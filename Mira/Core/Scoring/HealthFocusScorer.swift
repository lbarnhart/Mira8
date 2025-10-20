import Foundation

/// Enhanced result type for component scoring with detailed breakdown
struct ComponentScoringResult {
    let score: Double
    let explanation: String
    let recommendations: [String]
    let adjustments: [ScoreAdjustment]
    let keyFactors: [String]
}

final class HealthFocusScorer {
    private let config: ScoringConfiguration

    init(config: ScoringConfiguration) {
        self.config = config
    }

    func calculateScore(
        for product: ProductModel,
        focus: HealthFocus,
        dietaryRestrictions: [DietaryRestriction]
    ) -> HealthScore {
        let weights = config.healthFocusWeights[focus.rawValue] ?? ComponentWeights(
            macronutrientBalance: 0.25,
            micronutrientDensity: 0.2,
            processingLevel: 0.2,
            ingredientQuality: 0.2,
            additives: 0.15
        )

        return calculateScoreWithWeights(
            product: product,
            focus: focus,
            dietaryRestrictions: dietaryRestrictions,
            weights: weights
        )
    }

    private func calculateScoreWithWeights(
        product: ProductModel,
        focus: HealthFocus,
        dietaryRestrictions: [DietaryRestriction],
        weights: ComponentWeights
    ) -> HealthScore {

        // Calculate all component scores with detailed results
        let macroResult = calculateMacronutrientScore(product, focus: focus)
        let microResult = calculateMicronutrientScore(product.nutrition, ingredients: product.ingredients)
        let processingResult = calculateProcessingScore(product.processingLevel)
        let ingredientResult = calculateIngredientQualityScore(product.ingredients)
        let additiveResult = calculateAdditiveScore(product.additives)

        // Detect data completeness and adjust weights if needed
        let completeness = assessDataCompleteness(product: product)
        let adjustedWeights = adjustWeightsForCompleteness(
            weights: weights,
            completeness: completeness
        )

        // Build component scores
        let components = ScoreComponents(
            macronutrientBalance: ComponentScore(
                score: macroResult.score,
                weight: adjustedWeights.macronutrientBalance,
                explanation: macroResult.explanation,
                recommendations: macroResult.recommendations
            ),
            micronutrientDensity: ComponentScore(
                score: microResult.score,
                weight: adjustedWeights.micronutrientDensity,
                explanation: microResult.explanation,
                recommendations: microResult.recommendations
            ),
            processingLevel: ComponentScore(
                score: processingResult.score,
                weight: adjustedWeights.processingLevel,
                explanation: processingResult.explanation,
                recommendations: processingResult.recommendations
            ),
            ingredientQuality: ComponentScore(
                score: ingredientResult.score,
                weight: adjustedWeights.ingredientQuality,
                explanation: ingredientResult.explanation,
                recommendations: ingredientResult.recommendations
            ),
            additives: ComponentScore(
                score: additiveResult.score,
                weight: adjustedWeights.additives,
                explanation: additiveResult.explanation,
                recommendations: additiveResult.recommendations
            )
        )

        // Create detailed breakdown
        let breakdown = createBreakdown(
            macroResult: macroResult,
            microResult: microResult,
            processingResult: processingResult,
            ingredientResult: ingredientResult,
            additiveResult: additiveResult,
            weights: adjustedWeights
        )

        // Collect all adjustments
        let allAdjustments = macroResult.adjustments +
            microResult.adjustments +
            processingResult.adjustments +
            ingredientResult.adjustments +
            additiveResult.adjustments

        let overallScore = calculateOverallScore(components: components)
        AppLog.debug("Scoring components -> macro: \(Int(components.macronutrientBalance.score)), micro: \(Int(components.micronutrientDensity.score)), processing: \(Int(components.processingLevel.score)), ingredients: \(Int(components.ingredientQuality.score)), additives: \(Int(components.additives.score)) | overall: \(Int(overallScore))", category: .scoring)

        let explanation = generateExplanation(
            components: components,
            focus: focus,
            overallScore: overallScore,
            breakdown: breakdown,
            confidence: completeness.confidence
        )

        return HealthScore(
            overall: overallScore,
            components: components,
            explanation: explanation,
            focus: focus,
            breakdown: breakdown,
            adjustments: allAdjustments,
            confidence: completeness.confidence,
            confidenceWarning: completeness.warning
        )
    }

    // MARK: - Macronutrient Scoring

