import Foundation
import Combine

/// ViewModel for natural language product search
@MainActor
final class NLSearchViewModel: ObservableObject {
    // MARK: - Published State

    @Published var query: String = ""
    @Published var parsedQuery: ParsedQuery?
    @Published var results: [NLSearchResult] = []
    @Published var isLoading = false
    @Published var isParsing = false
    @Published var errorMessage: String?

    @Published var sortOption: SortOption = .relevance
    @Published var showFiltersSheet = false

    // MARK: - Search History

    @Published var recentSearches: [String] = []
    @Published var suggestedQueries: [String] = [
        "high protein vegan snacks",
        "low sugar breakfast cereals",
        "gluten free under 200 calories",
        "low sodium chips",
        "high fiber bars"
    ]

    // MARK: - Dependencies

    private let searchService = NLSearchService.shared
    private let usdaService = USDAService.shared
    private let openFoodFactsService = OpenFoodFactsService.shared
    private let scoringEngine = ScoringEngine.shared

    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // Health focus for scoring
    var healthFocus: HealthFocus = .generalWellness
    var dietaryRestrictions: [DietaryRestriction] = []

    // MARK: - Initialization

    init() {
        loadRecentSearches()

        // Debounce query changes
        $query
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] newQuery in
                guard let self else { return }
                if !newQuery.isEmpty {
                    self.parseAndSearch(query: newQuery)
                } else {
                    self.parsedQuery = nil
                    self.results = []
                }
            }
            .store(in: &cancellables)

        // Re-sort when sort option changes
        $sortOption
            .dropFirst()
            .sink { [weak self] _ in
                self?.sortResults()
            }
            .store(in: &cancellables)
    }

    // MARK: - Search Methods

    func search() {
        guard !query.isEmpty else { return }
        parseAndSearch(query: query)
    }

    func searchWithSuggestion(_ suggestion: String) {
        query = suggestion
        parseAndSearch(query: suggestion)
    }

    func clearSearch() {
        query = ""
        parsedQuery = nil
        results = []
        errorMessage = nil
    }

    private func parseAndSearch(query: String) {
        searchTask?.cancel()

        searchTask = Task { [weak self] in
            guard let self else { return }

            self.isParsing = true
            self.isLoading = true
            self.errorMessage = nil

            do {
                // Parse the query
                let parsed = try await searchService.parseQuery(query)
                guard !Task.isCancelled else { return }

                self.parsedQuery = parsed
                self.isParsing = false

                // Save to recent searches
                self.addToRecentSearches(query)

                // Execute search - query both USDA and OFF in parallel for best coverage
                var usdaProducts: [APIProduct] = []
                var offProducts: [APIProduct] = []

                async let usdaResult: [APIProduct] = {
                    do {
                        let results = try await usdaService.searchWithFilters(parsed.filters, limit: 30)
                        AppLog.debug("🇺🇸 Search: USDA returned \(results.count) products", category: .network)
                        return results
                    } catch {
                        AppLog.warning("🇺🇸 Search: USDA search failed: \(error.localizedDescription)", category: .network)
                        return []
                    }
                }()

                async let offResult: [APIProduct] = {
                    do {
                        let results = try await openFoodFactsService.searchWithFilters(parsed.filters, limit: 30)
                        AppLog.debug("🌍 Search: OFF returned \(results.count) products", category: .network)
                        return results
                    } catch {
                        AppLog.warning("🌍 Search: OFF search failed: \(error.localizedDescription)", category: .network)
                        return []
                    }
                }()

                usdaProducts = await usdaResult
                offProducts = await offResult

                guard !Task.isCancelled else { return }

                // Merge results: prefer OFF products (which have images) over USDA duplicates
                var products: [APIProduct] = []
                var seenBarcodes = Set<String>()

                // Add OFF products first (they have images)
                for product in offProducts {
                    let barcode = product.barcode
                    if !barcode.isEmpty {
                        seenBarcodes.insert(barcode)
                    }
                    products.append(product)
                }

                // Add USDA products that aren't duplicates
                for product in usdaProducts {
                    let barcode = product.barcode
                    if barcode.isEmpty || !seenBarcodes.contains(barcode) {
                        if !barcode.isEmpty {
                            seenBarcodes.insert(barcode)
                        }
                        products.append(product)
                    }
                }

                guard !Task.isCancelled else { return }

                // Score and create results
                self.results = self.createSearchResults(products: products, query: parsed)
                self.sortResults()
                self.isLoading = false

            } catch {
                guard !Task.isCancelled else { return }

                self.isParsing = false
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                AppLog.error("Search failed: \(error.localizedDescription)", category: .network)
            }
        }
    }

    private func createSearchResults(products: [APIProduct], query: ParsedQuery) -> [NLSearchResult] {
        products.compactMap { apiProduct in
            let product = ProductModelConverter.convert(apiProduct)

            // Calculate health score
            let healthScore = scoringEngine.calculateHealthScore(
                for: product,
                healthFocus: healthFocus,
                dietaryRestrictions: dietaryRestrictions
            )

            // Calculate relevance based on filter matches
            let (matchedFilters, relevanceScore) = calculateRelevance(
                product: product,
                filters: query.filters
            )

            return NLSearchResult(
                product: product,
                healthScore: healthScore,
                matchedFilters: matchedFilters,
                relevanceScore: relevanceScore
            )
        }
    }

    private func calculateRelevance(product: ProductModel, filters: SearchFilters) -> (matched: [String], score: Double) {
        var matched: [String] = []
        var score: Double = 0.5 // Base score

        // Check protein
        if let min = filters.proteinMin, product.nutrition.protein >= min {
            matched.append("High Protein")
            score += 0.1
        }

        // Check calories
        if let max = filters.caloriesMax, product.nutrition.calories <= max {
            matched.append("Low Calorie")
            score += 0.1
        }

        // Check sugar
        if let max = filters.sugarMax, product.nutrition.sugar <= max {
            matched.append("Low Sugar")
            score += 0.1
        }

        // Check fiber
        if let min = filters.fiberMin, product.nutrition.fiber >= min {
            matched.append("High Fiber")
            score += 0.1
        }

        // Check category match
        if !filters.categories.isEmpty {
            if let productCategory = product.category?.lowercased() {
                for category in filters.categories {
                    if productCategory.contains(category.lowercased()) {
                        matched.append(category.capitalized)
                        score += 0.15
                        break
                    }
                }
            }
        }

        return (matched, min(score, 1.0))
    }

    private func sortResults() {
        switch sortOption {
        case .relevance:
            results.sort { $0.relevanceScore > $1.relevanceScore }
        case .healthScore:
            results.sort { $0.healthScore.overall > $1.healthScore.overall }
        case .proteinHighToLow:
            results.sort { $0.product.nutrition.protein > $1.product.nutrition.protein }
        case .caloriesLowToHigh:
            results.sort { $0.product.nutrition.calories < $1.product.nutrition.calories }
        case .sugarLowToHigh:
            results.sort { $0.product.nutrition.sugar < $1.product.nutrition.sugar }
        }
    }

    // MARK: - Recent Searches

    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []
    }

    private func addToRecentSearches(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Remove if exists, add to front
        recentSearches.removeAll { $0.lowercased() == trimmed.lowercased() }
        recentSearches.insert(trimmed, at: 0)

        // Keep only last 10
        if recentSearches.count > 10 {
            recentSearches = Array(recentSearches.prefix(10))
        }

        UserDefaults.standard.set(recentSearches, forKey: "recentSearches")
    }

    func removeRecentSearch(_ query: String) {
        recentSearches.removeAll { $0 == query }
        UserDefaults.standard.set(recentSearches, forKey: "recentSearches")
    }

    func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: "recentSearches")
    }

    // MARK: - Filter Adjustments

    func updateFilters(_ newFilters: SearchFilters) {
        guard let currentParsed = parsedQuery else { return }

        let updatedParsed = ParsedQuery(
            originalQuery: currentParsed.originalQuery,
            filters: newFilters,
            confidence: currentParsed.confidence,
            interpretation: "Manually adjusted filters"
        )

        parsedQuery = updatedParsed

        // Re-run search with new filters - USDA first, OFF as fallback
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            guard let self else { return }

            self.isLoading = true
            self.errorMessage = nil

            async let usdaResult: [APIProduct] = {
                do {
                    return try await usdaService.searchWithFilters(newFilters, limit: 30)
                } catch {
                    AppLog.warning("🇺🇸 Filter update: USDA search failed", category: .network)
                    return []
                }
            }()

            async let offResult: [APIProduct] = {
                do {
                    return try await openFoodFactsService.searchWithFilters(newFilters, limit: 30)
                } catch {
                    AppLog.warning("🌍 Filter update: OFF search failed", category: .network)
                    return []
                }
            }()

            let usdaProducts = await usdaResult
            let offProducts = await offResult

            guard !Task.isCancelled else { return }

            // Merge: prefer OFF (has images) over USDA duplicates
            var products: [APIProduct] = []
            var seenBarcodes = Set<String>()

            for product in offProducts {
                if !product.barcode.isEmpty { seenBarcodes.insert(product.barcode) }
                products.append(product)
            }
            for product in usdaProducts {
                if product.barcode.isEmpty || !seenBarcodes.contains(product.barcode) {
                    if !product.barcode.isEmpty { seenBarcodes.insert(product.barcode) }
                    products.append(product)
                }
            }

            self.results = self.createSearchResults(products: products, query: updatedParsed)
            self.sortResults()
            self.isLoading = false
        }
    }

    // MARK: - Configuration

    func configure(healthFocus: HealthFocus, restrictions: Set<String>) {
        self.healthFocus = healthFocus
        self.dietaryRestrictions = restrictions.compactMap { DietaryRestriction(from: $0) }
    }
}
