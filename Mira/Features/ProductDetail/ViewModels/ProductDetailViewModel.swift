import Foundation
import Combine

@MainActor
final class ProductDetailViewModel: ObservableObject {
    @Published var product: ProductModel?
    @Published var healthScore: HealthScore?
    @Published var dietaryViolations: [DietaryRestriction] = []
    @Published var dietaryRestrictionResults: [DietaryRestrictionResult] = []
    @Published var alternatives: [AlternativeProduct] = []
    @Published var alternativesMessage: String?
    @Published var ingredientItems: [IngredientItem] = []
    @Published var rawIngredientsText: String?
    @Published var isLoading = false
    @Published var isLoadingAlternatives = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var isSearchingAmazon = false
    @Published var amazonErrorMessage: String?
    @Published var amazonSearchQuery: String?
    @Published var isInstacartAuthenticated = false
    @Published var isAddingToInstacart = false
    @Published var instacartCartCount = 0
    @Published var instacartErrorMessage: String?
    @Published var instacartDidAddToCart = false

    private let productService: ProductServiceProtocol
    private let scoringEngine: ScoringEngine
    private let amazonService: AmazonServicing
    private let instacartService: InstacartService
    private var cancellables = Set<AnyCancellable>()

    private var currentHealthFocus: HealthFocus = .generalWellness
    private var currentDietaryRestrictions: [DietaryRestriction] = []
    private var currentDietaryRestrictionIds: Set<String> = []

    init(
        productService: ProductServiceProtocol = ProductService.shared,
        scoringEngine: ScoringEngine = .shared,
        amazonService: AmazonServicing = AmazonService.shared,
        instacartService: InstacartService = .shared
    ) {
        self.productService = productService
        self.scoringEngine = scoringEngine
        self.amazonService = amazonService
        self.instacartService = instacartService
    }

