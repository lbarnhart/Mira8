import Foundation

/// Fast regex-based pre-filter for dietary restriction checks.
/// Handles obvious cases quickly and identifies when AI analysis is needed.
struct DietaryQuickChecker {

    /// Result of a quick check
    enum QuickCheckResult {
        case definiteViolation([DietaryViolation])  // Clear violation, no AI needed
        case definitePass                            // Clearly passes, no AI needed
        case needsAIAnalysis([DietaryWarning])       // Ambiguous, needs AI review
        case missingData                             // No ingredients to check
    }

    /// Perform a quick check for a specific restriction
    static func quickCheck(
        restriction: DietaryRestriction,
        ingredients: [String],
        rawIngredientsText: String?
    ) -> QuickCheckResult {
        // Combine ingredients for analysis
        let ingredientsText: String
        if let raw = rawIngredientsText, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ingredientsText = raw
        } else if !ingredients.isEmpty {
            ingredientsText = ingredients.joined(separator: ", ")
        } else {
            return .missingData
        }

        let normalized = normalize(ingredientsText)
        let original = ingredientsText.lowercased()

        // Check for cross-contamination warnings first
        let crossContaminationWarnings = checkCrossContamination(
            restriction: restriction,
            original: original
        )

        // Check for direct violations
        let violations = checkDirectViolations(
            restriction: restriction,
            normalized: normalized
        )

        // Check for derivative ingredients
        let derivativeViolations = checkDerivatives(
            restriction: restriction,
            normalized: normalized
        )

        let allViolations = violations + derivativeViolations

        // If we have definite violations, return them
        if !allViolations.isEmpty {
            return .definiteViolation(allViolations)
        }

        // Check for ambiguous ingredients that need AI
        let ambiguousWarnings = checkAmbiguousIngredients(
            restriction: restriction,
            normalized: normalized
        )

        let allWarnings = crossContaminationWarnings + ambiguousWarnings

        // If we have warnings or cross-contamination, might need AI
        if !allWarnings.isEmpty {
            return .needsAIAnalysis(allWarnings)
        }

