import Foundation

/// Service for parsing natural language search queries into structured filters.
/// Uses a combination of regex pattern matching and AI for complex queries.
actor NLSearchService {
    static let shared = NLSearchService()

    private let claudeService = ClaudeService.shared

    /// Parse a natural language query into structured filters.
    /// - Parameter query: The user's search query (e.g., "high protein vegan snacks")
    /// - Returns: A ParsedQuery containing the extracted filters
    func parseQuery(_ query: String) async throws -> ParsedQuery {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else {
            return ParsedQuery(
                originalQuery: query,
                filters: SearchFilters(),
                confidence: 0,
                interpretation: "Empty query"
            )
        }

        // First try fast regex-based parsing
        let regexResult = parseWithRegex(trimmedQuery)

        // If regex parsing is confident enough, use it
        if regexResult.confidence >= 0.7 {
            return regexResult
        }

        // For complex queries, use AI parsing
        let isAIAvailable = await claudeService.isConfigured
        if isAIAvailable && regexResult.confidence < 0.5 {
            do {
                let aiResult = try await parseWithAI(trimmedQuery)
                // Merge AI result with regex result, preferring AI
                return mergeResults(regex: regexResult, ai: aiResult)
            } catch {
                AppLog.warning("AI query parsing failed, using regex fallback: \(error.localizedDescription)", category: .general)
            }
        }

        return regexResult
    }

    // MARK: - Regex-Based Parsing

    private func parseWithRegex(_ query: String) -> ParsedQuery {
        let lowercased = query.lowercased()
        var filters = SearchFilters()
        var confidence: Double = 0.3
        var interpretations: [String] = []

        // Parse "high protein"
        if lowercased.contains("high protein") || lowercased.contains("protein rich") {
            filters.proteinMin = 15
            confidence += 0.2
            interpretations.append("high protein (≥15g)")
        }

        // Parse "low calorie" / "under X calories"
        if lowercased.contains("low calorie") || lowercased.contains("low cal") {
            filters.caloriesMax = 150
            confidence += 0.15
            interpretations.append("low calorie (≤150)")
        }

        if let match = lowercased.range(of: "under (\\d+) cal", options: .regularExpression) {
            let numberRange = lowercased[match]
            if let number = extractNumber(from: String(numberRange)) {
                filters.caloriesMax = number
                confidence += 0.2
                interpretations.append("≤\(Int(number)) calories")
            }
        }

        // Parse "less than X calories"
        if let match = lowercased.range(of: "less than (\\d+) cal", options: .regularExpression) {
            let numberRange = lowercased[match]
            if let number = extractNumber(from: String(numberRange)) {
                filters.caloriesMax = number
                confidence += 0.2
                interpretations.append("≤\(Int(number)) calories")
            }
        }

        // Parse "low sugar" / "no sugar" / "sugar free"
        if lowercased.contains("low sugar") {
            filters.sugarMax = 5
            confidence += 0.15
            interpretations.append("low sugar (≤5g)")
        }
        if lowercased.contains("no sugar") || lowercased.contains("sugar free") || lowercased.contains("sugar-free") {
            filters.sugarMax = 1
            confidence += 0.15
            interpretations.append("sugar free (≤1g)")
        }

        // Parse "high fiber"
        if lowercased.contains("high fiber") || lowercased.contains("fiber rich") {
            filters.fiberMin = 5
            confidence += 0.15
            interpretations.append("high fiber (≥5g)")
        }

        // Parse "low sodium" / "low salt"
        if lowercased.contains("low sodium") || lowercased.contains("low salt") {
            filters.sodiumMax = 140
            confidence += 0.15
            interpretations.append("low sodium (≤140mg)")
        }

        // Parse "low fat"
        if lowercased.contains("low fat") {
            filters.fatMax = 3
            confidence += 0.15
            interpretations.append("low fat (≤3g)")
        }

        // Parse "low carb" / "keto"
        if lowercased.contains("low carb") || lowercased.contains("keto") {
            filters.carbsMax = 10
            confidence += 0.15
            interpretations.append("low carb (≤10g)")
        }

        // Parse dietary restrictions
        let dietaryPatterns: [(pattern: String, restriction: String, name: String)] = [
            ("vegan", "vegan", "vegan"),
            ("vegetarian", "vegetarian", "vegetarian"),
            ("gluten.?free", "gluten_free", "gluten-free"),
            ("dairy.?free", "dairy_free", "dairy-free"),
            ("nut.?free", "nut_free", "nut-free"),
            ("plant.?based", "vegan", "plant-based")
        ]

        for (pattern, restriction, name) in dietaryPatterns {
            if lowercased.range(of: pattern, options: .regularExpression) != nil {
                filters.dietaryRestrictions.insert(restriction)
                confidence += 0.2
                interpretations.append(name)
            }
        }

        // Parse categories from common terms
        let categoryPatterns: [(pattern: String, categories: [String])] = [
            ("snack", ["snacks"]),
            ("breakfast", ["breakfast", "cereals"]),
            ("cereal", ["cereals"]),
            ("bar", ["snack-bars", "protein-bars"]),
            ("chip", ["chips"]),
            ("cookie", ["cookies"]),
            ("yogurt", ["yogurt"]),
            ("drink", ["beverages"]),
            ("beverage", ["beverages"]),
            ("protein shake", ["protein"]),
            ("smoothie", ["beverages"]),
            ("frozen", ["frozen-foods"]),
            ("soup", ["soups"]),
            ("pasta", ["pasta"]),
            ("bread", ["breads"])
        ]

        for (pattern, categories) in categoryPatterns {
            if lowercased.contains(pattern) {
                filters.categories.append(contentsOf: categories)
                confidence += 0.15
                interpretations.append(pattern)
            }
        }

        // Remove duplicates from categories
        filters.categories = Array(Set(filters.categories))

        // Extract remaining search terms (words not matched by patterns)
        var remainingTerms = extractRemainingTerms(from: lowercased, matchedPatterns: interpretations)
        filters.searchTerms = remainingTerms.filter { $0.count > 2 }

        // Cap confidence
        confidence = min(confidence, 0.95)

        let interpretation = interpretations.isEmpty ? "General search" : interpretations.joined(separator: ", ")

        return ParsedQuery(
            originalQuery: query,
            filters: filters,
            confidence: confidence,
            interpretation: interpretation
        )
    }

    private func extractNumber(from text: String) -> Double? {
        let pattern = "\\d+"
        if let match = text.range(of: pattern, options: .regularExpression) {
            return Double(text[match])
        }
        return nil
    }

    private func extractRemainingTerms(from query: String, matchedPatterns: [String]) -> [String] {
        var remaining = query
        let stopWords = ["high", "low", "free", "under", "less", "than", "with", "without", "and", "or", "the", "a", "an"]

        // Remove matched pattern keywords
        for pattern in matchedPatterns {
            remaining = remaining.replacingOccurrences(of: pattern, with: " ", options: .caseInsensitive)
        }

        // Split and filter
        let words = remaining.components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty && !stopWords.contains($0.lowercased()) }

        return words
    }

    // MARK: - AI-Based Parsing

    private func parseWithAI(_ query: String) async throws -> ParsedQuery {
        let cacheKey = "nlsearch_\(query.lowercased().replacingOccurrences(of: " ", with: "_").prefix(50))"

        let systemPrompt = """
        You are a search query parser for a food/grocery app. Parse natural language search \
        queries into structured filters.

        Extract the following when present:
        - Nutritional constraints (calories, protein, sugar, fiber, sodium, fat, carbs)
        - Dietary restrictions (vegan, vegetarian, gluten-free, dairy-free, nut-free)
        - Food categories (snacks, breakfast, drinks, etc.)
        - Search terms for product names/brands

        Guidelines:
        - "high protein" typically means ≥15g
        - "low calorie" typically means ≤150 calories
        - "low sugar" typically means ≤5g
        - "high fiber" typically means ≥5g
        - "low sodium" typically means ≤140mg
        - Be conservative - only extract what's explicitly mentioned

        Response format (JSON only, no markdown):
        {
            "caloriesMin": null or number,
            "caloriesMax": null or number,
            "proteinMin": null or number,
            "proteinMax": null or number,
            "carbsMax": null or number,
            "fatMax": null or number,
            "fiberMin": null or number,
            "sugarMax": null or number,
            "sodiumMax": null or number,
            "dietaryRestrictions": ["vegan", "gluten_free", etc.],
            "categories": ["snacks", "breakfast", etc.],
            "searchTerms": ["remaining", "keywords"],
            "interpretation": "Brief description of what was understood",
            "confidence": 0.0-1.0
        }
        """

        let userPrompt = """
        Parse this search query: "\(query)"

        Extract filters and provide JSON response.
        """

        let response: AIQueryParseResponse = try await claudeService.completeJSON(
            prompt: userPrompt,
            systemPrompt: systemPrompt,
            model: .haiku, // Use Haiku for cost efficiency
            cacheKey: cacheKey
        )

        let filters = SearchFilters(
            caloriesMin: response.caloriesMin,
            caloriesMax: response.caloriesMax,
            proteinMin: response.proteinMin,
            proteinMax: response.proteinMax,
            carbsMax: response.carbsMax,
            fatMax: response.fatMax,
            fiberMin: response.fiberMin,
            sugarMax: response.sugarMax,
            sodiumMax: response.sodiumMax,
            dietaryRestrictions: Set(response.dietaryRestrictions),
            categories: response.categories,
            searchTerms: response.searchTerms
        )

        return ParsedQuery(
            originalQuery: query,
            filters: filters,
            confidence: response.confidence,
            interpretation: response.interpretation
        )
    }

    private func mergeResults(regex: ParsedQuery, ai: ParsedQuery) -> ParsedQuery {
        // Prefer AI result if it has higher confidence
        if ai.confidence > regex.confidence {
            return ai
        }

        // Otherwise, merge both results
        var mergedFilters = ai.filters

        // Use regex values as fallback
        if mergedFilters.caloriesMax == nil { mergedFilters.caloriesMax = regex.filters.caloriesMax }
        if mergedFilters.proteinMin == nil { mergedFilters.proteinMin = regex.filters.proteinMin }
        if mergedFilters.sugarMax == nil { mergedFilters.sugarMax = regex.filters.sugarMax }
        if mergedFilters.fiberMin == nil { mergedFilters.fiberMin = regex.filters.fiberMin }

        mergedFilters.dietaryRestrictions = ai.filters.dietaryRestrictions.union(regex.filters.dietaryRestrictions)
        mergedFilters.categories = Array(Set(ai.filters.categories + regex.filters.categories))

        return ParsedQuery(
            originalQuery: ai.originalQuery,
            filters: mergedFilters,
            confidence: max(regex.confidence, ai.confidence),
            interpretation: ai.interpretation
        )
    }

    // MARK: - Availability

    var isAIAvailable: Bool {
        get async {
            await claudeService.isConfigured
        }
    }
}

// MARK: - AI Response Model

private struct AIQueryParseResponse: Codable {
    let caloriesMin: Double?
    let caloriesMax: Double?
    let proteinMin: Double?
    let proteinMax: Double?
    let carbsMax: Double?
    let fatMax: Double?
    let fiberMin: Double?
    let sugarMax: Double?
    let sodiumMax: Double?
    let dietaryRestrictions: [String]
    let categories: [String]
    let searchTerms: [String]
    let interpretation: String
    let confidence: Double
}
