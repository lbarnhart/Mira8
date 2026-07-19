import Foundation

/// AI-powered dietary restriction analysis service.
/// Uses Claude Sonnet for safety-critical analysis of ambiguous ingredients.
actor DietaryAIService {
    static let shared = DietaryAIService()

    private let claudeService = ClaudeService.shared
    private let quickChecker = DietaryQuickChecker.self

    /// Analyze a product for dietary restriction compliance.
    /// Uses a two-tier approach: fast regex check first, AI only for ambiguous cases.
    /// - Parameters:
    ///   - product: The product to analyze
    ///   - restrictions: User's dietary restrictions
    /// - Returns: Array of analysis results for each restriction
    func analyzeProduct(
        _ product: ProductModel,
        restrictions: Set<String>
    ) async throws -> [DietaryAnalysisResult] {
        // Convert restriction strings to enum types
        let activeRestrictions = restrictions.compactMap { DietaryRestriction(from: $0) }

        guard !activeRestrictions.isEmpty else {
            return []
        }

        // First pass: Quick regex check
        let quickResults = quickChecker.quickCheckAll(
            restrictions: restrictions,
            ingredients: product.ingredients,
            rawIngredientsText: product.rawIngredientsText
        )

        // Separate definite results from those needing AI
        var finalResults: [DietaryAnalysisResult] = []
        var restrictionsNeedingAI: [(DietaryRestriction, [DietaryWarning])] = []

        for (restriction, result) in quickResults {
            switch result {
            case .definiteViolation(let violations):
                finalResults.append(.violation(
                    restriction: restriction,
                    violations: violations,
                    confidence: .high,
                    method: .regexOnly
                ))

            case .definitePass:
                finalResults.append(.compliant(
                    restriction: restriction,
                    confidence: .high,
                    method: .regexOnly
                ))

            case .needsAIAnalysis(let warnings):
                restrictionsNeedingAI.append((restriction, warnings))

            case .missingData:
                finalResults.append(.uncertain(
                    restriction: restriction,
                    warnings: [DietaryWarning(
                        warningType: .missingData,
                        detail: "Ingredient list not available",
                        aiExplanation: nil
                    )],
                    confidence: .low,
                    method: .regexOnly
                ))
            }
        }

        // If no AI needed or AI not available, return quick results
        guard !restrictionsNeedingAI.isEmpty else {
            return finalResults
        }

        let isAIAvailable = await claudeService.isConfigured
        guard isAIAvailable else {
            // Fall back to uncertain results with regex warnings
            for (restriction, warnings) in restrictionsNeedingAI {
                finalResults.append(.uncertain(
                    restriction: restriction,
                    warnings: warnings,
                    confidence: .low,
                    method: .fallback
                ))
            }
            return finalResults
        }

        // Second pass: AI analysis for ambiguous cases
        let aiResults = await analyzeWithAI(
            product: product,
            restrictions: restrictionsNeedingAI.map { $0.0 },
            existingWarnings: Dictionary(uniqueKeysWithValues: restrictionsNeedingAI)
        )

        finalResults.append(contentsOf: aiResults)

        return finalResults
    }

    // MARK: - AI Analysis

    private func analyzeWithAI(
        product: ProductModel,
        restrictions: [DietaryRestriction],
        existingWarnings: [DietaryRestriction: [DietaryWarning]]
    ) async -> [DietaryAnalysisResult] {
        let ingredientsText = product.rawIngredientsText ?? product.ingredients.joined(separator: ", ")
        let restrictionNames = restrictions.map { $0.displayName }.joined(separator: ", ")

        let productKey = product.barcode.isEmpty ? product.name.hash.description : product.barcode
        let cacheKey = "dietary_\(productKey)_\(restrictionNames.hash)"

        let systemPrompt = """
        You are a food safety expert for the Mira health app. Your role is to analyze \
        ingredient lists for dietary restriction compliance.

        CRITICAL: This is a safety-critical task. When in doubt, err on the side of caution.

        Guidelines:
        - Identify hidden animal-derived ingredients (casein=dairy, albumin=eggs, carmine=insects)
        - Recognize derivatives and byproducts
        - Note cross-contamination risks from "may contain" or facility warnings
        - Consider regional variations in ingredient naming
        - If an ingredient's source is truly ambiguous, mark as uncertain
        - Be conservative: if there's reasonable doubt, flag it

        Response format (JSON only, no markdown code blocks):
        {
            "analyses": [
                {
                    "restriction": "Vegan",
                    "status": "compliant" | "violation" | "uncertain" | "mayContain",
                    "confidence": 0.0-1.0,
                    "violations": [
                        {
                            "ingredient": "Casein",
                            "isDerivative": true,
                            "derivedFrom": "milk",
                            "explanation": "Casein is a milk protein"
                        }
                    ],
                    "warnings": [
                        {
                            "type": "crossContamination" | "ambiguousIngredient" | "processingFacility",
                            "detail": "Natural flavors - source uncertain",
                            "explanation": "Natural flavors can be derived from animal or plant sources"
                        }
                    ],
                    "reasoning": "Brief explanation of the analysis"
                }
            ]
        }
        """

        let userPrompt = """
        Analyze this product for the following dietary restrictions: \(restrictionNames)

        Product: \(product.name)
        Brand: \(product.brand ?? "Unknown")
        Category: \(product.category ?? "Unknown")

        Ingredients:
        \(ingredientsText)

        Focus on identifying:
        1. Hidden derivatives of restricted ingredients
        2. Cross-contamination warnings
        3. Ambiguous ingredients that could be from restricted sources
        4. Regional/alternative names for restricted ingredients

        Provide your analysis in the specified JSON format.
        """

        do {
            let response: AIAnalysisResponse = try await claudeService.completeJSON(
                prompt: userPrompt,
                systemPrompt: systemPrompt,
                model: .sonnet, // Use Sonnet for safety-critical analysis
                cacheKey: cacheKey
            )

            return convertAIResponse(response, restrictions: restrictions, existingWarnings: existingWarnings)
        } catch {
            AppLog.error("Dietary AI analysis failed: \(error)", category: .network)

            // Return uncertain results with existing warnings on failure
            return restrictions.map { restriction in
                .uncertain(
                    restriction: restriction,
                    warnings: existingWarnings[restriction] ?? [],
                    confidence: .low,
                    method: .fallback
                )
            }
        }
    }

    private func convertAIResponse(
        _ response: AIAnalysisResponse,
        restrictions: [DietaryRestriction],
        existingWarnings: [DietaryRestriction: [DietaryWarning]]
    ) -> [DietaryAnalysisResult] {
        var results: [DietaryAnalysisResult] = []

        for restriction in restrictions {
            if let analysis = response.analyses.first(where: {
                $0.restriction.lowercased() == restriction.displayName.lowercased()
            }) {
                let status = DietaryStatus(rawValue: analysis.status) ?? .uncertain

                let violations = analysis.violations.map { v in
                    DietaryViolation(
                        ingredient: v.ingredient,
                        violationType: v.isDerivative ? .derivativeMatch : .aiDetected,
                        isDerivative: v.isDerivative,
                        derivedFrom: v.derivedFrom,
                        aiExplanation: v.explanation
                    )
                }

                let aiWarnings = analysis.warnings.map { w in
                    DietaryWarning(
                        warningType: DietaryWarning.WarningType(rawValue: w.type) ?? .ambiguousIngredient,
                        detail: w.detail,
                        aiExplanation: w.explanation
                    )
                }

                // Combine AI warnings with regex warnings
                let combinedWarnings = (existingWarnings[restriction] ?? []) + aiWarnings

                let confidence: ConfidenceLevel
                if analysis.confidence >= 0.8 {
                    confidence = .high
                } else if analysis.confidence >= 0.5 {
                    confidence = .medium
                } else {
                    confidence = .low
                }

                results.append(DietaryAnalysisResult(
                    restriction: restriction,
                    status: status,
                    confidence: confidence,
                    violations: violations,
                    warnings: combinedWarnings,
                    analysisMethod: .aiEnhanced
                ))
            } else {
                // AI didn't return analysis for this restriction, use fallback
                results.append(.uncertain(
                    restriction: restriction,
                    warnings: existingWarnings[restriction] ?? [],
                    confidence: .low,
                    method: .fallback
                ))
            }
        }

        return results
    }

    // MARK: - Check Availability

    var isAvailable: Bool {
        get async {
            await claudeService.isConfigured
        }
    }
}

// MARK: - AI Response Models

private struct AIAnalysisResponse: Codable {
    let analyses: [AIRestrictionAnalysis]
}

private struct AIRestrictionAnalysis: Codable {
    let restriction: String
    let status: String
    let confidence: Double
    let violations: [AIViolation]
    let warnings: [AIWarning]
    let reasoning: String?
}

private struct AIViolation: Codable {
    let ingredient: String
    let isDerivative: Bool
    let derivedFrom: String?
    let explanation: String?
}

private struct AIWarning: Codable {
    let type: String
    let detail: String
    let explanation: String?
}