    private func calculateMacronutrientScore(_ product: ProductModel, focus: HealthFocus) -> ComponentScoringResult {
        let thresholds = config.macronutrientThresholds
        let nutrition = product.nutrition

        let proteinScore = thresholds.protein.getScore(for: nutrition.protein)
        let fiberScore = thresholds.fiber.getScore(for: nutrition.fiber)
        let sugarScore = thresholds.sugar.getScore(for: nutrition.sugar, isLowerBetter: true)
        let sodiumScore = thresholds.sodium.getScore(for: nutrition.sodium, isLowerBetter: true)
        let saturatedFatScore = thresholds.saturatedFat.getScore(for: nutrition.fat, isLowerBetter: true)
        let cholesterolMg = nutrition.cholesterol * 1000

        var weightedScore: Double
        var explanation: String
        var recommendations: [String] = []
        var adjustments: [ScoreAdjustment] = []
        var keyFactors: [String] = []

        switch focus {
        case .proteinFocus:
            weightedScore = (proteinScore * 0.5) + (fiberScore * 0.2) + (sugarScore * 0.15) + (sodiumScore * 0.15)
            explanation = NutritionGuidelines.Protein.getProteinExplanation(grams: nutrition.protein)
            keyFactors.append("Protein: \(nutrition.protein.formatted(.number.precision(.fractionLength(0...1))))g")
            keyFactors.append("Fiber: \(nutrition.fiber.formatted(.number.precision(.fractionLength(0...1))))g")

            if proteinScore < 80 {
                recommendations.append("Look for products with higher protein content (≥10g per serving)")
            }

        case .weightLoss:
            weightedScore = (fiberScore * 0.3) + (sugarScore * 0.3) + (proteinScore * 0.25) + (sodiumScore * 0.15)
            explanation = "\(NutritionGuidelines.Fiber.getFiberExplanation(grams: nutrition.fiber)) \(NutritionGuidelines.Sugar.getSugarExplanation(grams: nutrition.sugar))"
            keyFactors.append("Fiber: \(nutrition.fiber.formatted(.number.precision(.fractionLength(0...1))))g")
            keyFactors.append("Sugar: \(nutrition.sugar.formatted(.number.precision(.fractionLength(0...1))))g")

            if fiberScore < 80 {
                recommendations.append("Choose products with more fiber (≥3g per serving)")
            }
            if sugarScore < 80 {
                recommendations.append("Avoid products high in added sugars")
            }

        case .gutHealth:
            var adjustedFiberScore = fiberScore

            if nutrition.fiber == 0 && nutrition.sugar <= 1.0 && nutrition.calories <= 50 {
                adjustedFiberScore = max(fiberScore, 60)
                if fiberScore < 60 {
                    adjustments.append(ScoreAdjustment(
                        label: "Low-Calorie Beverage Exception",
                        delta: adjustedFiberScore - fiberScore,
                        reason: "Zero-fiber clean beverage (≤1g sugar, ≤50 cal) receives reduced fiber penalty"
                    ))
                }
            }

            weightedScore = (adjustedFiberScore * 0.4) + (proteinScore * 0.2) + (sugarScore * 0.2) + (sodiumScore * 0.2)
            explanation = NutritionGuidelines.Fiber.getFiberExplanation(grams: nutrition.fiber)
            keyFactors.append("Fiber: \(nutrition.fiber.formatted(.number.precision(.fractionLength(0...1))))g (key for gut health)")

            if adjustedFiberScore < 80 && !(nutrition.fiber == 0 && nutrition.sugar <= 1.0 && nutrition.calories <= 50) {
                recommendations.append("Prioritize high-fiber foods for gut health")
            }

        case .generalWellness:
            weightedScore = (proteinScore + fiberScore + sugarScore + sodiumScore) / 4
            explanation = "Balanced nutritional profile analysis"
            keyFactors.append("Protein: \(nutrition.protein.formatted(.number.precision(.fractionLength(0...1))))g")
            keyFactors.append("Fiber: \(nutrition.fiber.formatted(.number.precision(.fractionLength(0...1))))g")
            keyFactors.append("Sugar: \(nutrition.sugar.formatted(.number.precision(.fractionLength(0...1))))g")

            if proteinScore < 80 {
                recommendations.append("Consider higher protein options")
            }
            if fiberScore < 80 {
                recommendations.append("Look for more fiber-rich alternatives")
            }

        case .heartHealth:
            weightedScore = (fiberScore * 0.35) +
                (sodiumScore * 0.2) +
                (sugarScore * 0.15) +
                (proteinScore * 0.15) +
                (saturatedFatScore * 0.15)

            // Heart-health specific adjustments with explicit reasoning
            let cholesterolAdjustment = applyCholesterolAdjustment(cholesterolMg: cholesterolMg)
            adjustments.append(contentsOf: cholesterolAdjustment.adjustments)
            weightedScore += cholesterolAdjustment.totalDelta

            keyFactors.append("Cholesterol: \(Int(cholesterolMg))mg")
            keyFactors.append("Sodium: \(Int(nutrition.sodium * 1000))mg")
            keyFactors.append("Fiber: \(nutrition.fiber.formatted(.number.precision(.fractionLength(0...1))))g")

            recommendations.append(contentsOf: cholesterolAdjustment.recommendations)

            if saturatedFatScore < 80 {
                let message = "Reduce saturated fat to support cardiovascular health"
                if !recommendations.contains(message) { recommendations.append(message) }
            }

            if fiberScore < 80 {
                let message = "Aim for at least 3g of fiber for heart health"
                if !recommendations.contains(message) { recommendations.append(message) }
            }

            // Check for heart-friendly ingredients
            let heartFriendlyCheck = checkHeartFriendlyIngredients(product.ingredients)
            if heartFriendlyCheck.hasHeartFriendly {
                adjustments.append(ScoreAdjustment(
                    label: "Heart-Friendly Ingredients",
                    delta: NutritionGuidelines.Adjustments.heartFriendlyBonus,
                    reason: NutritionGuidelines.HeartHealth.heartFriendlyGuideline
                ))
                weightedScore += NutritionGuidelines.Adjustments.heartFriendlyBonus
                keyFactors.append("Contains heart-friendly ingredients: \(heartFriendlyCheck.ingredients.joined(separator: ", "))")
            }

            explanation = "Heart health analysis: \(NutritionGuidelines.HeartHealth.getCholesterolExplanation(milligrams: cholesterolMg)). \(NutritionGuidelines.HeartHealth.getSodiumExplanation(grams: nutrition.sodium))"
        }

        let finalScore = max(0, min(100, weightedScore))
        return ComponentScoringResult(
            score: finalScore,
            explanation: explanation,
            recommendations: recommendations,
            adjustments: adjustments,
            keyFactors: keyFactors
        )
    }