        // No issues found
        return .definitePass
    }

    // MARK: - Private Helpers

    private static func normalize(_ text: String) -> String {
        text.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func containsWord(_ text: String, word: String) -> Bool {
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
        return text.range(of: pattern, options: .regularExpression) != nil
    }

    // MARK: - Direct Violation Checks

    private static func checkDirectViolations(
        restriction: DietaryRestriction,
        normalized: String
    ) -> [DietaryViolation] {
        let keywords = directKeywords(for: restriction)
        var violations: [DietaryViolation] = []

        for keyword in keywords {
            if containsWord(normalized, word: keyword) {
                violations.append(DietaryViolation(
                    ingredient: keyword.capitalized,
                    violationType: .directMatch,
                    isDerivative: false,
                    derivedFrom: nil,
                    aiExplanation: nil
                ))
            }
        }

        return violations
    }

    private static func directKeywords(for restriction: DietaryRestriction) -> [String] {
        switch restriction {
        case .vegan:
            return [
                "milk", "cream", "butter", "cheese", "yogurt", "whey",
                "egg", "eggs", "honey", "gelatin", "lard", "tallow",
                "beef", "chicken", "pork", "fish", "salmon", "tuna",
                "anchovy", "anchovies", "bacon", "ham", "meat"
            ]

        case .vegetarian:
            return [
                "beef", "chicken", "pork", "turkey", "lamb", "veal",
                "fish", "salmon", "tuna", "cod", "tilapia", "shrimp",
                "anchovy", "anchovies", "bacon", "ham", "meat",
                "gelatin", "lard", "tallow", "pepperoni", "sausage",
                "chorizo", "prosciutto", "seafood", "crab", "lobster"
            ]

        case .glutenFree:
            return [
                "wheat", "barley", "rye", "malt", "triticale",
                "semolina", "durum", "spelt", "farina", "farro",
                "bulgur", "couscous", "seitan"
            ]

        case .dairyFree:
            return [
                "milk", "cream", "butter", "cheese", "yogurt",
                "whey", "lactose", "ghee", "curds", "kefir",
                "buttermilk", "half and half", "sour cream"
            ]

        case .nutFree:
            return [
                "peanut", "peanuts", "almond", "almonds", "cashew", "cashews",
                "walnut", "walnuts", "pecan", "pecans", "hazelnut", "hazelnuts",
                "pistachio", "pistachios", "macadamia", "macadamias",
                "pine nut", "pine nuts", "brazil nut", "brazil nuts",
                "chestnut", "chestnuts", "praline", "marzipan", "nougat"
            ]

        case .lowSodium, .sugarFree:
            // These restrictions require nutritional data analysis, not ingredient keywords
            return []
        }
    }

    // MARK: - Derivative Checks

    private static func checkDerivatives(
        restriction: DietaryRestriction,
        normalized: String
    ) -> [DietaryViolation] {
        let derivatives = derivativeKeywords(for: restriction)
        var violations: [DietaryViolation] = []

        for (derivative, source) in derivatives {
            if containsWord(normalized, word: derivative) {
                violations.append(DietaryViolation(
                    ingredient: derivative.capitalized,
                    violationType: .derivativeMatch,
                    isDerivative: true,
                    derivedFrom: source,
                    aiExplanation: nil
                ))
            }
        }

        return violations
    }

    private static func derivativeKeywords(for restriction: DietaryRestriction) -> [(derivative: String, source: String)] {
        switch restriction {
        case .vegan:
            return [
                ("casein", "milk"),
                ("caseinate", "milk"),
                ("sodium caseinate", "milk"),
                ("calcium caseinate", "milk"),
                ("lactalbumin", "milk"),
                ("lactoglobulin", "milk"),
                ("albumin", "eggs"),
                ("lysozyme", "eggs"),
                ("mayonnaise", "eggs"),
                ("meringue", "eggs"),
                ("carmine", "insects"),
                ("cochineal", "insects"),
                ("shellac", "insects"),
                ("confectioners glaze", "insects"),
                ("isinglass", "fish"),
                ("l cysteine", "animal sources"),
                ("lanolin", "sheep wool"),
                ("royal jelly", "bees"),
                ("bee pollen", "bees"),
                ("propolis", "bees")
            ]

        case .vegetarian:
            return [
                ("rennet", "animal stomach"),
                ("isinglass", "fish bladder"),
                ("carmine", "insects"),
                ("cochineal", "insects"),
                ("l cysteine", "animal sources")
            ]

        case .glutenFree:
            return [
                ("modified food starch", "wheat (possibly)"),
                ("maltodextrin", "wheat (possibly)"),
                ("dextrin", "wheat (possibly)"),
                ("hydrolyzed vegetable protein", "wheat (possibly)"),
                ("textured vegetable protein", "wheat (possibly)")
            ]

        case .dairyFree:
            return [
                ("casein", "milk"),
                ("caseinate", "milk"),
                ("sodium caseinate", "milk"),
                ("calcium caseinate", "milk"),
                ("lactalbumin", "milk"),
                ("lactoglobulin", "milk"),
                ("lactulose", "milk"),
                ("recaldent", "milk"),
                ("tagatose", "milk (possibly)")
            ]

        case .nutFree:
            return [
                ("arachis oil", "peanuts"),
                ("groundnut", "peanuts"),
                ("groundnuts", "peanuts"),
                ("mandelonas", "peanuts"),
                ("nut butter", "various nuts"),
                ("nut oil", "various nuts"),
                ("nut paste", "various nuts"),
                ("gianduja", "hazelnuts"),
                ("nutella", "hazelnuts")
            ]

        case .lowSodium, .sugarFree:
            // These restrictions require nutritional data analysis, not ingredient derivatives
            return []
        }
    }

    // MARK: - Cross-Contamination Checks

    private static func checkCrossContamination(
        restriction: DietaryRestriction,
        original: String
    ) -> [DietaryWarning] {
        var warnings: [DietaryWarning] = []

        let allergenTerms = allergenTermsFor(restriction)

        // Check for "may contain" warnings
        for term in allergenTerms {
            let mayContainPatterns = [
                "may contain \\w*\\s*\(term)",
                "may contain traces of \\w*\\s*\(term)",
                "may contain \\w*\\s*\(term)s?"
            ]

            for pattern in mayContainPatterns {
                if original.range(of: pattern, options: .regularExpression) != nil {
                    warnings.append(DietaryWarning(
                        warningType: .crossContamination,
                        detail: term.capitalized,
                        aiExplanation: nil
                    ))
                    break
                }
            }
        }

        // Check for facility warnings
        let facilityPatterns = [
            "processed in a facility that (also )?processes \(allergenTerms.joined(separator: "|"))",
            "manufactured in a facility that (also )?handles \(allergenTerms.joined(separator: "|"))",
            "made on equipment that (also )?processes \(allergenTerms.joined(separator: "|"))",
            "produced in a facility with \(allergenTerms.joined(separator: "|"))"
        ]

        for pattern in facilityPatterns {
            if original.range(of: pattern, options: .regularExpression) != nil {
                warnings.append(DietaryWarning(
                    warningType: .processingFacility,
                    detail: restriction.displayName + " allergens",
                    aiExplanation: nil
                ))
                break
            }
        }

        return warnings
    }

    private static func allergenTermsFor(_ restriction: DietaryRestriction) -> [String] {
        switch restriction {
        case .vegan, .vegetarian:
            return ["milk", "egg", "dairy", "meat", "fish", "animal"]
        case .glutenFree:
            return ["wheat", "gluten", "barley", "rye"]
        case .dairyFree:
            return ["milk", "dairy", "lactose", "cream", "cheese"]
        case .nutFree:
            return ["nut", "nuts", "peanut", "peanuts", "tree nut", "tree nuts", "almond", "cashew", "walnut"]
        case .lowSodium, .sugarFree:
            return []
        }
    }

    // MARK: - Ambiguous Ingredient Checks

    private static func checkAmbiguousIngredients(
        restriction: DietaryRestriction,
        normalized: String
    ) -> [DietaryWarning] {
        let ambiguous = ambiguousIngredients(for: restriction)
        var warnings: [DietaryWarning] = []

        for (ingredient, note) in ambiguous {
            if containsWord(normalized, word: ingredient) {
                warnings.append(DietaryWarning(
                    warningType: .ambiguousIngredient,
                    detail: "\(ingredient.capitalized) (\(note))",
                    aiExplanation: nil
                ))
            }
        }

        return warnings
    }

    private static func ambiguousIngredients(for restriction: DietaryRestriction) -> [(ingredient: String, note: String)] {
        switch restriction {
        case .vegan:
            return [
                ("natural flavors", "may be animal-derived"),
                ("natural flavor", "may be animal-derived"),
                ("natural flavoring", "may be animal-derived"),
                ("vitamin d3", "often from lanolin"),
                ("vitamin d", "may be from animal sources"),
                ("mono and diglycerides", "may be animal-derived"),
                ("glycerin", "may be animal-derived"),
                ("glycerine", "may be animal-derived"),
                ("stearic acid", "may be animal-derived"),
                ("lecithin", "may be from eggs"),
                ("l cysteine", "often from animal sources"),
                ("omega 3", "often from fish")
            ]

        case .vegetarian:
            return [
                ("natural flavors", "may contain meat derivatives"),
                ("natural flavor", "may contain meat derivatives"),
                ("enzyme", "may be animal-derived"),
                ("enzymes", "may be animal-derived"),
                ("lipase", "often animal-derived"),
                ("rennet", "may be animal-derived")
            ]

        case .glutenFree:
            return [
                ("natural flavors", "may contain gluten"),
                ("natural flavor", "may contain gluten"),
                ("modified starch", "may be from wheat"),
                ("starch", "may be from wheat"),
                ("maltodextrin", "may be from wheat"),
                ("dextrin", "may be from wheat"),
                ("caramel color", "may contain gluten"),
                ("flour", "type unspecified"),
                ("hydrolyzed protein", "may contain gluten")
            ]

        case .dairyFree:
            return [
                ("natural flavors", "may contain dairy"),
                ("natural flavor", "may contain dairy"),
                ("lactic acid", "usually vegan but check"),
                ("lactate", "usually vegan but check")
            ]

        case .nutFree:
            return [
                ("natural flavors", "may contain nut derivatives"),
                ("natural flavor", "may contain nut derivatives"),
                ("hydrolyzed plant protein", "may include nuts"),
                ("vegetable oil", "may include nut oils")
            ]

        case .lowSodium, .sugarFree:
            // These restrictions require nutritional data analysis, not ingredient analysis
            return []
        }
    }
}

