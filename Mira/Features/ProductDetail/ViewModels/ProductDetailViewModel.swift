import Foundation
import Combine

// MARK: - State Groups

/// Core product data and scoring
struct ProductDataState {
    var product: ProductModel?
    var healthScore: HealthScore?
    var ingredientItems: [IngredientItem] = []
    var rawIngredientsText: String?
}

/// Dietary restriction evaluation results
struct DietaryState {
    var violations: [DietaryRestriction] = []
    var results: [DietaryRestrictionResult] = []
    var aiEnhancedResults: [DietaryAnalysisResult] = []
    var isAnalyzingWithAI = false
    var isAIEnhanced = false
}

/// Alternative products state
struct AlternativesState {
    var items: [AlternativeProduct] = []
    var message: String?
    var isLoading = false
}

/// Loading and error state
struct LoadingState {
    var isLoading = false
    var errorMessage: String?
    var showError = false

    mutating func setError(_ message: String) {
        errorMessage = message
        showError = true
    }

    mutating func clearError() {
        errorMessage = nil
        showError = false
    }
}

/// Amazon integration state
struct AmazonState {
    var isSearching = false
    var errorMessage: String?
    var searchQuery: String?
}

/// Instacart integration state
struct InstacartState {
    var isAuthenticated = false
    var isAddingToCart = false
    var cartCount = 0
    var errorMessage: String?
    var didAddToCart = false
}

// MARK: - ViewModel

@MainActor
final class ProductDetailViewModel: ObservableObject {
    // MARK: - Published State Groups
    @Published var productData = ProductDataState()
    @Published var dietary = DietaryState()
    @Published var alternatives = AlternativesState()
    @Published var loading = LoadingState()
    @Published var amazon = AmazonState()
    @Published var instacart = InstacartState()

    // MARK: - Convenience Accessors (for backward compatibility)
    var product: ProductModel? { productData.product }
    var healthScore: HealthScore? { productData.healthScore }
    var ingredientItems: [IngredientItem] { productData.ingredientItems }
    var rawIngredientsText: String? { productData.rawIngredientsText }
    var dietaryViolations: [DietaryRestriction] { dietary.violations }
    var dietaryRestrictionResults: [DietaryRestrictionResult] { dietary.results }
    var dietaryAIResults: [DietaryAnalysisResult] { dietary.aiEnhancedResults }
    var isDietaryAILoading: Bool { dietary.isAnalyzingWithAI }
    var isDietaryAIEnhanced: Bool { dietary.isAIEnhanced }
    var alternativeProducts: [AlternativeProduct] { alternatives.items }
    var alternativesMessage: String? { alternatives.message }
    var isLoading: Bool { loading.isLoading }
    var isLoadingAlternatives: Bool { alternatives.isLoading }
    var errorMessage: String? { loading.errorMessage }
    var showError: Bool { loading.showError }
    var isSearchingAmazon: Bool { amazon.isSearching }
    var amazonErrorMessage: String? { amazon.errorMessage }
    var amazonSearchQuery: String? { amazon.searchQuery }
    var isInstacartAuthenticated: Bool { instacart.isAuthenticated }
    var isAddingToInstacart: Bool { instacart.isAddingToCart }
    var instacartCartCount: Int { instacart.cartCount }
    var instacartErrorMessage: String? { instacart.errorMessage }
    var instacartDidAddToCart: Bool { instacart.didAddToCart }

    // MARK: - Dependencies
    private let productService: ProductServiceProtocol
    private let scoringEngine: ScoringEngine
    private let amazonService: AmazonServicing
    private let instacartService: InstacartService
    private let dietaryAIService = DietaryAIService.shared
    private var cancellables = Set<AnyCancellable>()
    private var dietaryAnalysisTask: Task<Void, Never>?

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
        loading.isLoading = true
        loading.clearError()
        alternatives.message = nil
        productData.ingredientItems = []
        productData.rawIngredientsText = nil

        productService.getProduct(by: barcode)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.loading.isLoading = false
                    if case .failure(let error) = completion {
                        self?.productData.ingredientItems = []
                        let networkError = NetworkError.from(error)
                        self?.loading.setError(networkError.errorDescription ?? error.localizedDescription)
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

                    self.productData.product = normalizedProduct
                    let analyses = IngredientAnalyzer.shared.analyze(ingredients: normalizedProduct.ingredients)
                    AppLog.debug("ProductDetail ingredients count: \(normalizedProduct.ingredients.count)", category: .general)
                    if !normalizedProduct.ingredients.isEmpty {
                        AppLog.debug("ProductDetail ingredient sample: \(normalizedProduct.ingredients.prefix(5))", category: .general)
                    }
                    AppLog.debug("Ingredient analyses count: \(analyses.count)", category: .general)
                    self.productData.ingredientItems = analyses.map(IngredientItem.init(analysis:))
                    let rawText = normalizedProduct.rawIngredientsText ?? normalizedProduct.ingredients.joined(separator: ", ")
                    self.productData.rawIngredientsText = rawText.isEmpty ? nil : rawText
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
        guard let product = productData.product else { return }

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
        productData.healthScore = score

        // Haptic feedback for excellent scores
        if score.overall >= 80 {
            HapticManager.shared.success()
        }

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
        guard let product = productData.product else {
            dietary.violations = []
            return
        }

        guard !currentDietaryRestrictions.isEmpty else {
            dietary.violations = []
            return
        }

        dietary.violations = scoringEngine.checkDietaryViolations(
            ingredients: product.ingredients,
            restrictions: currentDietaryRestrictions
        )

        // Haptic feedback for dietary violations
        if !dietary.violations.isEmpty {
            HapticManager.shared.dietaryViolation()
        }
    }

