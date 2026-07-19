import Foundation

// MARK: - Essentials Catalog Models

/// A lightweight product entry for the bundled essentials catalog
struct EssentialProduct: Codable {
    let barcode: String
    let name: String
    let brand: String?
    let category: String
    let nutrition: EssentialNutrition
    let servingSize: String?
    let ingredients: [String]?
}

/// Minimal nutrition data for essential products (per 100g)
struct EssentialNutrition: Codable {
    let calories: Double
    let protein: Double
    let carbohydrates: Double
    let fat: Double
    let saturatedFat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double // grams per 100g, matching NutritionalData

    var isPlausible: Bool {
        guard (0...900).contains(calories) else { return false }
        let gramValues = [protein, carbohydrates, fat, saturatedFat, fiber, sugar, sodium]
        guard gramValues.allSatisfy({ (0...100).contains($0) }) else { return false }
        guard saturatedFat <= fat + 0.01 else { return false }
        // Zero is also how the legacy catalog represents an unavailable value.
        // Only compare sugars with carbohydrates when both were actually supplied.
        return carbohydrates == 0 || sugar <= carbohydrates + 0.5
    }

    func scalingSodium(by multiplier: Double) -> EssentialNutrition {
        EssentialNutrition(
            calories: calories,
            protein: protein,
            carbohydrates: carbohydrates,
            fat: fat,
            saturatedFat: saturatedFat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium * multiplier
        )
    }
}

private extension EssentialProduct {
    func scalingSodium(by multiplier: Double) -> EssentialProduct {
        EssentialProduct(
            barcode: barcode,
            name: name,
            brand: brand,
            category: category,
            nutrition: nutrition.scalingSodium(by: multiplier),
            servingSize: servingSize,
            ingredients: ingredients
        )
    }

    var servingSizeInGrams: Double? {
        guard let servingSize = servingSize?.lowercased() else { return nil }

        let metricPattern = #"(\d+(?:[\.,]\d+)?)\s*(g|ml)\b"#
        if let regex = try? NSRegularExpression(pattern: metricPattern),
           let match = regex.firstMatch(
               in: servingSize,
               range: NSRange(servingSize.startIndex..., in: servingSize)
           ),
           let valueRange = Range(match.range(at: 1), in: servingSize) {
            return Double(servingSize[valueRange].replacingOccurrences(of: ",", with: "."))
        }

        let ouncePattern = #"(\d+(?:[\.,]\d+)?)\s*oz\b"#
        if let regex = try? NSRegularExpression(pattern: ouncePattern),
           let match = regex.firstMatch(
               in: servingSize,
               range: NSRange(servingSize.startIndex..., in: servingSize)
           ),
           let valueRange = Range(match.range(at: 1), in: servingSize),
           let ounces = Double(servingSize[valueRange].replacingOccurrences(of: ",", with: ".")) {
            return ounces * 28.3495
        }

        return nil
    }
}

/// The root structure of the essentials catalog JSON
struct EssentialsCatalog: Codable {
    let version: String
    let generatedAt: String
    let productCount: Int
    let products: [EssentialProduct]
}

// MARK: - Essentials Database Service

