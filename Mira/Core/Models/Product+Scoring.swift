import Foundation

// Bridge CoreData Product to ScoringEngine via ProductModel
extension Product {
    func calculateScore(for healthFocus: String, dietaryRestrictions: [DietaryRestriction] = []) -> HealthScore {
        let ingredientList = (ingredients ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        let processingLevel = ProcessingLevel.determine(for: ingredientList)

        // The stored nutritional data is per-serving (already scaled).
        // Normalize back to per-100g for scoring since thresholds are per-100g.
        let servingGrams = extractServingGrams(from: servingSize) ?? 100.0
        let normalizationFactor = servingGrams > 0 ? (100.0 / servingGrams) : 1.0
        let normalizedNutrition = NutritionalData(
            calories: nutritionalData.calories * normalizationFactor,
            protein: nutritionalData.protein * normalizationFactor,
            carbohydrates: nutritionalData.carbohydrates * normalizationFactor,
            fat: nutritionalData.fat * normalizationFactor,
            fiber: nutritionalData.fiber * normalizationFactor,
            sugar: nutritionalData.sugar * normalizationFactor,
            sodium: nutritionalData.sodium * normalizationFactor,
            cholesterol: nutritionalData.cholesterol * normalizationFactor
        )

        let model = ProductModel(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            brand: brand,
            category: category,
            categorySlug: nil,
            barcode: barcode,
            nutrition: ProductNutrition(
                calories: normalizedNutrition.calories,
                protein: normalizedNutrition.protein,
                carbohydrates: normalizedNutrition.carbohydrates,
                fat: normalizedNutrition.fat,
                fiber: normalizedNutrition.fiber,
                sugar: normalizedNutrition.sugar,
                sodium: normalizedNutrition.sodium,
                cholesterol: normalizedNutrition.cholesterol,
                servingSize: "100g"
            ),
            ingredients: ingredientList,
            additives: [],
            processingLevel: processingLevel,
            dietaryFlags: [],
            imageURL: imageURL,
            thumbnailURL: thumbnailURL,
            healthScore: 0,
            createdAt: lastScanned ?? Date(),
            updatedAt: lastScanned ?? Date(),
            isCached: true,
            rawIngredientsText: ingredients
        )

        let focus = HealthFocus(fromStored: healthFocus)
        return ScoringEngine.shared.calculateHealthScore(
            for: model,
            healthFocus: focus,
            dietaryRestrictions: dietaryRestrictions
        )
    }

    /// Extract serving size in grams from a serving size string like "28g", "1 oz (28g)", "2 tbsp (30 g)"
    private func extractServingGrams(from servingSize: String?) -> Double? {
        guard let servingSize = servingSize else { return nil }

        let lowered = servingSize.lowercased()

        // Try to find a number followed by 'g' (grams)
        let gramPattern = #"(\d+(?:\.\d+)?)\s*g(?:rams?)?\b"#
        if let regex = try? NSRegularExpression(pattern: gramPattern, options: []),
           let match = regex.firstMatch(in: lowered, options: [], range: NSRange(lowered.startIndex..., in: lowered)),
           let range = Range(match.range(at: 1), in: lowered) {
            return Double(lowered[range])
        }

        // Try to find a number followed by 'ml' for beverages (approximate 1ml = 1g)
        let mlPattern = #"(\d+(?:\.\d+)?)\s*ml\b"#
        if let regex = try? NSRegularExpression(pattern: mlPattern, options: []),
           let match = regex.firstMatch(in: lowered, options: [], range: NSRange(lowered.startIndex..., in: lowered)),
           let range = Range(match.range(at: 1), in: lowered) {
            return Double(lowered[range])
        }

        // Try to find a number followed by 'oz' and convert to grams (1 oz = 28.35g)
        let ozPattern = #"(\d+(?:\.\d+)?)\s*oz\b"#
        if let regex = try? NSRegularExpression(pattern: ozPattern, options: []),
           let match = regex.firstMatch(in: lowered, options: [], range: NSRange(lowered.startIndex..., in: lowered)),
           let range = Range(match.range(at: 1), in: lowered),
           let oz = Double(lowered[range]) {
            return oz * 28.35
        }

        return nil
    }
}
