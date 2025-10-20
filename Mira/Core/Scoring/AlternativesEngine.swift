import Foundation
import Combine

final class AlternativesEngine {
    static let shared = AlternativesEngine()

    private let scoringEngine: ScoringEngine
    private let openFoodFactsService: OpenFoodFactsService

    private init(
        scoringEngine: ScoringEngine = .shared,
        openFoodFactsService: OpenFoodFactsService = .shared
    ) {
        self.scoringEngine = scoringEngine
        self.openFoodFactsService = openFoodFactsService
    }

    func findAlternatives(
        for product: ProductModel,
        healthFocus: HealthFocus,
        dietaryRestrictions: [DietaryRestriction],
        limit: Int = 5
    ) -> AnyPublisher<[AlternativeProduct], Error> {
        AppLog.debug("Finding alternatives for: \(product.name) [focus: \(healthFocus.rawValue)]", category: .scoring)
        return searchSimilarProducts(for: product)
            .map { [weak self] candidates in
                guard let self else { return [] }
                AppLog.debug("Candidates found: \(candidates.count)", category: .scoring)
                return self.rankAlternatives(
                    candidates: candidates,
                    originalProduct: product,
                    healthFocus: healthFocus,
                    dietaryRestrictions: dietaryRestrictions,
                    limit: limit
                )
            }
            .eraseToAnyPublisher()
    }

