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
                originalProduct: originalProduct,
                alternativeProduct: candidate,
                originalScore: originalScore,
                alternativeScore: candidateScore,
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
        originalProduct: ProductModel,
        alternativeProduct: ProductModel,
        originalScore: HealthScore,
        alternativeScore: HealthScore,
        healthFocus: HealthFocus
    ) -> [String] {
        var reasons: [String] = []

        let origNutr = originalProduct.nutrition
        let altNutr = alternativeProduct.nutrition
        let originalSodiumMg = origNutr.sodiumMilligrams
        let alternativeSodiumMg = altNutr.sodiumMilligrams

        // Specific nutritional comparisons with numbers
        let nutritionComparisons: [(check: Bool, reason: String)] = [
            // Protein
            (
                altNutr.protein > origNutr.protein + 2,
                "Higher protein (\(String(format: "%.1f", altNutr.protein))g vs \(String(format: "%.1f", origNutr.protein))g)"
            ),
            // Fiber
            (
                altNutr.fiber > origNutr.fiber + 1.5,
                "Higher fiber (\(String(format: "%.1f", altNutr.fiber))g vs \(String(format: "%.1f", origNutr.fiber))g)"
            ),
            // Lower sugar
            (
                altNutr.sugar < origNutr.sugar - 3 && altNutr.sugar > 0,
                "Lower sugar (\(String(format: "%.1f", altNutr.sugar))g vs \(String(format: "%.1f", origNutr.sugar))g)"
            ),
            // Lower sodium
            (
                alternativeSodiumMg < originalSodiumMg - 100 && originalSodiumMg > 200,
                "Lower sodium (\(String(format: "%.0f", alternativeSodiumMg))mg vs \(String(format: "%.0f", originalSodiumMg))mg)"
            ),
            // Lower calories (for weight loss focus)
            (
                healthFocus == .weightLoss && altNutr.calories < origNutr.calories - 20,
                "Lower calories (\(String(format: "%.0f", altNutr.calories)) vs \(String(format: "%.0f", origNutr.calories)))"
            )
        ]

        // Add nutritional improvements
        for comparison in nutritionComparisons {
            if comparison.check {
                reasons.append(comparison.reason)
            }
        }

        // Score component comparisons (fallback if no specific nutrients)
        if reasons.isEmpty {
            let componentComparisons: [(name: String, original: Double, alternative: Double, labelProvider: (Double) -> String?)] = [
                (
                    name: "processing",
                    original: originalScore.components.processingLevel.score,
                    alternative: alternativeScore.components.processingLevel.score,
                    labelProvider: { delta in delta > 6 ? "Less processed" : nil }
                ),
                (
                    name: "ingredients",
                    original: originalScore.components.ingredientQuality.score,
                    alternative: alternativeScore.components.ingredientQuality.score,
                    labelProvider: { delta in delta > 6 ? "Cleaner ingredients" : nil }
                ),
                (
                    name: "additives",
                    original: originalScore.components.additives.score,
                    alternative: alternativeScore.components.additives.score,
                    labelProvider: { delta in delta > 6 ? "Fewer additives" : nil }
                ),
                (
                    name: "nutrition",
                    original: originalScore.components.macronutrientBalance.score,
                    alternative: alternativeScore.components.macronutrientBalance.score,
                    labelProvider: { delta in delta > 8 ? "Better nutrition profile" : nil }
                )
            ]

            for comparison in componentComparisons {
                let delta = comparison.alternative - comparison.original
                if let label = comparison.labelProvider(delta), !reasons.contains(label) {
                    reasons.append(label)
                }
            }
        }

        // Last resort
        if reasons.isEmpty {
            reasons.append("Higher overall score")
        }

        return Array(reasons.prefix(3)) // Limit to top 3 reasons
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
        // Use shared converter to avoid duplicate conversion logic
        ProductModelConverter.convertAndFilter(products, excluding: original.barcode, usOnly: true)
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