    private func applyCholesterolAdjustment(cholesterolMg: Double) -> (totalDelta: Double, adjustments: [ScoreAdjustment], recommendations: [String]) {
        var delta: Double = 0
        var adjustments: [ScoreAdjustment] = []
        var recommendations: [String] = []

        if cholesterolMg > NutritionGuidelines.HeartHealth.cholesterolModerate {
            delta = NutritionGuidelines.Adjustments.cholesterolHighPenalty
            adjustments.append(ScoreAdjustment(
                label: "High Cholesterol Penalty",
                delta: delta,
                reason: "Cholesterol \(Int(cholesterolMg))mg exceeds 100mg threshold; \(NutritionGuidelines.HeartHealth.cholesterolGuideline)"
            ))
            recommendations.append("Choose options with less than 100mg cholesterol per serving")
        } else if cholesterolMg > NutritionGuidelines.HeartHealth.cholesterolGood {
            delta = NutritionGuidelines.Adjustments.cholesterolModeratePenalty
            adjustments.append(ScoreAdjustment(
                label: "Moderate Cholesterol Penalty",
                delta: delta,
                reason: "Cholesterol \(Int(cholesterolMg))mg is moderate (50-100mg); \(NutritionGuidelines.HeartHealth.cholesterolGuideline)"
            ))
            recommendations.append("Limit foods exceeding 50mg cholesterol per serving")
        } else if cholesterolMg > 0 {
            delta = NutritionGuidelines.Adjustments.cholesterolLowBonus
            adjustments.append(ScoreAdjustment(
                label: "Low Cholesterol Bonus",
                delta: delta,
                reason: "Heart-friendly cholesterol amount (\(Int(cholesterolMg))mg <50mg)"
            ))
        } else {
            delta = NutritionGuidelines.Adjustments.cholesterolFreeBonus
            adjustments.append(ScoreAdjustment(
                label: "Cholesterol-Free Bonus",
                delta: delta,
                reason: "No cholesterol detected; excellent for heart health"
            ))
        }

        return (delta, adjustments, recommendations)
    }

    private func checkHeartFriendlyIngredients(_ ingredients: [String]) -> (hasHeartFriendly: Bool, ingredients: [String]) {
        var foundIngredients: [String] = []

        for ingredient in ingredients {
            let lowered = ingredient.lowercased()
            for keyword in NutritionGuidelines.HeartHealth.heartFriendlyIngredients {
                if lowered.contains(keyword) && !foundIngredients.contains(keyword) {
                    foundIngredients.append(keyword)
                }
            }
        }

        return (!foundIngredients.isEmpty, foundIngredients)
    }

    // MARK: - Micronutrient Scoring

