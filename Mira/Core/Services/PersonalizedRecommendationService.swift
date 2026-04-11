import Foundation
import os

/// Service that generates personalized recommendations based on user nutrition profile.
/// Uses Claude AI for natural language insights and actionable suggestions.
actor PersonalizedRecommendationService {

    private let claudeService: ClaudeService
    private let profilerService: NutritionProfilerService
    private let logger = Logger(subsystem: "com.mira8.app", category: "PersonalizedRecommendation")

    // Cache for insights
    private var insightCache: [String: (insight: WeeklyInsight, cachedAt: Date)] = [:]
    private let cacheTTL: TimeInterval = 3600 // 1 hour

    init(
        claudeService: ClaudeService = .shared,
        profilerService: NutritionProfilerService? = nil
    ) {
        self.claudeService = claudeService
        self.profilerService = profilerService ?? NutritionProfilerService()
    }

    // MARK: - Public API

    /// Generate weekly insight for the user
    func generateWeeklyInsight(
        healthFocus: HealthFocus,
        dietaryRestrictions: Set<String>
    ) async throws -> WeeklyInsight {
        let cacheKey = "\(healthFocus.rawValue)_\(dietaryRestrictions.sorted().joined(separator: "_"))"

        // Check cache
        if let cached = insightCache[cacheKey],
           Date().timeIntervalSince(cached.cachedAt) < cacheTTL {
            logger.debug("Returning cached weekly insight")
            return cached.insight
        }

        logger.info("Generating weekly insight for \(healthFocus.rawValue)")

        // Build profile
        let profile = try await profilerService.buildProfile(
            period: .week,
            healthFocus: healthFocus
        )

        // Generate insight
        let insight: WeeklyInsight

        if profile.hasEnoughData {
            if await claudeService.isConfigured {
                do {
                    insight = try await generateAIInsight(
                        profile: profile,
                        dietaryRestrictions: dietaryRestrictions
                    )
                } catch {
                    logger.warning("AI insight generation failed, using deterministic fallback: \(error.localizedDescription)")
                    insight = generateFallbackInsight(profile: profile)
                }
            } else {
                logger.info("Claude is not configured, using deterministic fallback insight")
                insight = generateFallbackInsight(profile: profile)
            }
        } else {
            insight = generateMinimalDataInsight(
                profile: profile,
                healthFocus: healthFocus
            )
        }

        // Cache the insight
        insightCache[cacheKey] = (insight, Date())

        return insight
    }

    /// Invalidate cached insights (call after new scans)
    func invalidateCache() async {
        insightCache.removeAll()
        await profilerService.invalidateCache()
        logger.debug("Recommendation cache invalidated")
    }

    // MARK: - AI Insight Generation

    private func generateAIInsight(
        profile: UserNutritionProfile,
        dietaryRestrictions: Set<String>
    ) async throws -> WeeklyInsight {
        let prompt = buildInsightPrompt(profile: profile, restrictions: dietaryRestrictions)

        let response = try await claudeService.complete(
            prompt: prompt,
            model: .haiku,
            maxTokens: 1500
        )

        // Parse the AI response
        return parseAIResponse(response, profile: profile)
    }

    private func buildInsightPrompt(
        profile: UserNutritionProfile,
        restrictions: Set<String>
    ) -> String {
        let gapsSummary = profile.gaps.map { gap in
            let direction = gap.isDeficiency ? "below" : "above"
            return "- \(gap.nutrient.displayName): \(String(format: "%.1f", gap.currentAverage))\(gap.nutrient.unit) (target: \(String(format: "%.1f", gap.recommendedTarget))\(gap.nutrient.unit), \(Int(abs(gap.gapPercentage)))% \(direction))"
        }.joined(separator: "\n")

        let patternsSummary = profile.patterns.map { pattern in
            "- \(pattern.description)"
        }.joined(separator: "\n")

        let restrictionsList = restrictions.isEmpty ? "None" : restrictions.joined(separator: ", ")

        return """
        You are a friendly nutrition advisor analyzing a user's weekly food scanning data.

        USER PROFILE:
        - Health Focus: \(profile.healthFocus.displayName)
        - Products Scanned This Week: \(profile.scanCount)
        - Dietary Restrictions: \(restrictionsList)

        NUTRITIONAL AVERAGES (per product scanned):
        - Calories: \(String(format: "%.0f", profile.averages.calories)) kcal
        - Protein: \(String(format: "%.1f", profile.averages.protein))g
        - Fiber: \(String(format: "%.1f", profile.averages.fiber))g
        - Sugar: \(String(format: "%.1f", profile.averages.sugar))g
        - Sodium: \(String(format: "%.0f", profile.averages.sodium))mg
        - Saturated Fat: \(String(format: "%.1f", profile.averages.saturatedFat))g

        IDENTIFIED NUTRITION GAPS:
        \(gapsSummary.isEmpty ? "No significant gaps detected" : gapsSummary)

        CONSUMPTION PATTERNS:
        \(patternsSummary.isEmpty ? "Not enough data for pattern detection" : patternsSummary)

        Please provide a personalized weekly insight in the following JSON format:
        {
          "title": "Brief encouraging title (5-8 words)",
          "summary": "2-3 sentence personalized summary of their week",
          "highlights": [
            {"type": "positive|neutral|needs_attention", "message": "Specific observation", "value": "optional metric"},
            ...
          ],
          "recommendations": [
            {"priority": 1, "action": "Specific actionable advice", "rationale": "Brief explanation", "nutrient": "protein|fiber|sugar|sodium|etc or null"},
            ...
          ]
        }

        Guidelines:
        - Be encouraging but honest
        - Focus on 2-3 most impactful changes
        - Make recommendations specific and actionable
        - Consider their health focus (\(profile.healthFocus.displayName)) in all advice
        - Respect their dietary restrictions
        - Use simple, friendly language
        """
    }

    private func parseAIResponse(_ response: String, profile: UserNutritionProfile) -> WeeklyInsight {
        // Try to extract JSON from response
        guard let jsonStart = response.firstIndex(of: "{"),
              let jsonEnd = response.lastIndex(of: "}") else {
            logger.warning("Could not find JSON in AI response, using fallback")
            return generateFallbackInsight(profile: profile)
        }

        let jsonString = String(response[jsonStart...jsonEnd])

        guard let data = jsonString.data(using: .utf8) else {
            return generateFallbackInsight(profile: profile)
        }

        do {
            let parsed = try JSONDecoder().decode(AIInsightResponse.self, from: data)
            return convertToWeeklyInsight(parsed, profile: profile)
        } catch {
            logger.error("Failed to parse AI insight: \(error.localizedDescription)")
            return generateFallbackInsight(profile: profile)
        }
    }

    private func convertToWeeklyInsight(_ response: AIInsightResponse, profile: UserNutritionProfile) -> WeeklyInsight {
        let highlights = response.highlights.map { highlight in
            InsightHighlight(
                type: HighlightType(rawValue: highlight.type) ?? .neutral,
                message: highlight.message,
                value: highlight.value
            )
        }

        let actions = response.recommendations.enumerated().map { index, rec in
            RecommendedAction(
                priority: rec.priority ?? (index + 1),
                action: rec.action,
                rationale: rec.rationale,
                relatedNutrient: rec.nutrient.flatMap { InsightNutrientType(rawValue: $0) }
            )
        }

        return WeeklyInsight(
            title: response.title,
            summary: response.summary,
            highlights: highlights,
            topGaps: Array(profile.gaps.prefix(3)),
            recommendedActions: actions,
            generatedAt: Date()
        )
    }

    // MARK: - Fallback Generation

    private func generateMinimalDataInsight(
        profile: UserNutritionProfile,
        healthFocus: HealthFocus
    ) -> WeeklyInsight {
        WeeklyInsight(
            title: "Keep Scanning to Unlock Insights",
            summary: "You've scanned \(profile.scanCount) product\(profile.scanCount == 1 ? "" : "s") this week. Scan at least 5 products to get personalized nutrition insights tailored to your \(healthFocus.displayName) goals.",
            highlights: [
                InsightHighlight(
                    type: .neutral,
                    message: "Scan more products to build your profile",
                    value: "\(profile.scanCount)/5"
                )
            ],
            topGaps: [],
            recommendedActions: [
                RecommendedAction(
                    priority: 1,
                    action: "Scan your regular grocery items",
                    rationale: "This helps us understand your typical food choices",
                    relatedNutrient: nil
                )
            ],
            generatedAt: Date()
        )
    }

    private func generateFallbackInsight(profile: UserNutritionProfile) -> WeeklyInsight {
        var highlights: [InsightHighlight] = []
        var actions: [RecommendedAction] = []

        // Generate basic highlights from gaps
        for (index, gap) in profile.gaps.prefix(3).enumerated() {
            let type: HighlightType = gap.severity == .significant ? .needsAttention : .neutral
            highlights.append(InsightHighlight(
                type: type,
                message: gap.description,
                value: "\(String(format: "%.1f", gap.currentAverage))\(gap.nutrient.unit)"
            ))

            // Generate corresponding action
            let action = generateActionForGap(gap)
            actions.append(RecommendedAction(
                priority: index + 1,
                action: action.0,
                rationale: action.1,
                relatedNutrient: gap.nutrient
            ))
        }

        // Add positive highlight if profile looks good
        if profile.gaps.isEmpty || profile.gaps.allSatisfy({ $0.severity == .mild }) {
            highlights.insert(InsightHighlight(
                type: .positive,
                message: "Your food choices align well with your health goals",
                value: nil
            ), at: 0)
        }

        return WeeklyInsight(
            title: "Your Weekly Nutrition Summary",
            summary: "Based on \(profile.scanCount) products scanned this week, here's how your choices align with your \(profile.healthFocus.displayName) goals.",
            highlights: highlights,
            topGaps: Array(profile.gaps.prefix(3)),
            recommendedActions: actions,
            generatedAt: Date()
        )
    }

    private func generateActionForGap(_ gap: NutritionGap) -> (String, String) {
        switch gap.nutrient {
        case .protein:
            return gap.isDeficiency
                ? ("Look for products with 10g+ protein", "Higher protein helps with satiety and muscle maintenance")
                : ("Balance protein with other nutrients", "Consider variety in your protein sources")

        case .fiber:
            return gap.isDeficiency
                ? ("Choose whole grain and high-fiber options", "Fiber supports digestive health and keeps you feeling full")
                : ("Increase fiber gradually", "Too much fiber too fast can cause digestive discomfort")

        case .sugar:
            return ("Check sugar content on nutrition labels", "Many products have hidden added sugars")

        case .sodium:
            return ("Compare sodium levels between brands", "Lower sodium options are often available")

        case .calories:
            return ("Look for lower-calorie alternatives", "Small swaps can add up over time")

        case .saturatedFat:
            return ("Choose products with healthier fat profiles", "Unsaturated fats are better for heart health")

        case .carbohydrates:
            return ("Focus on complex carbs over simple ones", "Whole grains provide sustained energy")
        }
    }
}

// MARK: - AI Response Models

private struct AIInsightResponse: Codable {
    let title: String
    let summary: String
    let highlights: [AIHighlight]
    let recommendations: [AIRecommendation]
}

private struct AIHighlight: Codable {
    let type: String
    let message: String
    let value: String?
}

private struct AIRecommendation: Codable {
    let priority: Int?
    let action: String
    let rationale: String
    let nutrient: String?
}