    private func searchSimilarProducts(for product: ProductModel) -> AnyPublisher<[ProductModel], Error> {
        let query = sanitizedQuery(from: product)
        let limit = 24

        return Future { [weak self] promise in
            guard let self else {
                promise(.success([]))
                return
            }

            Task {
                do {
                    let offProducts = try await self.openFoodFactsService.searchSimilarProducts(category: query, limit: limit)
                    let normalized = self.normalize(products: offProducts, excluding: product)
                    AppLog.debug("OFF alternatives fetched: \(normalized.count)", category: .network)
                    promise(.success(normalized))
                } catch {
                    AppLog.warning("OFF alternative search failed: \(error.localizedDescription)", category: .network)
                    promise(.success([]))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private func rankAlternatives(
        candidates: [ProductModel],
        originalProduct: ProductModel,
        healthFocus: HealthFocus,
        dietaryRestrictions: [DietaryRestriction],
        limit: Int
    ) -> [AlternativeProduct] {
        let originalScore = scoringEngine.calculateHealthScore(
            for: originalProduct,
            healthFocus: healthFocus,
            dietaryRestrictions: dietaryRestrictions
        )
        AppLog.debug("Original product score: \(Int(originalScore.overall.rounded())) for \(originalProduct.name)", category: .scoring)

        let improvedAlternatives = candidates.compactMap { candidate -> AlternativeProduct? in
            guard candidate.nutrition.isComplete else {
                AppLog.debug("Skipping candidate with incomplete nutrition: \(candidate.name)", category: .scoring)
                return nil
            }

            let candidateScore = scoringEngine.calculateHealthScore(
                for: candidate,
                healthFocus: healthFocus,
                dietaryRestrictions: dietaryRestrictions
            )
            let improvement = candidateScore.overall - originalScore.overall
            let improvementStr = String(format: "%.1f", improvement)
            AppLog.debug("Scoring alternative: \(candidate.name), Score: \(Int(candidateScore.overall.rounded())) (Δ \(improvementStr))", category: .scoring)

            guard improvement >= 1 else {
                return nil
            }

            let violations = scoringEngine.checkDietaryViolations(
                ingredients: candidate.ingredients,
                restrictions: dietaryRestrictions
            )

            guard violations.isEmpty else {
                AppLog.debug("Skipping candidate due to dietary violations: \(candidate.name)", category: .scoring)
                return nil
            }

            let reasons = generateImprovementReasons(
                original: originalScore,
                alternative: candidateScore,
                healthFocus: healthFocus
            )

            return AlternativeProduct(
                product: candidate,
                healthScore: candidateScore,
                improvement: improvement,
                improvementReasons: reasons,
                dietaryViolations: violations,
                similarity: calculateSimilarity(originalProduct, candidate)
            )
        }

        let sorted = improvedAlternatives.sorted { first, second in
            if abs(first.improvement - second.improvement) < 5 {
                return first.similarity > second.similarity
            }
            return first.improvement > second.improvement
        }

        let final = Array(sorted.prefix(limit))
        AppLog.debug("Final scored alternatives: \(final.count)", category: .scoring)
        return final
    }

    private func generateImprovementReasons(
        original: HealthScore,
        alternative: HealthScore,
        healthFocus: HealthFocus
    ) -> [String] {
        var reasons: [String] = []

        let comparisons: [(name: String, original: Double, alternative: Double, labelProvider: (Double) -> String?)] = [
            (
                name: "nutrition",
                original: original.components.macronutrientBalance.score,
                alternative: alternative.components.macronutrientBalance.score,
                labelProvider: { delta in
                    guard delta > 8 else { return nil }
                    switch healthFocus {
                    case .proteinFocus:
                        return "Higher protein quality"
                    case .weightLoss:
                        return "Better macro balance"
                    case .gutHealth:
                        return "More fiber-rich ingredients"
                    case .heartHealth:
                        return "Improved heart-healthy nutrient profile"
                    case .generalWellness:
                        return "Improved nutrition profile"
                    }
                }
            ),
            (
                name: "processing",
                original: original.components.processingLevel.score,
                alternative: alternative.components.processingLevel.score,
                labelProvider: { delta in delta > 6 ? "Less processed" : nil }
            ),
            (
                name: "ingredients",
                original: original.components.ingredientQuality.score,
                alternative: alternative.components.ingredientQuality.score,
                labelProvider: { delta in delta > 6 ? "Cleaner ingredient list" : nil }
            ),
            (
                name: "additives",
                original: original.components.additives.score,
                alternative: alternative.components.additives.score,
                labelProvider: { delta in delta > 6 ? "Fewer additives" : nil }
            )
        ]

        for comparison in comparisons {
            let delta = comparison.alternative - comparison.original
            if let label = comparison.labelProvider(delta), !reasons.contains(label) {
                reasons.append(label)
            }
        }

        if reasons.isEmpty {
            reasons.append("Higher overall score")
        }

        return reasons
    }

    private func calculateSimilarity(_ product1: ProductModel, _ product2: ProductModel) -> Double {
        var similarity: Double = 0

        if product1.brand?.lowercased() == product2.brand?.lowercased() {
            similarity += 30
        }

        let keywords1 = Set(
            product1.name
                .lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
        )
        let keywords2 = Set(
            product2.name
                .lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
        )
        let commonKeywords = keywords1.intersection(keywords2)
        if !keywords1.isEmpty && !keywords2.isEmpty {
            let keywordSimilarity = Double(commonKeywords.count) / Double(max(keywords1.count, keywords2.count)) * 40
            similarity += keywordSimilarity
        }

        let nutrition1 = product1.nutrition
        let nutrition2 = product2.nutrition

        let calorieDenominator = max(max(nutrition1.calories, nutrition2.calories), 1)
        let caloriesSimilarity = 1 - abs(nutrition1.calories - nutrition2.calories) / calorieDenominator

        let proteinDenominator = max(max(nutrition1.protein, nutrition2.protein), 1)
        let proteinSimilarity = 1 - abs(nutrition1.protein - nutrition2.protein) / proteinDenominator

        similarity += max(0, caloriesSimilarity * 10)
        similarity += max(0, proteinSimilarity * 10)

        return min(100, max(0, similarity))
    }

    // MARK: - Helpers
    func sanitizedQuery(from product: ProductModel) -> String {
        if let slug = product.categorySlug, !slug.isEmpty {
            return slug
        }

        if let category = product.category?.lowercased(), !category.isEmpty {
            let slug = category
                .replacingOccurrences(of: " ", with: "-")
                .replacingOccurrences(of: "_", with: "-")
            let normalized = slug.replacingOccurrences(of: "-", with: "")
            if !genericQueryTokens.contains(normalized) {
                return slug
            }
        }

        let lowercasedName = product.name.lowercased()
        if let directMatch = commonQueryCategories.first(where: { lowercasedName.contains($0) }) {
            return directMatch
        }

        if let keyword = firstValidQueryToken(in: keywordCandidates(from: product.name)) {
            return keyword
        }

        if let brand = product.brand,
           let keyword = firstValidQueryToken(in: keywordCandidates(from: brand)) {
            return keyword
        }

        return "food"
    }

    private func keywordCandidates(from text: String) -> [String] {
        text
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    private func firstValidQueryToken(in tokens: [String]) -> String? {
        tokens.first(where: { !genericQueryTokens.contains($0) })
    }

    private var commonQueryCategories: [String] {
        [
            "granola", "cereal", "yogurt", "bread", "milk", "cheese",
            "cracker", "crackers", "bar", "snack", "soup", "pasta",
            "sauce", "juice", "drink", "candy", "chocolate", "chips",
            "vinaigrette", "dressing", "salad-dressings"
        ]
    }

    private var genericQueryTokens: Set<String> {
        [
            "the", "and", "with", "without", "best", "product",
            "products", "food", "foods", "groceries", "grocery",
            "unknown"
        ]
    }

    private func normalize(products: [APIProduct], excluding original: ProductModel) -> [ProductModel] {
        products
            .filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .filter { $0.barcode != original.barcode }
            .filter { isUSProduct($0) }
            .map { convertAPIProduct($0) }
            .filter { $0.nutrition.isComplete }
    }

    /// Check if a product is available in the United States
    private func isUSProduct(_ product: APIProduct) -> Bool {
        guard let countriesTags = product.countriesTags else {
            // If countries data is not available, include the product (backwards compatibility)
            AppLog.debug("No countries data for product: \(product.name), including by default", category: .scoring)
            return true
        }

        // Check for US country tags
        let usCountryTags = ["en:united-states", "en:us", "united-states", "us"]
        let hasUSTag = countriesTags.contains { tag in
            usCountryTags.contains(tag.lowercased())
        }

        if !hasUSTag {
            AppLog.debug("Filtering out non-US product: \(product.name) | countries: \(countriesTags)", category: .scoring)
        }

        return hasUSTag
    }

    private func convertAPIProduct(_ api: APIProduct) -> ProductModel {
        let nutrition = ProductNutrition(
            calories: api.nutritionalData.calories,
            protein: api.nutritionalData.protein,
            carbohydrates: api.nutritionalData.carbohydrates,
            fat: api.nutritionalData.fat,
            fiber: api.nutritionalData.fiber,
            sugar: api.nutritionalData.sugar,
            sodium: api.nutritionalData.sodium,
            cholesterol: api.nutritionalData.cholesterol,
            servingSize: api.servingSize != nil ? "\(api.servingSize!)\(api.servingSizeUnit)" : "100g"
        )

        return ProductModel(
            id: UUID(),
            name: api.name,
            brand: api.brand,
            category: api.category,
            categorySlug: api.categorySlug,
            barcode: api.barcode,
            nutrition: nutrition,
            ingredients: api.ingredients,
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

struct AlternativeProduct {
    let product: ProductModel
    let healthScore: HealthScore
    let improvement: Double
    let improvementReasons: [String]
    let dietaryViolations: [DietaryRestriction]
    let similarity: Double
}