    private func calculateMicronutrientScore(_ nutrition: ProductNutrition, ingredients: [String]) -> ComponentScoringResult {
        // Extract all available micronutrients and calculate % DV
        let micronutrients = extractMicronutrients(from: nutrition)

        var explanation: String
        var keyFactors: [String] = []
        var adjustments: [ScoreAdjustment] = []
        var densityScore: Double

        if micronutrients.isEmpty {
            let nonBlank = ingredients.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            var synthesizedMicronutrients: [NutritionGuidelines.MicronutrientInfo] = []

            for ingredient in nonBlank {
                if let profile = MicronutrientProfiles.lookup(ingredient: ingredient) {
                    if let vitaminA = profile.vitaminA, vitaminA > 0 {
                        let percentDV = (vitaminA / NutritionGuidelines.Micronutrients.vitaminADV) * 100
                        synthesizedMicronutrients.append(NutritionGuidelines.MicronutrientInfo(
                            name: "Vitamin A", amount: vitaminA, unit: "mcg", percentDV: percentDV,
                            dailyValue: NutritionGuidelines.Micronutrients.vitaminADV
                        ))
                    }
                    if let vitaminC = profile.vitaminC, vitaminC > 0 {
                        let percentDV = (vitaminC / NutritionGuidelines.Micronutrients.vitaminCDV) * 100
                        synthesizedMicronutrients.append(NutritionGuidelines.MicronutrientInfo(
                            name: "Vitamin C", amount: vitaminC, unit: "mg", percentDV: percentDV,
                            dailyValue: NutritionGuidelines.Micronutrients.vitaminCDV
                        ))
                    }
                    if let vitaminK = profile.vitaminK, vitaminK > 0 {
                        let percentDV = (vitaminK / 120.0) * 100
                        synthesizedMicronutrients.append(NutritionGuidelines.MicronutrientInfo(
                            name: "Vitamin K", amount: vitaminK, unit: "mcg", percentDV: percentDV,
                            dailyValue: 120.0
                        ))
                    }
                    if let folate = profile.folate, folate > 0 {
                        let percentDV = (folate / NutritionGuidelines.Micronutrients.folateDV) * 100
                        synthesizedMicronutrients.append(NutritionGuidelines.MicronutrientInfo(
                            name: "Folate", amount: folate, unit: "mcg", percentDV: percentDV,
                            dailyValue: NutritionGuidelines.Micronutrients.folateDV
                        ))
                    }
                    if let calcium = profile.calcium, calcium > 0 {
                        let percentDV = (calcium / NutritionGuidelines.Micronutrients.calciumDV) * 100
                        synthesizedMicronutrients.append(NutritionGuidelines.MicronutrientInfo(
                            name: "Calcium", amount: calcium, unit: "mg", percentDV: percentDV,
                            dailyValue: NutritionGuidelines.Micronutrients.calciumDV
                        ))
                    }
                    if let iron = profile.iron, iron > 0 {
                        let percentDV = (iron / NutritionGuidelines.Micronutrients.ironDV) * 100
                        synthesizedMicronutrients.append(NutritionGuidelines.MicronutrientInfo(
                            name: "Iron", amount: iron, unit: "mg", percentDV: percentDV,
                            dailyValue: NutritionGuidelines.Micronutrients.ironDV
                        ))
                    }
                    if let magnesium = profile.magnesium, magnesium > 0 {
                        let percentDV = (magnesium / NutritionGuidelines.Micronutrients.magnesiumDV) * 100
                        synthesizedMicronutrients.append(NutritionGuidelines.MicronutrientInfo(
                            name: "Magnesium", amount: magnesium, unit: "mg", percentDV: percentDV,
                            dailyValue: NutritionGuidelines.Micronutrients.magnesiumDV
                        ))
                    }
                    if let potassium = profile.potassium, potassium > 0 {
                        let percentDV = (potassium / NutritionGuidelines.Micronutrients.potassiumDV) * 100
                        synthesizedMicronutrients.append(NutritionGuidelines.MicronutrientInfo(
                            name: "Potassium", amount: potassium, unit: "mg", percentDV: percentDV,
                            dailyValue: NutritionGuidelines.Micronutrients.potassiumDV
                        ))
                    }
                }
            }

            if !synthesizedMicronutrients.isEmpty {
                let avgPercentDV = synthesizedMicronutrients.reduce(0.0) { $0 + $1.percentDV } / Double(synthesizedMicronutrients.count)
                densityScore = min(100, avgPercentDV * 2)

                let topMicronutrients = Array(synthesizedMicronutrients.sorted { $0.percentDV > $1.percentDV }.prefix(4))
                keyFactors = topMicronutrients.map { $0.name }

                let microCount = synthesizedMicronutrients.count
                explanation = "\(microCount) micronutrient\(microCount == 1 ? "" : "s") (est.), avg \(Int(avgPercentDV))% DV"
            } else {
                densityScore = min(100, (nutrition.protein + nutrition.fiber) * 2)

                adjustments.append(ScoreAdjustment(
                    label: "Micronutrient Estimation",
                    delta: 0,
                    reason: "Limited micronutrient data—using fiber/protein proxy for density estimation"
                ))

                keyFactors.append("Limited micronutrient data")
                explanation = "Nutrient density based on protein/fiber. Full data not available."
            }
        } else {
            // Calculate score based on actual micronutrient data
            let avgPercentDV = micronutrients.reduce(0.0) { $0 + $1.percentDV } / Double(micronutrients.count)
            densityScore = min(100, avgPercentDV * 2) // Scale to 0-100

            // Get top 3-4 micronutrients by % DV and list just the names
            let topMicronutrients = Array(micronutrients.sorted { $0.percentDV > $1.percentDV }.prefix(4))
            keyFactors = topMicronutrients.map { $0.name }

            let microCount = micronutrients.count
            explanation = "\(microCount) micronutrient\(microCount == 1 ? "" : "s"), avg \(Int(avgPercentDV))% DV. FDA: ≥20% DV = excellent source."
        }

        let recommendations: [String] = densityScore < 80 ?
            ["Look for fortified products or whole food alternatives with higher micronutrient content"] : []

        return ComponentScoringResult(
            score: densityScore,
            explanation: explanation,
            recommendations: recommendations,
            adjustments: adjustments,
            keyFactors: keyFactors
        )
    }