    func loadProduct(barcode: String) {
        isLoading = true
        errorMessage = nil
        alternativesMessage = nil
        ingredientItems = []
        rawIngredientsText = nil

        productService.getProduct(by: barcode)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.ingredientItems = []
                        let networkError = NetworkError.from(error)
                        self?.showError(networkError.errorDescription ?? error.localizedDescription)
                    }
                },
                receiveValue: { [weak self] product in
                    guard let self else { return }

                    var normalizedProduct = product

                    if normalizedProduct.ingredients.isEmpty,
                       let raw = normalizedProduct.rawIngredientsText,
                       !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        let parsed = IngredientAnalyzer.shared.parseIngredientList(raw)
                        if !parsed.isEmpty {
                            AppLog.debug("Parsed ingredients from raw text fallback: \(parsed.count)", category: .general)
                            normalizedProduct.ingredients = parsed
                        }
                    }

                    self.product = normalizedProduct
                    let analyses = IngredientAnalyzer.shared.analyze(ingredients: normalizedProduct.ingredients)
                    AppLog.debug("ProductDetail ingredients count: \(normalizedProduct.ingredients.count)", category: .general)
                    if !normalizedProduct.ingredients.isEmpty {
                        AppLog.debug("ProductDetail ingredient sample: \(normalizedProduct.ingredients.prefix(5))", category: .general)
                    }
                    AppLog.debug("Ingredient analyses count: \(analyses.count)", category: .general)
                    self.ingredientItems = analyses.map(IngredientItem.init(analysis:))
                    let rawText = normalizedProduct.rawIngredientsText ?? normalizedProduct.ingredients.joined(separator: ", ")
                    self.rawIngredientsText = rawText.isEmpty ? nil : rawText
                    self.calculateHealthScore()
                    self.checkDietaryViolations()
                    self.updateDietaryRestrictionResults()
                    self.loadAlternatives()
                }
            )
            .store(in: &cancellables)
    }

    func updateHealthFocus(_ focus: HealthFocus) {
        currentHealthFocus = focus
        calculateHealthScore()
        loadAlternatives()
    }

    func updateDietaryRestrictions(_ restrictionIds: Set<String>) {
        currentDietaryRestrictionIds = restrictionIds
        currentDietaryRestrictions = mapDietaryRestrictions(from: restrictionIds)
        checkDietaryViolations()
        updateDietaryRestrictionResults()
        calculateHealthScore()
        loadAlternatives()
    }

    private func calculateHealthScore() {
        guard let product = product else { return }

        AppLog.debug("=== PRODUCT DETAIL VIEW MODEL ===", category: .scoring)
        AppLog.debug("Product: \(product.name)", category: .scoring)
        AppLog.debug("Barcode: \(product.barcode)", category: .scoring)
        AppLog.debug("Protein: \(product.nutrition.protein)g, Fiber: \(product.nutrition.fiber)g, Sugar: \(product.nutrition.sugar)g", category: .scoring)
        AppLog.debug("Health Focus: \(currentHealthFocus.rawValue)", category: .scoring)

        let score = scoringEngine.calculateHealthScore(
            for: product,
            healthFocus: currentHealthFocus,
            dietaryRestrictions: currentDietaryRestrictions
        )
        healthScore = score

        AppLog.debug("Calculated Score: \(Int(score.overall.rounded()))", category: .scoring)
        AppLog.debug("Score Breakdown:", category: .scoring)
        AppLog.debug("   macronutrients: \(Int(score.components.macronutrientBalance.score))", category: .scoring)
        AppLog.debug("   micronutrients: \(Int(score.components.micronutrientDensity.score))", category: .scoring)
        AppLog.debug("   processing: \(Int(score.components.processingLevel.score))", category: .scoring)
        AppLog.debug("   ingredients: \(Int(score.components.ingredientQuality.score))", category: .scoring)
        AppLog.debug("   additives: \(Int(score.components.additives.score))", category: .scoring)
        AppLog.debug("---", category: .scoring)
    }

    private func checkDietaryViolations() {
        guard let product = product else {
            dietaryViolations = []
            return
        }

        guard !currentDietaryRestrictions.isEmpty else {
            dietaryViolations = []
            return
        }

        dietaryViolations = scoringEngine.checkDietaryViolations(
            ingredients: product.ingredients,
            restrictions: currentDietaryRestrictions
        )
    }

    private func loadAlternatives() {
        guard let product = product else { return }

        isLoadingAlternatives = true

        alternativesMessage = nil
        alternatives = []

        productService.getAlternatives(
            for: product,
            healthFocus: currentHealthFocus,
            dietaryRestrictions: currentDietaryRestrictions,
            maxResults: 3
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoadingAlternatives = false
                if case .failure(let error) = completion {
                    let networkError = NetworkError.from(error)
                    let message = networkError.errorDescription ?? error.localizedDescription
                    AppLog.warning("Failed to load alternatives: \(message)", category: .network)
                    self?.alternativesMessage = message
                }
            },
            receiveValue: { [weak self] alternatives in
                AppLog.debug("Alternatives received: \(alternatives.count)", category: .network)
                for alt in alternatives {
                    AppLog.debug("   → \(alt.product.name): \(Int(alt.healthScore.overall.rounded())) (+\(Int(alt.improvement)))", category: .network)
                }
                if alternatives.isEmpty {
                    self?.alternativesMessage = "No better alternatives found yet."
                } else {
                    self?.alternativesMessage = nil
                }
                self?.alternatives = alternatives
            }
        )
        .store(in: &cancellables)
    }

    func dismissError() {
        showError = false
        errorMessage = nil
    }

    func fetchAmazonLink(for product: ProductModel) async -> URL? {
        isSearchingAmazon = true
        amazonErrorMessage = nil
        amazonSearchQuery = nil

        defer { isSearchingAmazon = false }

        let brand = product.brand ?? ""
        if let url = amazonService.generateProductLink(
            name: product.name,
            brand: brand,
            barcode: product.barcode
        ) {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItem = components.queryItems?.first(where: { $0.name == Constants.Amazon.searchQueryKey }),
               let value = queryItem.value {
                amazonSearchQuery = value.replacingOccurrences(of: "+", with: " ")
            }
            return url
        } else {
            amazonErrorMessage = "Unable to build Amazon link for this product."
            return nil
        }
    }

    func loadInstacartState() {
        Task { [weak self] in
            guard let self else { return }
            let authenticated = await instacartService.isAuthenticated()
            await MainActor.run {
                self.isInstacartAuthenticated = authenticated
            }

            guard authenticated else { return }

            do {
                let count = try await instacartService.getCartItemCount()
                await MainActor.run {
                    self.instacartCartCount = count
                }
            } catch {
                AppLog.warning("Instacart cart count fetch failed: \(error.localizedDescription)", category: .network)
            }
        }
    }

    func handleInstacartConnected() {
        isInstacartAuthenticated = true
        instacartErrorMessage = nil
        loadInstacartState()
    }

    func addCurrentProductToInstacart() {
        guard let product = product else { return }
        guard isInstacartAuthenticated else {
            instacartErrorMessage = InstacartServiceError.notAuthenticated.errorDescription
            return
        }

        isAddingToInstacart = true
        instacartErrorMessage = nil
        instacartDidAddToCart = false

        Task { [weak self] in
            guard let self else { return }

            do {
                let instacartProduct = try await instacartService.searchProduct(
                    upc: product.barcode,
                    name: product.name,
                    brand: product.brand ?? ""
                )

                guard let candidate = instacartProduct else {
                    await MainActor.run {
                        self.instacartErrorMessage = InstacartServiceError.productNotFound.errorDescription
                        self.instacartDidAddToCart = false
                        self.isAddingToInstacart = false
                    }
                    return
                }

                _ = try await instacartService.addToCart(product: candidate)
                let newCount = try await instacartService.getCartItemCount()

                await MainActor.run {
                    self.instacartCartCount = newCount
                    self.instacartDidAddToCart = true
                    self.isAddingToInstacart = false
                }
            } catch {
                await MainActor.run {
                    self.instacartErrorMessage = error.localizedDescription
                    self.instacartDidAddToCart = false
                    self.isAddingToInstacart = false
                }
            }
        }
    }

    func resetInstacartFeedback() {
        instacartDidAddToCart = false
    }

    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }

    private func updateDietaryRestrictionResults() {
        guard !currentDietaryRestrictionIds.isEmpty else {
            dietaryRestrictionResults = []
            return
        }

        guard let product = product else {
            dietaryRestrictionResults = []
            return
        }

        let results = DietaryRestrictionChecker.checkRestrictions(
            for: product,
            restrictions: currentDietaryRestrictionIds
        )

        dietaryRestrictionResults = results

        AppLog.debug("Dietary restriction check for: \(product.name)", category: .general)
        if results.isEmpty {
            AppLog.debug("No applicable restrictions to evaluate.", category: .general)
        } else {
            for result in results {
                if let passes = result.passes {
                    let status = passes ? "✓ PASS" : "✗ FAIL"
                    AppLog.debug("\(result.restriction): \(status) - \(result.reason)", category: .general)
                } else {
                    AppLog.warning("\(result.restriction): ⚠️ UNKNOWN - \(result.reason)", category: .general)
                }
            }
        }
    }

    private func mapDietaryRestrictions(from identifiers: Set<String>) -> [DietaryRestriction] {
        guard !identifiers.isEmpty else { return [] }

        let normalizedIdentifiers = Set(identifiers.map(normalizeRestrictionIdentifier(_:)))

        return DietaryRestriction.allCases.filter { restriction in
            normalizedIdentifiers.contains(normalizeRestrictionIdentifier(restriction.rawValue))
        }
    }

    private func normalizeRestrictionIdentifier(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
    }
}