// MARK: - Batch Checking

extension DietaryQuickChecker {
    /// Check multiple restrictions at once
    static func quickCheckAll(
        restrictions: Set<String>,
        ingredients: [String],
        rawIngredientsText: String?
    ) -> [DietaryRestriction: QuickCheckResult] {
        var results: [DietaryRestriction: QuickCheckResult] = [:]

        for restrictionString in restrictions {
            guard let restriction = DietaryRestriction(from: restrictionString) else {
                continue
            }

            results[restriction] = quickCheck(
                restriction: restriction,
                ingredients: ingredients,
                rawIngredientsText: rawIngredientsText
            )
        }

        return results
    }

    /// Convert quick check results to DietaryAnalysisResults
    static func convertToAnalysisResults(
        quickResults: [DietaryRestriction: QuickCheckResult]
    ) -> [DietaryAnalysisResult] {
        quickResults.map { restriction, result in
            switch result {
            case .definiteViolation(let violations):
                return .violation(
                    restriction: restriction,
                    violations: violations,
                    confidence: .high,
                    method: .regexOnly
                )

            case .definitePass:
                return .compliant(
                    restriction: restriction,
                    confidence: .high,
                    method: .regexOnly
                )

            case .needsAIAnalysis(let warnings):
                return .uncertain(
                    restriction: restriction,
                    warnings: warnings,
                    confidence: .low,
                    method: .regexOnly
                )

            case .missingData:
                return .uncertain(
                    restriction: restriction,
                    warnings: [DietaryWarning(
                        warningType: .missingData,
                        detail: "Ingredient list not available",
                        aiExplanation: nil
                    )],
                    confidence: .low,
                    method: .regexOnly
                )
            }
        }
    }
}