    /// Extract all available micronutrients from nutrition data and calculate % DV
    private func extractMicronutrients(from nutrition: ProductNutrition) -> [NutritionGuidelines.MicronutrientInfo] {
        var micronutrients: [NutritionGuidelines.MicronutrientInfo] = []

        if let vitaminA = nutrition.vitaminA, vitaminA > 0 {
            let percentDV = (vitaminA / NutritionGuidelines.Micronutrients.vitaminADV) * 100
            micronutrients.append(NutritionGuidelines.MicronutrientInfo(
                name: "Vitamin A", amount: vitaminA, unit: "mcg", percentDV: percentDV,
                dailyValue: NutritionGuidelines.Micronutrients.vitaminADV
            ))
        }

        if let vitaminC = nutrition.vitaminC, vitaminC > 0 {
            let percentDV = (vitaminC / NutritionGuidelines.Micronutrients.vitaminCDV) * 100
            micronutrients.append(NutritionGuidelines.MicronutrientInfo(
                name: "Vitamin C", amount: vitaminC, unit: "mg", percentDV: percentDV,
                dailyValue: NutritionGuidelines.Micronutrients.vitaminCDV
            ))
        }

        if let vitaminD = nutrition.vitaminD, vitaminD > 0 {
            let percentDV = (vitaminD / NutritionGuidelines.Micronutrients.vitaminDDV) * 100
            micronutrients.append(NutritionGuidelines.MicronutrientInfo(
                name: "Vitamin D", amount: vitaminD, unit: "mcg", percentDV: percentDV,
                dailyValue: NutritionGuidelines.Micronutrients.vitaminDDV
            ))
        }

        if let vitaminE = nutrition.vitaminE, vitaminE > 0 {
            let percentDV = (vitaminE / NutritionGuidelines.Micronutrients.vitaminEDV) * 100
            micronutrients.append(NutritionGuidelines.MicronutrientInfo(
                name: "Vitamin E", amount: vitaminE, unit: "mg", percentDV: percentDV,
                dailyValue: NutritionGuidelines.Micronutrients.vitaminEDV
            ))
        }

        if let iron = nutrition.iron, iron > 0 {
            let percentDV = (iron / NutritionGuidelines.Micronutrients.ironDV) * 100
            micronutrients.append(NutritionGuidelines.MicronutrientInfo(
                name: "Iron", amount: iron, unit: "mg", percentDV: percentDV,
                dailyValue: NutritionGuidelines.Micronutrients.ironDV
            ))
        }

        if let calcium = nutrition.calcium, calcium > 0 {
            let percentDV = (calcium / NutritionGuidelines.Micronutrients.calciumDV) * 100
            micronutrients.append(NutritionGuidelines.MicronutrientInfo(
                name: "Calcium", amount: calcium, unit: "mg", percentDV: percentDV,
                dailyValue: NutritionGuidelines.Micronutrients.calciumDV
            ))
        }

        if let magnesium = nutrition.magnesium, magnesium > 0 {
            let percentDV = (magnesium / NutritionGuidelines.Micronutrients.magnesiumDV) * 100
            micronutrients.append(NutritionGuidelines.MicronutrientInfo(
                name: "Magnesium", amount: magnesium, unit: "mg", percentDV: percentDV,
                dailyValue: NutritionGuidelines.Micronutrients.magnesiumDV
            ))
        }

        if let potassium = nutrition.potassium, potassium > 0 {
            let percentDV = (potassium / NutritionGuidelines.Micronutrients.potassiumDV) * 100
            micronutrients.append(NutritionGuidelines.MicronutrientInfo(
                name: "Potassium", amount: potassium, unit: "mg", percentDV: percentDV,
                dailyValue: NutritionGuidelines.Micronutrients.potassiumDV
            ))
        }

        if let zinc = nutrition.zinc, zinc > 0 {
            let percentDV = (zinc / NutritionGuidelines.Micronutrients.zincDV) * 100
            micronutrients.append(NutritionGuidelines.MicronutrientInfo(
                name: "Zinc", amount: zinc, unit: "mg", percentDV: percentDV,
                dailyValue: NutritionGuidelines.Micronutrients.zincDV
            ))
        }

        if let vitaminB12 = nutrition.vitaminB12, vitaminB12 > 0 {
            let percentDV = (vitaminB12 / NutritionGuidelines.Micronutrients.vitaminB12DV) * 100
            micronutrients.append(NutritionGuidelines.MicronutrientInfo(
                name: "Vitamin B12", amount: vitaminB12, unit: "mcg", percentDV: percentDV,
                dailyValue: NutritionGuidelines.Micronutrients.vitaminB12DV
            ))
        }

        if let folate = nutrition.folate, folate > 0 {
            let percentDV = (folate / NutritionGuidelines.Micronutrients.folateDV) * 100
            micronutrients.append(NutritionGuidelines.MicronutrientInfo(
                name: "Folate", amount: folate, unit: "mcg", percentDV: percentDV,
                dailyValue: NutritionGuidelines.Micronutrients.folateDV
            ))
        }

        return micronutrients
    }

    /// Infer likely micronutrients based on protein and fiber content (fallback when no data available)
    private func inferMicronutrients(protein: Double, fiber: Double) -> [String] {
        var micronutrients: [String] = []

        // High protein foods typically contain these micronutrients
        if protein >= 10 {
            micronutrients.append("Iron (estimated)")
            micronutrients.append("Vitamin B12 (estimated)")
            micronutrients.append("Zinc (estimated)")
        } else if protein >= 5 {
            micronutrients.append("Iron (estimated)")
        }

        // High fiber foods typically contain these micronutrients
        if fiber >= 5 {
            micronutrients.append("Magnesium (estimated)")
        }

        // Limit to top 3-4
        let result = Array(micronutrients.prefix(4))

        // If no significant protein or fiber, add general note
        return result.isEmpty ? ["Limited micronutrient data"] : result
    }

    // MARK: - Processing Score

    private func calculateProcessingScore(_ processingLevel: ProcessingLevel) -> ComponentScoringResult {
        let scoreValue = Double(config.processingLevelScores[String(processingLevel.rawValue)] ?? 30)

        // Short, descriptive explanation based on processing level
        let explanation: String
        switch processingLevel {
        case .minimal:
            explanation = "Lightly processed with mostly whole ingredients"
        case .processed:
            explanation = "Moderately processed with added salt, sugar, or oils"
        case .ultraProcessed:
            explanation = "Highly processed with industrial formulations"
        case .unknown:
            explanation = "Processing level could not be determined"
        }

        let recommendations: [String] = scoreValue < 80 ?
            ["Choose less processed alternatives when possible"] : []

        let keyFactors = [processingLevel.displayName]

        return ComponentScoringResult(
            score: scoreValue,
            explanation: explanation,
            recommendations: recommendations,
            adjustments: [],
            keyFactors: keyFactors
        )
    }