protocol ProductServiceProtocol {
    func getProduct(by barcode: String) -> AnyPublisher<ProductModel, Error>
    func getAlternatives(
        for product: ProductModel,
        healthFocus: HealthFocus,
        dietaryRestrictions: [DietaryRestriction],
        maxResults: Int
    ) -> AnyPublisher<[AlternativeProduct], Error>
}

final class ProductService: ProductServiceProtocol {
    static let shared = ProductService()

    private let usdaService: USDAService
    private let openFoodFactsService: OpenFoodFactsService

    private init(
        usdaService: USDAService = .shared,
        openFoodFactsService: OpenFoodFactsService = .shared
    ) {
        self.usdaService = usdaService
        self.openFoodFactsService = openFoodFactsService
    }

    func getProduct(by barcode: String) -> AnyPublisher<ProductModel, Error> {
        return Future { [weak self] promise in
            Task {
                guard let self else {
                    promise(.failure(NetworkError.productNotFound))
                    return
                }

                do {
                    let product = try await self.loadProductWithFallbacks(barcode: barcode)
                    promise(.success(product))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func getAlternatives(
        for product: ProductModel,
        healthFocus: HealthFocus,
        dietaryRestrictions: [DietaryRestriction],
        maxResults: Int
    ) -> AnyPublisher<[AlternativeProduct], Error> {
        return AlternativesEngine.shared.findAlternatives(
            for: product,
            healthFocus: healthFocus,
            dietaryRestrictions: dietaryRestrictions,
            limit: maxResults
        )
        .eraseToAnyPublisher()
    }

    private func loadProductWithFallbacks(barcode: String) async throws -> ProductModel {
        do {
            var usdaProduct = try await usdaService.searchProductByBarcode(barcode)
            AppLog.debug("USDA initial ingredients count for \(barcode): \(usdaProduct.ingredients.count) | raw length: \(usdaProduct.rawIngredientsText?.count ?? 0)", category: .network)
            usdaProduct = await enrichUSDAProduct(usdaProduct)
            AppLog.debug("USDA enriched ingredients count for \(barcode): \(usdaProduct.ingredients.count) | raw length: \(usdaProduct.rawIngredientsText?.count ?? 0)", category: .network)

            var candidate = usdaProduct

            if !hasIngredients(in: candidate) {
                do {
                    let fallback = try await openFoodFactsService.searchProductByBarcode(barcode)
                    AppLog.debug("OFF fallback ingredients count: \(fallback.ingredients.count) | raw length: \(fallback.rawIngredientsText?.count ?? 0)", category: .network)
                    if hasIngredients(in: fallback) {
                        candidate = merge(primary: candidate, with: fallback)
                        AppLog.debug("Ingredients supplemented from OpenFoodFacts for barcode \(barcode)", category: .network)
                    } else {
                        AppLog.debug("OpenFoodFacts fallback lacked ingredients for barcode \(barcode)", category: .network)
                    }
                } catch {
                    AppLog.warning("OpenFoodFacts lookup failed for barcode \(barcode): \(error.localizedDescription)", category: .network)
                }
            }

            if !hasIngredients(in: candidate) {
                AppLog.warning("Unable to locate ingredients for barcode \(barcode) after all fallbacks", category: .network)
            }

            return convertAPIProduct(candidate)
        } catch {
            AppLog.warning("USDA lookup failed for barcode \(barcode): \(error.localizedDescription)", category: .network)
        }

        let fallbackProduct = try await openFoodFactsService.searchProductByBarcode(barcode)
        return convertAPIProduct(fallbackProduct)
    }

    private func enrichUSDAProduct(_ product: APIProduct) async -> APIProduct {
        guard !hasIngredients(in: product) else { return product }

        do {
            let details = try await usdaService.fetchProductDetails(fdcId: product.id)
            let detailedProduct = details.product
            AppLog.debug("USDA details ingredients count: \(detailedProduct.ingredients.count) | raw length: \(detailedProduct.rawIngredientsText?.count ?? 0)", category: .network)
            if hasIngredients(in: detailedProduct) {
                AppLog.debug("USDA details provided ingredient list for FDC ID \(product.id)", category: .network)
                return detailedProduct
            } else {
                AppLog.debug("USDA details still missing ingredients for FDC ID \(product.id)", category: .network)
            }
        } catch {
            AppLog.warning("USDA detail lookup failed for FDC ID \(product.id): \(error.localizedDescription)", category: .network)
        }

        return product
    }

    private func hasIngredients(in product: APIProduct) -> Bool {
        if !product.ingredients.isEmpty { return true }
        if let raw = product.rawIngredientsText?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty {
            return true
        }
        return false
    }

    private func merge(primary: APIProduct, with fallback: APIProduct) -> APIProduct {
        let mergedNutrition = mergeNutrition(primary: primary.nutritionalData, fallback: fallback.nutritionalData)

        let mergedBrand = preferredValue(primary: primary.brand, fallback: fallback.brand, unknownToken: "Unknown")
        let mergedName = preferredValue(primary: primary.name, fallback: fallback.name, unknownToken: "Unknown Product")
        let mergedCategory = preferredValue(primary: primary.category, fallback: fallback.category, unknownToken: "Food")

        let barcode = primary.barcode.isEmpty ? fallback.barcode : primary.barcode
        let servingSize = primary.servingSize ?? fallback.servingSize
        let servingUnit = primary.servingSizeUnit.isEmpty ? fallback.servingSizeUnit : primary.servingSizeUnit
        let servingSizeDisplay = primary.servingSizeDisplay ?? fallback.servingSizeDisplay
        let imageURL = primary.imageURL ?? fallback.imageURL
        let thumbnailURL = primary.thumbnailURL ?? fallback.thumbnailURL
        let rawIngredients = fallback.rawIngredientsText ?? primary.rawIngredientsText
        let resolvedIngredients: [String]
        if !fallback.ingredients.isEmpty {
            resolvedIngredients = fallback.ingredients
        } else if let rawIngredients, !rawIngredients.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let parsed = IngredientAnalyzer.shared.parseIngredientList(rawIngredients)
            resolvedIngredients = parsed.isEmpty ? primary.ingredients : parsed
        } else if !primary.ingredients.isEmpty {
            resolvedIngredients = primary.ingredients
        } else {
            resolvedIngredients = []
        }

        AppLog.debug("Merging ingredients: primary count \(primary.ingredients.count), fallback count \(fallback.ingredients.count), resolved count \(resolvedIngredients.count)", category: .network)

        let mergedCategorySlug = primary.categorySlug ?? fallback.categorySlug

        return APIProduct(
            id: primary.id,
            barcode: barcode,
            name: mergedName,
            brand: mergedBrand,
            category: mergedCategory,
            categorySlug: mergedCategorySlug,
            ingredients: resolvedIngredients,
            rawIngredientsText: rawIngredients,
            nutritionalData: mergedNutrition,
            servingSize: servingSize,
            servingSizeUnit: servingUnit,
            servingSizeDisplay: servingSizeDisplay,
            imageURL: imageURL,
            thumbnailURL: thumbnailURL,
            source: primary.source
        )
    }

    private func mergeNutrition(primary: NutritionalData, fallback: NutritionalData) -> NutritionalData {
        var merged = primary

        if merged.calories == 0 { merged.calories = fallback.calories }
        if merged.protein == 0 { merged.protein = fallback.protein }
        if merged.carbohydrates == 0 { merged.carbohydrates = fallback.carbohydrates }
        if merged.fat == 0 { merged.fat = fallback.fat }
        if merged.fiber == 0 { merged.fiber = fallback.fiber }
        if merged.sugar == 0 { merged.sugar = fallback.sugar }
        if merged.sodium == 0 { merged.sodium = fallback.sodium }
        if merged.cholesterol == 0 { merged.cholesterol = fallback.cholesterol }

        return merged
    }

    private func preferredValue(primary: String, fallback: String, unknownToken: String) -> String {
        let trimmedPrimary = primary.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedPrimary.isEmpty || trimmedPrimary.caseInsensitiveCompare(unknownToken) == .orderedSame {
            let trimmedFallback = fallback.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedFallback.isEmpty ? trimmedPrimary : trimmedFallback
        }
        return primary
    }

    private func convertAPIProduct(_ api: APIProduct) -> ProductModel {
        // Map API nutritional data to app nutrition model
        // Use servingSizeDisplay if available (e.g., "2 tbsp (30 g)"), else fall back to "100g"
        let servingDisplay = api.servingSizeDisplay ?? "100g"
        let servingMultiplier = (api.servingSizeInGrams ?? 100) / 100
        let adjustedNutritionData = api.nutritionalData.scaled(by: servingMultiplier)
        let nutrition = ProductNutrition(
            calories: adjustedNutritionData.calories,
            protein: adjustedNutritionData.protein,
            carbohydrates: adjustedNutritionData.carbohydrates,
            fat: adjustedNutritionData.fat,
            fiber: adjustedNutritionData.fiber,
            sugar: adjustedNutritionData.sugar,
            sodium: adjustedNutritionData.sodium,
            cholesterol: adjustedNutritionData.cholesterol,
            servingSize: servingDisplay
        )

        let normalizedIngredients: [String]
        if !api.ingredients.isEmpty {
            normalizedIngredients = api.ingredients
        } else if let raw = api.rawIngredientsText, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            normalizedIngredients = IngredientAnalyzer.shared.parseIngredientList(raw)
        } else {
            normalizedIngredients = []
        }

        AppLog.debug("APIProduct convert → ingredients count: \(normalizedIngredients.count) | raw length: \(api.rawIngredientsText?.count ?? 0)", category: .network)

        return ProductModel(
            id: UUID(),
            name: api.name,
            brand: api.brand,
            category: api.category,
            categorySlug: api.categorySlug,
            barcode: api.barcode,
            nutrition: nutrition,
            ingredients: normalizedIngredients,
            additives: [],
            processingLevel: .processed,
            dietaryFlags: [],
            imageURL: api.imageURL,
            thumbnailURL: api.thumbnailURL,
            healthScore: 0,
            createdAt: Date(),
            updatedAt: Date(),
            isCached: false,
            rawIngredientsText: api.rawIngredientsText
        )
    }
}