    private func loadAlternatives() {
        guard let product = productData.product else { return }

        alternatives.isLoading = true
        alternatives.message = nil
        alternatives.items = []

        productService.getAlternatives(
            for: product,
            healthFocus: currentHealthFocus,
            dietaryRestrictions: currentDietaryRestrictions,
            maxResults: 3
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.alternatives.isLoading = false
                if case .failure(let error) = completion {
                    let networkError = NetworkError.from(error)
                    let message = networkError.errorDescription ?? error.localizedDescription
                    AppLog.warning("Failed to load alternatives: \(message)", category: .network)
                    self?.alternatives.message = message
                }
            },
            receiveValue: { [weak self] altProducts in
                AppLog.debug("Alternatives received: \(altProducts.count)", category: .network)
                for alt in altProducts {
                    AppLog.debug("   → \(alt.product.name): \(Int(alt.healthScore.overall.rounded())) (+\(Int(alt.improvement)))", category: .network)
                }
                if altProducts.isEmpty {
                    self?.alternatives.message = "No better alternatives found yet."
                } else {
                    self?.alternatives.message = nil
                }
                self?.alternatives.items = altProducts
            }
        )
        .store(in: &cancellables)
    }

    func dismissError() {
        loading.clearError()
    }

    func fetchAmazonLink(for product: ProductModel) async -> URL? {
        amazon.isSearching = true
        amazon.errorMessage = nil
        amazon.searchQuery = nil

        defer { amazon.isSearching = false }

        let brand = product.brand ?? ""
        if let url = amazonService.generateProductLink(
            name: product.name,
            brand: brand,
            barcode: product.barcode
        ) {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItem = components.queryItems?.first(where: { $0.name == Constants.Amazon.searchQueryKey }),
               let value = queryItem.value {
                amazon.searchQuery = value.replacingOccurrences(of: "+", with: " ")
            }
            return url
        } else {
            amazon.errorMessage = "Unable to build Amazon link for this product."
            return nil
        }
    }

    func loadInstacartState() {
        Task { [weak self] in
            guard let self else { return }
            let authenticated = await instacartService.isAuthenticated()
            await MainActor.run {
                self.instacart.isAuthenticated = authenticated
            }

            guard authenticated else { return }

            do {
                let count = try await instacartService.getCartItemCount()
                await MainActor.run {
                    self.instacart.cartCount = count
                }
            } catch {
                AppLog.warning("Instacart cart count fetch failed: \(error.localizedDescription)", category: .network)
            }
        }
    }

    func handleInstacartConnected() {
        instacart.isAuthenticated = true
        instacart.errorMessage = nil
        loadInstacartState()
    }

    func addCurrentProductToInstacart() {
        guard let product = productData.product else { return }
        guard instacart.isAuthenticated else {
            instacart.errorMessage = InstacartServiceError.notAuthenticated.errorDescription
            return
        }

        instacart.isAddingToCart = true
        instacart.errorMessage = nil
        instacart.didAddToCart = false

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
                        self.instacart.errorMessage = InstacartServiceError.productNotFound.errorDescription
                        self.instacart.didAddToCart = false
                        self.instacart.isAddingToCart = false
                    }
                    return
                }

                _ = try await instacartService.addToCart(product: candidate)
                let newCount = try await instacartService.getCartItemCount()

                await MainActor.run {
                    self.instacart.cartCount = newCount
                    self.instacart.didAddToCart = true
                    self.instacart.isAddingToCart = false
                }
            } catch {
                await MainActor.run {
                    self.instacart.errorMessage = error.localizedDescription
                    self.instacart.didAddToCart = false
                    self.instacart.isAddingToCart = false
                }
            }
        }
    }

    func resetInstacartFeedback() {
        instacart.didAddToCart = false
    }

    private func updateDietaryRestrictionResults() {
        guard !currentDietaryRestrictionIds.isEmpty else {
            dietary.results = []
            dietary.aiEnhancedResults = []
            dietary.isAIEnhanced = false
            return
        }

        guard let product = productData.product else {
            dietary.results = []
            dietary.aiEnhancedResults = []
            dietary.isAIEnhanced = false
            return
        }

        // First, do fast regex-based check
        let results = DietaryRestrictionChecker.checkRestrictions(
            for: product,
            restrictions: currentDietaryRestrictionIds
        )

        dietary.results = results

        AppLog.debug("Dietary restriction check for: \(product.name)", category: .general)
        if results.isEmpty {
            AppLog.debug("No applicable restrictions to evaluate.", category: .general)
        } else {
            for result in results {
                if let passes = result.passes {
                    let status = passes ? "PASS" : "FAIL"
                    AppLog.debug("\(result.restriction): \(status) - \(result.reason)", category: .general)
                } else {
                    AppLog.warning("\(result.restriction): UNKNOWN - \(result.reason)", category: .general)
                }
            }
        }

        // Then trigger AI-enhanced analysis in background
        performAIEnhancedDietaryAnalysis()
    }

    /// Performs AI-enhanced dietary restriction analysis.
    /// This provides more detailed violation detection including derivatives and cross-contamination.
    private func performAIEnhancedDietaryAnalysis() {
        // Cancel any existing analysis
        dietaryAnalysisTask?.cancel()

        guard !currentDietaryRestrictionIds.isEmpty else {
            dietary.aiEnhancedResults = []
            dietary.isAIEnhanced = false
            dietary.isAnalyzingWithAI = false
            return
        }

        guard let product = productData.product else {
            dietary.aiEnhancedResults = []
            dietary.isAIEnhanced = false
            dietary.isAnalyzingWithAI = false
            return
        }

        dietary.isAnalyzingWithAI = true

        dietaryAnalysisTask = Task { [weak self] in
            guard let self else { return }

            do {
                let results = try await dietaryAIService.analyzeProduct(
                    product,
                    restrictions: currentDietaryRestrictionIds
                )

                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.dietary.aiEnhancedResults = results
                    self.dietary.isAIEnhanced = results.contains { $0.analysisMethod == .aiEnhanced }
                    self.dietary.isAnalyzingWithAI = false

                    AppLog.debug("AI dietary analysis complete for: \(product.name)", category: .general)
                    for result in results {
                        let method = result.analysisMethod == .aiEnhanced ? "AI" : "regex"
                        AppLog.debug("[\(method)] \(result.restriction.displayName): \(result.status.rawValue)", category: .general)
                        for violation in result.violations {
                            AppLog.debug("  → Violation: \(violation.description)", category: .general)
                        }
                        for warning in result.warnings {
                            AppLog.debug("  → Warning: \(warning.description)", category: .general)
                        }
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.dietary.isAnalyzingWithAI = false
                    AppLog.warning("AI dietary analysis failed: \(error.localizedDescription)", category: .general)
                    // Fall back to quick checker results only
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
        // Run USDA and Open Food Facts lookups in parallel for faster loading
        async let usdaTask: APIProduct? = fetchUSDAProduct(barcode: barcode)
        async let offTask: APIProduct? = fetchOFFProduct(barcode: barcode)

        let (usdaResult, offResult) = await (usdaTask, offTask)

        // Determine the best product data to use
        var candidate: APIProduct?

        if let usda = usdaResult {
            AppLog.debug("USDA found product for \(barcode)", category: .network)
            candidate = usda

            // If USDA lacks ingredients, supplement from OFF
            if !hasIngredients(in: usda), let off = offResult, hasIngredients(in: off) {
                candidate = merge(primary: usda, with: off)
                AppLog.debug("Ingredients supplemented from OpenFoodFacts for barcode \(barcode)", category: .network)
            }
        } else if let off = offResult {
            AppLog.debug("Using OpenFoodFacts as primary source for \(barcode)", category: .network)
            candidate = off
        }

        guard let finalProduct = candidate else {
            AppLog.warning("No product data found for barcode \(barcode) from any source", category: .network)
            throw NetworkError.productNotFound
        }

        if !hasIngredients(in: finalProduct) {
            AppLog.warning("Unable to locate ingredients for barcode \(barcode) after all sources", category: .network)
        }

        return convertAPIProduct(finalProduct)
    }

    /// Fetches product from USDA, returning nil on failure
    private func fetchUSDAProduct(barcode: String) async -> APIProduct? {
        do {
            var product = try await usdaService.searchProductByBarcode(barcode)
            AppLog.debug("USDA initial ingredients count for \(barcode): \(product.ingredients.count) | raw length: \(product.rawIngredientsText?.count ?? 0)", category: .network)
            product = await enrichUSDAProduct(product)
            AppLog.debug("USDA enriched ingredients count for \(barcode): \(product.ingredients.count) | raw length: \(product.rawIngredientsText?.count ?? 0)", category: .network)
            return product
        } catch {
            AppLog.debug("USDA lookup failed for barcode \(barcode): \(error.localizedDescription)", category: .network)
            return nil
        }
    }

    /// Fetches product from Open Food Facts, returning nil on failure
    private func fetchOFFProduct(barcode: String) async -> APIProduct? {
        do {
            let product = try await openFoodFactsService.searchProductByBarcode(barcode)
            AppLog.debug("OFF found product for \(barcode): ingredients count \(product.ingredients.count) | raw length: \(product.rawIngredientsText?.count ?? 0)", category: .network)
            return product
        } catch {
            AppLog.debug("OFF lookup failed for barcode \(barcode): \(error.localizedDescription)", category: .network)
            return nil
        }
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