    // MARK: - Ingredient Quality Score

    private func calculateIngredientQualityScore(_ ingredients: [String]) -> ComponentScoringResult {
        let totalIngredients = ingredients.count
        var adjustments: [ScoreAdjustment] = []
        var keyFactors: [String] = []

        guard totalIngredients > 0 else {
            adjustments.append(ScoreAdjustment(
                label: "Missing Ingredient Data",
                delta: 0,
                reason: "No ingredient information available—score reliability reduced"
            ))
            return ComponentScoringResult(
                score: 50,
                explanation: "No ingredient information available",
                recommendations: ["Request detailed ingredient list"],
                adjustments: adjustments,
                keyFactors: ["No ingredient data"]
            )
        }

        let nonBlank = ingredients.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if nonBlank.count == 1, let singleIngredient = nonBlank.first {
            let normalized = singleIngredient.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let wholeFoodAllowlist = [
                "spinach", "kale", "lettuce", "arugula", "broccoli", "cauliflower", "carrot",
                "celery", "cucumber", "tomato", "pepper", "onion", "garlic", "potato",
                "sweet potato", "beet", "cabbage", "brussels sprout", "asparagus", "zucchini",
                "apple", "banana", "orange", "strawberry", "blueberry", "raspberry", "blackberry",
                "grape", "peach", "pear", "plum", "cherry", "watermelon", "cantaloupe", "mango",
                "pineapple", "kiwi", "avocado", "lemon", "lime",
                "chicken breast", "chicken thigh", "turkey breast", "beef", "pork", "lamb",
                "salmon", "tuna", "cod", "shrimp", "tilapia", "trout",
                "egg", "eggs",
                "rice", "quinoa", "oat", "barley", "bulgur", "millet",
                "almond", "walnut", "cashew", "pecan", "peanut", "hazelnut",
                "black bean", "kidney bean", "chickpea", "lentil", "pinto bean"
            ]

            for wholeFoodKeyword in wholeFoodAllowlist {
                if normalized.contains(wholeFoodKeyword) {
                    keyFactors.append("Single whole-food ingredient")
                    return ComponentScoringResult(
                        score: 95,
                        explanation: "Single whole-food ingredient",
                        recommendations: [],
                        adjustments: adjustments,
                        keyFactors: keyFactors
                    )
                }
            }
        }

        var beneficialCount = ingredients.filter { ingredient in
            config.beneficialIngredients.contains { beneficial in
                ingredient.lowercased().contains(beneficial.lowercased())
            }
        }.count

        // Detect botanical patterns: organic/soothing botanicals + root/leaf/flower/herb
        let botanicalBonusCount = ingredients.filter { ingredient in
            let lower = ingredient.lowercased()
            let hasBotanicalWord = lower.contains("root") || lower.contains("leaf") ||
                                   lower.contains("flower") || lower.contains("herb")
            if !hasBotanicalWord { return false }

            // Check if organic or known soothing botanical
            let isOrganic = lower.contains("organic")
            let isSoothingBotanical = [
                "chamomile", "valerian", "lavender", "passionflower", "lemon balm",
                "peppermint", "spearmint", "ginger", "turmeric", "echinacea",
                "ashwagandha", "holy basil", "rosemary", "thyme", "sage"
            ].contains { lower.contains($0) }

            return isOrganic || isSoothingBotanical
        }.count

        beneficialCount += botanicalBonusCount

        // Check for specific quality indicators
        let hasOrganic = ingredients.contains { $0.lowercased().contains("organic") }
        let hasArtificialFlavors = ingredients.contains { $0.lowercased().contains("artificial flavor") }
        let hasNaturalFlavors = ingredients.contains { $0.lowercased().contains("natural flavor") }

        let qualityRatio = Double(beneficialCount) / Double(totalIngredients)
        let baseScore = min(100, qualityRatio * 200)

        keyFactors.append("\(totalIngredients) ingredients")
        if hasOrganic {
            keyFactors.append("Organic")
        }
        if hasArtificialFlavors {
            keyFactors.append("Artificial flavors")
        } else if hasNaturalFlavors {
            keyFactors.append("Natural flavors")
        }
        if beneficialCount > 0 {
            keyFactors.append("\(beneficialCount) beneficial")
        }

        var finalScore = baseScore

        // Apply length penalty
        if totalIngredients > NutritionGuidelines.Adjustments.longIngredientListThreshold {
            let penalty = Double(totalIngredients - NutritionGuidelines.Adjustments.longIngredientListThreshold) *
                NutritionGuidelines.Adjustments.longIngredientListPenaltyPerItem
            finalScore -= penalty
            adjustments.append(ScoreAdjustment(
                label: "Long Ingredient List",
                delta: -penalty,
                reason: "Product has \(totalIngredients) ingredients (penalty for >10 ingredients)"
            ))
        }

        finalScore = max(30, finalScore)

        // Generate short, descriptive explanation
        var explanation = "\(totalIngredients) ingredients"
        if hasOrganic {
            explanation += " (organic)"
        }
        if hasArtificialFlavors {
            explanation += ", artificial flavors"
        } else if hasNaturalFlavors {
            explanation += ", natural flavors"
        }
        if beneficialCount >= 3 {
            explanation += ", \(beneficialCount) beneficial"
        }

        let recommendations: [String] = finalScore < 80 ?
            ["Look for products with more whole food ingredients", "Avoid products with long ingredient lists"] : []

        return ComponentScoringResult(
            score: finalScore,
            explanation: explanation,
            recommendations: recommendations,
            adjustments: adjustments,
            keyFactors: keyFactors
        )
    }

