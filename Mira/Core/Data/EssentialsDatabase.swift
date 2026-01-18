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
    let sodium: Double // in grams (will be converted to mg for display)
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

            for product in decoded.products {
                dict[product.barcode] = product
            }

            catalog = dict
            isLoaded = true
            AppLog.info("Loaded \(catalog.count) essential products for offline access (v\(decoded.version))", category: .network)
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
        return catalog[barcode]
    }

    /// Convert an EssentialProduct to ProductModel for use in the app
    func makeProductModel(from essential: EssentialProduct) -> ProductModel {
        let nutrition = ProductNutrition(
            calories: essential.nutrition.calories,
            protein: essential.nutrition.protein,
            carbohydrates: essential.nutrition.carbohydrates,
            fat: essential.nutrition.fat,
            saturatedFat: essential.nutrition.saturatedFat,
            fiber: essential.nutrition.fiber,
            sugar: essential.nutrition.sugar,
            sodium: essential.nutrition.sodium,
            cholesterol: 0,
            servingSize: essential.servingSize ?? "100g"
        )

        // Determine processing level based on ingredients
        let processingLevel = ProcessingLevel.determine(for: essential.ingredients ?? [])

        return ProductModel(
            id: UUID(),
            name: essential.name,
            brand: essential.brand,
            category: essential.category,
            categorySlug: essential.category.lowercased().replacingOccurrences(of: " ", with: "-"),
            barcode: essential.barcode,
            nutrition: nutrition,
            ingredients: essential.ingredients ?? [],
            additives: [],
            processingLevel: processingLevel,
            dietaryFlags: [],  // Will be detected by scoring engine if needed
            imageURL: nil,      // Essentials don't include images
            thumbnailURL: nil,  // Show generic category icon instead
            healthScore: 0,     // Will be calculated by scoring engine
            createdAt: Date(),
            updatedAt: Date(),
            isCached: true,
            rawIngredientsText: essential.ingredients?.joined(separator: ", "),
            nutriScore: nil
        )
    }

    /// Convert an EssentialProduct to APIProduct for compatibility with existing flows
    func makeAPIProduct(from essential: EssentialProduct) -> APIProduct {
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
            servingSize: 100,
            servingSizeUnit: "g",
            servingSizeDisplay: essential.servingSize,
            imageURL: nil,
            thumbnailURL: nil,
            source: .manual  // Mark as from local source
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
}
