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
        let servingReferenceUnits = extractServingReferenceUnits(from: servingSize) ?? 100.0
        let normalizationFactor = servingReferenceUnits > 0 ? (100.0 / servingReferenceUnits) : 1.0
        let normalizedNutrition = nutritionalData.scaled(by: normalizationFactor)
        var model = toProductModel(
            nutritionalData: normalizedNutrition,
            servingSize: "100g"
        )
        model.processingLevel = processingLevel

        let focus = HealthFocus(fromStored: healthFocus)
        return ScoringEngine.shared.calculateHealthScore(
            for: model,
            healthFocus: focus,
            dietaryRestrictions: dietaryRestrictions
        )
    }

    /// Extract a serving amount compatible with the source's 100 g/100 mL basis.
    private func extractServingReferenceUnits(from servingSize: String?) -> Double? {
        guard let servingSize = servingSize else { return nil }

        let lowered = servingSize.lowercased()

        // Try to find a number followed by 'g' (grams)
        let gramPattern = #"(\d+(?:\.\d+)?)\s*g(?:rams?)?\b"#
        if let regex = try? NSRegularExpression(pattern: gramPattern, options: []),
           let match = regex.firstMatch(in: lowered, options: [], range: NSRange(lowered.startIndex..., in: lowered)),
           let range = Range(match.range(at: 1), in: lowered) {
            return Double(lowered[range])
        }

        // For beverages, values normalized per 100 mL scale directly by mL.
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