    // MARK: - Additive Score

    private func calculateAdditiveScore(_ additives: [String]) -> ComponentScoringResult {
        var adjustments: [ScoreAdjustment] = []
        var keyFactors: [String] = []

        let harmfulCount = additives.filter { additive in
            config.harmfulAdditives.contains { harmful in
                additive.lowercased().contains(harmful.lowercased())
            }
        }.count

        let totalAdditives = additives.count
        var score = totalAdditives == 0 ? 100.0 : 100.0

        // Check for specific additive types
        let hasNaturalFlavors = additives.contains { $0.lowercased().contains("natural flavor") }
        let hasArtificialPreservatives = additives.contains {
            $0.lowercased().contains("sodium benzoate") ||
            $0.lowercased().contains("potassium sorbate") ||
            $0.lowercased().contains("tbhq") ||
            $0.lowercased().contains("bht") ||
            $0.lowercased().contains("bha")
        }
        let hasArtificialColors = additives.contains {
            $0.lowercased().contains("red") ||
            $0.lowercased().contains("blue") ||
            $0.lowercased().contains("yellow") ||
            $0.lowercased().contains("fd&c")
        }

        // Build key factors
        if totalAdditives == 0 {
            keyFactors.append("No additives")
        } else {
            if hasNaturalFlavors {
                keyFactors.append("Natural flavors")
            }
            if hasArtificialPreservatives {
                keyFactors.append("Artificial preservatives")
            }
            if hasArtificialColors {
                keyFactors.append("Artificial colors")
            }
            if harmfulCount > 0 {
                keyFactors.append("\(harmfulCount) concerning")
            }
            if keyFactors.isEmpty {
                keyFactors.append("\(totalAdditives) additives")
            }
        }

        if harmfulCount > 0 {
            let harmfulPenalty = Double(harmfulCount) * NutritionGuidelines.Adjustments.harmfulAdditivePerItemPenalty
            score -= harmfulPenalty
            adjustments.append(ScoreAdjustment(
                label: "Harmful Additives Penalty",
                delta: -harmfulPenalty,
                reason: "Contains \(harmfulCount) concerning additive(s)"
            ))
        }

        if totalAdditives > 0 {
            let totalPenalty = Double(totalAdditives) * NutritionGuidelines.Adjustments.totalAdditivePerItemPenalty
            score -= totalPenalty
            adjustments.append(ScoreAdjustment(
                label: "Total Additives Penalty",
                delta: -totalPenalty,
                reason: "Contains \(totalAdditives) total additive(s)"
            ))
        }

        score = max(30, score)

        // Generate short, descriptive explanation
        var explanation: String
        if totalAdditives == 0 {
            explanation = "No additives or preservatives"
        } else if hasNaturalFlavors && !hasArtificialPreservatives && !hasArtificialColors {
            explanation = "Only natural flavors, no artificial preservatives"
        } else if hasArtificialPreservatives && hasArtificialColors {
            explanation = "Contains artificial preservatives and colors"
        } else if hasArtificialPreservatives {
            explanation = "Contains artificial preservatives"
        } else if hasArtificialColors {
            explanation = "Contains artificial coloring"
        } else {
            explanation = "\(totalAdditives) additive\(totalAdditives == 1 ? "" : "s")"
        }

        let recommendations: [String] = score < 80 ?
            ["Choose products with fewer artificial additives"] : []

        return ComponentScoringResult(
            score: Double(score),
            explanation: explanation,
            recommendations: recommendations,
            adjustments: adjustments,
            keyFactors: keyFactors
        )
    }

    // MARK: - Data Completeness Assessment

    private func assessDataCompleteness(product: ProductModel) -> (confidence: ScoreConfidence, warning: String?, missingFields: [String]) {
        var missingFields: [String] = []
        let nutrition = product.nutrition

        // Check macronutrient completeness
        var macroCount = 0
        if nutrition.calories > 0 { macroCount += 1 }
        if nutrition.protein > 0 { macroCount += 1 }
        if nutrition.carbohydrates > 0 { macroCount += 1 }
        if nutrition.fat > 0 { macroCount += 1 }
        if nutrition.fiber > 0 { macroCount += 1 }
        if nutrition.sugar > 0 { macroCount += 1 }
        if nutrition.sodium > 0 { macroCount += 1 }

        if macroCount < NutritionGuidelines.DataCompleteness.minMacronutrientsForHighConfidence {
            missingFields.append("macronutrients")
        }

        // Check ingredient completeness
        if product.ingredients.count < NutritionGuidelines.DataCompleteness.minIngredientsForHighConfidence {
            missingFields.append("ingredients")
        }

        // Determine confidence level
        let confidence: ScoreConfidence
        let warning: String?

        if missingFields.isEmpty {
            confidence = .high
            warning = nil
        } else if missingFields.count == 1 {
            confidence = .medium
            warning = "Limited \(missingFields[0]) data—score may be less accurate"
        } else {
            confidence = .low
            warning = "Limited data for: \(missingFields.joined(separator: ", "))—score accuracy is reduced"
        }

        return (confidence, warning, missingFields)
    }