/// Pre-bundled database of top US products for instant offline access.
/// Products are loaded from essentials_catalog.json bundled in the app.
actor EssentialsDatabase {
    static let shared = EssentialsDatabase()

    private var catalog: [String: EssentialProduct] = [:]
    private var isLoaded = false
    private var loadError: Error?

    init() {
        Task {
            await loadCatalog()
        }
    }

    /// Load the essentials catalog from the app bundle
    func loadCatalog() {
        guard !isLoaded else { return }

        guard let url = Bundle.main.url(forResource: "essentials_catalog", withExtension: "json") else {
            AppLog.warning("essentials_catalog.json not found in bundle - offline essentials disabled", category: .network)
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decoded = try decoder.decode(EssentialsCatalog.self, from: data)

            // Build barcode lookup dictionary for O(1) access
            var dict: [String: EssentialProduct] = [:]
            dict.reserveCapacity(decoded.products.count)

            let legacySodiumMultiplier = decoded.version == "1.0.0" ? 1000.0 : 1.0
            var rejectedCount = 0
            for rawProduct in decoded.products {
                let product = rawProduct.scalingSodium(by: legacySodiumMultiplier)
                guard product.nutrition.isPlausible,
                      !product.barcode.isEmpty,
                      !product.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    rejectedCount += 1
                    continue
                }
                dict[BarcodeNormalizer.lookupKey(for: product.barcode)] = product
            }

            catalog = dict
            isLoaded = true
            AppLog.info("Loaded \(catalog.count) essential products for offline access (v\(decoded.version))", category: .network)
            if rejectedCount > 0 {
                AppLog.warning("Ignored \(rejectedCount) implausible offline catalog records", category: .network)
            }
        } catch {
            loadError = error
            AppLog.error("Failed to load essentials catalog: \(error.localizedDescription)", category: .network)
        }
    }

    /// Check if the database is ready for lookups
    var isReady: Bool {
        isLoaded && !catalog.isEmpty
    }

    /// Get the number of products in the database
    var productCount: Int {
        catalog.count
    }

    /// Look up a product by barcode
    /// - Returns: The essential product if found, nil otherwise
    func lookup(barcode: String) -> EssentialProduct? {
        catalog[BarcodeNormalizer.lookupKey(for: barcode)]
    }

    /// Convert an EssentialProduct to ProductModel for use in the app
    func makeProductModel(from essential: EssentialProduct) -> ProductModel {
        var model = ProductModelConverter.convert(makeAPIProduct(from: essential))
        model.isCached = true
        model.fruitVegEstimate = FruitVegLegumeNutEstimator.shared.estimate(
            ingredients: model.ingredients,
            rawText: model.rawIngredientsText,
            categorySlug: model.categorySlug
        )
        return model
    }

    /// Convert an EssentialProduct to APIProduct for compatibility with existing flows
    func makeAPIProduct(from essential: EssentialProduct) -> APIProduct {
        let servingGrams = essential.servingSizeInGrams
        let nutritionalData = NutritionalData(
            calories: essential.nutrition.calories,
            protein: essential.nutrition.protein,
            carbohydrates: essential.nutrition.carbohydrates,
            fat: essential.nutrition.fat,
            saturatedFat: essential.nutrition.saturatedFat,
            fiber: essential.nutrition.fiber,
            sugar: essential.nutrition.sugar,
            sodium: essential.nutrition.sodium,
            cholesterol: 0  // Not available in essentials data
        )

        return APIProduct(
            id: essential.barcode,
            barcode: essential.barcode,
            name: essential.name,
            brand: essential.brand ?? "",  // Handle optional brand
            category: essential.category,
            categorySlug: essential.category.lowercased().replacingOccurrences(of: " ", with: "-"),
            ingredients: essential.ingredients ?? [],
            rawIngredientsText: essential.ingredients?.joined(separator: ", "),
            nutritionalData: nutritionalData,
            nutritionBasis: .per100Grams,
            servingSize: servingGrams ?? 100,
            servingSizeUnit: "g",
            servingSizeDisplay: servingGrams == nil ? "100g" : essential.servingSize,
            imageURL: nil,
            thumbnailURL: nil,
            source: .manual,
            processingLevel: ProcessingLevel.determine(for: essential.ingredients ?? [])
        )
    }
}

// MARK: - Integration with ScannerViewModel

extension EssentialsDatabase {
    /// Try to get a product from essentials first (instant), falling back to nil
    /// This should be called BEFORE network requests for maximum speed
    func getProductIfAvailable(barcode: String) async -> APIProduct? {
        // Try loading if not ready
        if !isReady {
            loadCatalog()
        }

        // Still not ready after loading attempt - catalog might not exist
        guard isReady else {
            return nil
        }

        guard let essential = lookup(barcode: barcode) else {
            return nil
        }

        AppLog.debug("Found '\(essential.name)' in essentials database (instant)", category: .network)
        return makeAPIProduct(from: essential)
    }

