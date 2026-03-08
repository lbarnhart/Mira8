import Foundation

/// Service for AI-powered ingredient analysis using Claude API.
/// Provides research-backed ingredient assessments personalized to user's health focus.
actor IngredientAIService {
    static let shared = IngredientAIService()

    private let claudeService = ClaudeService.shared

    /// Analyzes an ingredient using AI, personalized to the user's health focus and dietary restrictions.
    /// - Parameters:
    ///   - name: The ingredient name to analyze
    ///   - healthFocus: The user's health focus (e.g., "gutHealth", "heartHealth")
    ///   - dietaryRestrictions: The user's dietary restrictions (e.g., ["vegan", "glutenFree"])
    /// - Returns: An AI-generated analysis of the ingredient
    func analyzeIngredient(
        name: String,
        healthFocus: String,
        dietaryRestrictions: Set<String>
    ) async throws -> AIIngredientAnalysis {
        let healthFocusDisplay = healthFocusDisplayName(for: healthFocus)
        let restrictionsHash = dietaryRestrictions.sorted().joined(separator: "_")
        let cacheKey = "ingredient_\(name.lowercased().replacingOccurrences(of: " ", with: "_"))_\(healthFocus)_\(restrictionsHash)"

        let systemPrompt = """
        You are a nutrition scientist assistant for the Mira health app. Your role is to \
        analyze food ingredients and provide accurate, research-backed assessments.

        Guidelines:
        - Be factual and cite research when available
        - Tailor advice to the user's specific health focus
        - Flag ingredients that conflict with dietary restrictions
        - Use accessible language (8th grade reading level)
        - Be balanced - don't fear-monger but don't dismiss legitimate concerns
        - If evidence is mixed or inconclusive, say so
        - Keep the summary to 1-2 sentences
        - Keep the detailed explanation to 2-3 paragraphs

        Response format (JSON only, no markdown code blocks):
        {
            "ingredientName": "the ingredient name",
            "healthFocus": "the health focus",
            "safetyRating": "safe" | "caution" | "avoid",
            "summary": "1-2 sentence summary",
            "detailedExplanation": "2-3 paragraph explanation",
            "researchContext": "What studies say (optional, can be null)",
            "relevantRestrictions": ["list of affected dietary restrictions"],
            "alternatives": ["healthier alternatives if applicable"],
            "confidence": 0.0-1.0
        }
        """

        let restrictionsList = dietaryRestrictions.sorted().joined(separator: ", ")

        let userPrompt = """
        Analyze this ingredient: "\(name)"

        User's health focus: \(healthFocusDisplay)
        User's dietary restrictions: \(restrictionsList.isEmpty ? "None" : restrictionsList)

        Provide your analysis in the specified JSON format.
        """

        return try await claudeService.completeJSON(
            prompt: userPrompt,
            systemPrompt: systemPrompt,
            model: .haiku,
            cacheKey: cacheKey
        )
    }

    /// Check if the AI service is available (API key configured)
    var isAvailable: Bool {
        get async {
            await claudeService.isConfigured
        }
    }

    // MARK: - Private Helpers

    private func healthFocusDisplayName(for identifier: String) -> String {
        switch identifier {
        case "generalWellness": return "General Wellness"
        case "gutHealth": return "Gut Health"
        case "heartHealth": return "Heart Health"
        case "proteinFocus": return "Protein Focus"
        case "weightLoss": return "Weight Loss"
        default: return "General Wellness"
        }
    }
}