    private func adjustWeightsForCompleteness(weights: ComponentWeights, completeness: (confidence: ScoreConfidence, warning: String?, missingFields: [String])) -> ComponentWeights {
        // If confidence is low, we might want to redistribute weights
        // For now, we'll keep weights the same but this could be enhanced
        // to reduce weight of components with missing data

        if completeness.missingFields.contains("ingredients") {
            // Reduce ingredient quality weight slightly, redistribute to other components
            let reduction = weights.ingredientQuality * 0.3
            let redistributePerComponent = reduction / 4.0

            return ComponentWeights(
                macronutrientBalance: weights.macronutrientBalance + redistributePerComponent,
                micronutrientDensity: weights.micronutrientDensity + redistributePerComponent,
                processingLevel: weights.processingLevel + redistributePerComponent,
                ingredientQuality: weights.ingredientQuality - reduction,
                additives: weights.additives + redistributePerComponent
            )
        }

        return weights
    }

    // MARK: - Breakdown Creation

    private func createBreakdown(
        macroResult: ComponentScoringResult,
        microResult: ComponentScoringResult,
        processingResult: ComponentScoringResult,
        ingredientResult: ComponentScoringResult,
        additiveResult: ComponentScoringResult,
        weights: ComponentWeights
    ) -> [ComponentBreakdown] {
        return [
            ComponentBreakdown(
                componentName: "Macronutrients",
                rawScore: macroResult.score,
                weight: weights.macronutrientBalance,
                weightedScore: macroResult.score * weights.macronutrientBalance,
                explanation: macroResult.explanation,
                keyFactors: macroResult.keyFactors
            ),
            ComponentBreakdown(
                componentName: "Micronutrients",
                rawScore: microResult.score,
                weight: weights.micronutrientDensity,
                weightedScore: microResult.score * weights.micronutrientDensity,
                explanation: microResult.explanation,
                keyFactors: microResult.keyFactors
            ),
            ComponentBreakdown(
                componentName: "Processing Level",
                rawScore: processingResult.score,
                weight: weights.processingLevel,
                weightedScore: processingResult.score * weights.processingLevel,
                explanation: processingResult.explanation,
                keyFactors: processingResult.keyFactors
            ),
            ComponentBreakdown(
                componentName: "Ingredient Quality",
                rawScore: ingredientResult.score,
                weight: weights.ingredientQuality,
                weightedScore: ingredientResult.score * weights.ingredientQuality,
                explanation: ingredientResult.explanation,
                keyFactors: ingredientResult.keyFactors
            ),
            ComponentBreakdown(
                componentName: "Additives",
                rawScore: additiveResult.score,
                weight: weights.additives,
                weightedScore: additiveResult.score * weights.additives,
                explanation: additiveResult.explanation,
                keyFactors: additiveResult.keyFactors
            )
        ]
    }

    // MARK: - Overall Score Calculation

    private func calculateOverallScore(components: ScoreComponents) -> Double {
        let weighted = (components.macronutrientBalance.score * components.macronutrientBalance.weight) +
                      (components.micronutrientDensity.score * components.micronutrientDensity.weight) +
                      (components.processingLevel.score * components.processingLevel.weight) +
                      (components.ingredientQuality.score * components.ingredientQuality.weight) +
                      (components.additives.score * components.additives.weight)

        return min(100, max(0, weighted))
    }

    // MARK: - Explanation Generation

    private func generateExplanation(
        components: ScoreComponents,
        focus: HealthFocus,
        overallScore: Double,
        breakdown: [ComponentBreakdown],
        confidence: ScoreConfidence
    ) -> String {
        let scoreCategory = ScoreColor.from(score: overallScore)

        let focusDescription = focus.displayName.lowercased()

        let mainMessage: String
        switch scoreCategory {
        case .excellent:
            mainMessage = "This product is an excellent choice for \(focusDescription)."
        case .good:
            mainMessage = "This product is a good choice for \(focusDescription)."
        case .fair:
            mainMessage = "This product is an okay choice for \(focusDescription), but better options may be available."
        case .poor:
            mainMessage = "This product may not be the best choice for \(focusDescription)."
        }

        // Find top contributing component
        let topComponent = breakdown.max(by: { $0.weightedScore < $1.weightedScore })

        // Find weakest component
        let weakness = breakdown.min(by: { $0.rawScore < $1.rawScore })

        var explanation = "\(mainMessage)"

        if let topComponent = topComponent {
            let contribution = Int(topComponent.weightedScore)
            explanation += " Its strongest aspect is \(topComponent.componentName.lowercased()) (contributing \(contribution) points)"
            if !topComponent.keyFactors.isEmpty {
                explanation += ": \(topComponent.keyFactors.first ?? "")"
            }
            explanation += "."
        }

        if let weakness = weakness, weakness.rawScore < 70 {
            explanation += " The weakest aspect is \(weakness.componentName.lowercased()) (score: \(Int(weakness.rawScore)))"
            if !weakness.keyFactors.isEmpty {
                explanation += ": \(weakness.keyFactors.first ?? "")"
            }
            explanation += "."
        }

        // Add confidence note if not high
        if confidence != .high {
            explanation += " Note: This score has \(confidence.displayName.lowercased()) due to limited data."
        }

        return explanation
    }
}