    /// Search the bundled catalog for useful offline results using the same filter units as
    /// network search. Definite dietary violations are excluded; uncertain items remain visible.
    func search(filters: SearchFilters, limit: Int = 20) -> [APIProduct] {
        if !isReady {
            loadCatalog()
        }
        guard isReady, limit > 0 else { return [] }

        let searchTerms = filters.searchTerms.map { $0.lowercased() }.filter { !$0.isEmpty }
        let categories = filters.categories.map { $0.lowercased() }
        guard !searchTerms.isEmpty || !categories.isEmpty || filters.hasNutritionalFilters else {
            return []
        }

        let restrictions = filters.dietaryRestrictions.compactMap(DietaryRestriction.init(from:))
        let rankedProducts: [(rank: Int, product: EssentialProduct)] = catalog.values.compactMap { product in
            let ingredientText = product.ingredients?.joined(separator: " ") ?? ""
            let searchableText = [product.name, product.brand ?? "", product.category, ingredientText]
                .joined(separator: " ")
                .lowercased()

            guard searchTerms.allSatisfy(searchableText.contains),
                  filters.excludeTerms.map({ $0.lowercased() }).allSatisfy({ !searchableText.contains($0) }),
                  categories.allSatisfy(searchableText.contains),
                  filters.excludeCategories.map({ $0.lowercased() }).allSatisfy({ !searchableText.contains($0) }),
                  matchesNutrition(product.nutrition, filters: filters),
                  !hasDefiniteDietaryViolation(product, restrictions: restrictions) else {
                return nil
            }

            let normalizedName = product.name.lowercased()
            let rank = searchTerms.reduce(0) { score, term in
                score + (normalizedName.hasPrefix(term) ? 3 : normalizedName.contains(term) ? 2 : 1)
            }
            return (rank, product)
        }

        return rankedProducts
            .sorted {
                if $0.rank != $1.rank { return $0.rank > $1.rank }
                return $0.product.name.localizedCaseInsensitiveCompare($1.product.name) == .orderedAscending
            }
            .prefix(limit)
            .map { makeAPIProduct(from: $0.product) }
    }

    private func matchesNutrition(_ nutrition: EssentialNutrition, filters: SearchFilters) -> Bool {
        if let min = filters.caloriesMin, nutrition.calories < min { return false }
        if let max = filters.caloriesMax, nutrition.calories > max { return false }
        if let min = filters.proteinMin, nutrition.protein < min { return false }
        if let max = filters.proteinMax, nutrition.protein > max { return false }
        if let min = filters.carbsMin, nutrition.carbohydrates < min { return false }
        if let max = filters.carbsMax, nutrition.carbohydrates > max { return false }
        if let min = filters.fatMin, nutrition.fat < min { return false }
        if let max = filters.fatMax, nutrition.fat > max { return false }
        if let min = filters.fiberMin, nutrition.fiber < min { return false }
        if let max = filters.fiberMax, nutrition.fiber > max { return false }
        if let max = filters.sugarMax, nutrition.sugar > max { return false }
        if let max = filters.sodiumMax, nutrition.sodium * 1000 > max { return false }
        return true
    }

    private func hasDefiniteDietaryViolation(
        _ product: EssentialProduct,
        restrictions: [DietaryRestriction]
    ) -> Bool {
        restrictions.contains { restriction in
            if case .definiteViolation = DietaryQuickChecker.quickCheck(
                restriction: restriction,
                ingredients: product.ingredients ?? [],
                rawIngredientsText: product.ingredients?.joined(separator: ", ")
            ) {
                return true
            }
            return false
        }
    }
}
