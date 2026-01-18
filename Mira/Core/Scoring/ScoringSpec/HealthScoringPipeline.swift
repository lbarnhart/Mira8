import Foundation

final class HealthScoringPipeline {
    private let inputNormalizer: ScoringInputNormalizer
    private let pillarEvaluator: PillarEvaluator
    private let guardrailEngine: GuardrailEngine
    private let tierMapper: TierMapper
    private let percentileCalculator: CategoryPercentileCalculator
    private let algorithmVersion: String
    private let thresholdSetID: String

    init(
        inputNormalizer: ScoringInputNormalizer = ScoringInputNormalizer(),
        pillarEvaluator: PillarEvaluator = PillarEvaluator(),
        guardrailEngine: GuardrailEngine? = nil,
        tierMapper: TierMapper = TierMapper(),
        percentileCalculator: CategoryPercentileCalculator = .shared,
        dietaryRestrictions: [DietaryRestriction] = []
    ) {
        self.inputNormalizer = inputNormalizer
        self.pillarEvaluator = pillarEvaluator
        self.guardrailEngine = guardrailEngine ?? GuardrailEngine(dietaryRestrictions: dietaryRestrictions)
        self.tierMapper = tierMapper
        self.percentileCalculator = percentileCalculator
        self.algorithmVersion = "health-scoring-v1.1.1"
        if let metadata = try? AssetLoader.thresholds().metadata {
            self.thresholdSetID = "\(metadata.id)#\(metadata.version)"
        } else {
            self.thresholdSetID = "thresholds.unknown"
        }
    }

    func score(for product: ProductModel, activeCaps: Set<String> = [], dietaryRestrictions: [DietaryRestriction] = []) -> HealthScore {
        let input = inputNormalizer.normalize(product: product)
        let normalizedProduct = NormalizedProduct(input: input)
        let evaluation = pillarEvaluator.evaluate(input: input)
        // Reinitialize guardrailEngine with dietary restrictions if needed
        let guardrail = guardrailEngine.apply(product: normalizedProduct, evaluation: evaluation, activeCaps: activeCaps)
        let mapping = tierMapper.map(evaluation: evaluation, guardrail: guardrail)

        let pillarsRemaining = max(evaluation.pillars.count - evaluation.pillarsDropped.count, 0)
        let tier = determineTier(score: guardrail.finalScore, pillarsRemaining: pillarsRemaining)
        let grade = determineGrade(for: guardrail.finalScore)
        let uxMessages = buildUxMessages(evaluation: evaluation, guardrail: guardrail)
        let scoringResult = buildScoringResult(
            normalizedProduct: normalizedProduct,
            evaluation: evaluation,
            guardrail: guardrail,
            mapping: mapping,
            tier: tier,
            grade: grade
        )
        
        // MARK: - Scoring 2.0: Consumer-Friendly Additions
        
        // Calculate verdict
        let verdict = ScoreVerdict(score: guardrail.finalScore)
        
        // Calculate category percentile
        let category = product.category ?? product.categorySlug
        
        #if DEBUG
        AppLog.debug("🏷️ CATEGORY DETECTION - Product: \(product.name)", category: .scoring)
        AppLog.debug("🏷️ Category: \(product.category ?? "nil")", category: .scoring)
        AppLog.debug("🏷️ CategorySlug: \(product.categorySlug ?? "nil")", category: .scoring)
        AppLog.debug("🏷️ Selected: \(category ?? "nil")", category: .scoring)
        if let category = category {
            let profile = CategoryAdjustments.adjustedThresholds(for: category)
            AppLog.debug("🏷️ Profile: \(profile)", category: .scoring)
            AppLog.debug("🏷️ Sodium thresholds: \(profile.sodiumThresholds)", category: .scoring)
        }
        AppLog.debug("🏷️ Final Score: \(Int(guardrail.finalScore))", category: .scoring)
        #endif
        
        let percentile = percentileCalculator.calculatePercentile(score: guardrail.finalScore, category: category)
        let categoryRank = percentile.map { percentileCalculator.formatCategoryRank(percentile: $0, category: category) }
        
        // Build top factors for simplified display
        let topFactors = buildTopFactors(
            mapping: mapping,
            guardrail: guardrail,
            evaluation: evaluation
        )
        
        // Calculate Nutriscore verdict from API data if available
        let nutriScoreVerdict: NutriScoreVerdict
        if let nutriScore = product.nutriScore {
            nutriScoreVerdict = NutriScoreVerdict(from: nutriScore)
            #if DEBUG
            AppLog.debug("🥛 NutriScore Verdict: \(nutriScore) → \(nutriScoreVerdict.displayLabel)", category: .scoring)
            #endif
        } else {
            nutriScoreVerdict = .unknown
        }
        
        // Use Nutriscore verdict for primary display if available
        let verdictForDisplay = nutriScoreVerdict != .unknown 
            ? ScoreVerdict(from: nutriScoreVerdict)
            : .fair  // When Nutriscore unavailable, show neutral verdict instead of harsh custom score
        
        // Only show category context if Nutriscore is NOT available
        // When Nutriscore is primary verdict, don't confuse users with percentile rankings
        let categoryContext = nutriScoreVerdict == .unknown ? categoryRank : nil
        
        // Create simplified display (using Nutriscore as primary if available)
        let simplifiedDisplay = SimplifiedScoreDisplay(
            score: guardrail.finalScore,
            verdict: verdictForDisplay,
            topFactors: topFactors,
            categoryContext: categoryContext
        )
        
        // Record score for future percentile calculations
        percentileCalculator.recordScore(score: guardrail.finalScore, category: category)
        
        return HealthScore(
            rawScore: evaluation.baseScore,
            overall: guardrail.finalScore,
            tier: tier,
            grade: grade,
            explanation: mapping.explanation,
            confidence: guardrail.confidence,
            confidenceWarning: guardrail.warning,
            confidenceRange: guardrail.confidenceRange,
            rawPositivePoints: evaluation.rawPositivePoints,
            rawNegativePoints: evaluation.rawNegativePoints,
            weightedPositivePoints: evaluation.weightedPositivePoints,
            weightedNegativePoints: evaluation.weightedNegativePoints,
            contributions: mapping.contributions,
            breakdown: mapping.breakdown,
            adjustments: mapping.adjustments,
            topReasons: mapping.topReasons,
            uxMessages: uxMessages,
            components: .empty,
            scoringResult: scoringResult,
            verdict: verdict,
            simplifiedDisplay: simplifiedDisplay,
            categoryPercentile: percentile,
            categoryRank: categoryRank,
            nutriScoreVerdict: nutriScoreVerdict
        )
    }

    private func buildScoringResult(
        normalizedProduct: NormalizedProduct,
        evaluation: PillarEvaluation,
        guardrail: GuardrailOutcome,
        mapping: TierMappingOutput,
        tier: ScoreTier,
        grade: ScoreGrade
    ) -> ScoringResult {
        let capsApplied = guardrail.capsApplied.map { cap in
            GuardrailCap(ruleID: cap.ruleID, tier: cap.tier, reason: cap.reason)
        }

        var notes = normalizedProduct.input.density.notes.map { $0.rawValue }
        if let warning = guardrail.warning { notes.append(warning) }
        if evaluation.lensApplied { notes.append("lens_adjuster_applied") }

        var missingFields = normalizedProduct.input.density.missingFields.map { $0.rawValue }
        for droppedPillar in evaluation.pillarsDropped {
            missingFields.append("pillar_dropped:\(droppedPillar.rawValue)")
        }

        let categoryLabel = deriveCategoryLabel(for: normalizedProduct.product)
        let suggestedSwapCategories = deriveSuggestedSwapCategories(
            for: normalizedProduct.product,
            tier: tier,
            evaluation: evaluation
        )

        return ScoringResult(
            productID: normalizedProduct.product.id,
            algorithmVersion: algorithmVersion,
            weightsProfileID: evaluation.weightsProfileID,
            thresholdSetID: thresholdSetID,
            rawScore: evaluation.baseScore,
            tier: tier,
            grade: grade,
            topReasons: mapping.topReasons,
            categoryLabel: categoryLabel,
            lensApplied: evaluation.lensApplied,
            capsApplied: capsApplied,
            pillarsDropped: evaluation.pillarsDropped,
            missingFields: missingFields,
            dataConfidence: normalizedProduct.input.density.dataConfidence,
            notes: notes,
            isConfidentCategoryClassification: isConfidentCategoryClassification(for: normalizedProduct.product),
            suggestedSwapCategories: suggestedSwapCategories
        )
    }

    private func determineTier(score: Double, pillarsRemaining: Int) -> ScoreTier {
        guard pillarsRemaining >= 2 else { return .insufficientData }

        switch score {
        case ..<40: return .poor
        case 40..<65: return .fair
        case 65..<85: return .good
        default: return .excellent
        }
    }

    private func determineGrade(for score: Double) -> ScoreGrade {
        return ScoreGrade(score: score)
    }

    private func buildUxMessages(evaluation: PillarEvaluation, guardrail: GuardrailOutcome) -> [String] {
        var messages: [String] = []

        if guardrail.confidence == .medium {
            messages.append("Some core nutrients are missing; treat this score as directional.")
        } else if guardrail.confidence == .low {
            messages.append("Limited data detected. Collect more nutrition facts for better accuracy.")
        }

        let remainingPillars = evaluation.pillars.count - evaluation.pillarsDropped.count
        if remainingPillars < 2 {
            messages.append("Only \(remainingPillars) scoring pillar available—more nutrient data needed.")
        }

        return messages
    }
    
    /// Build top 2-3 key factors for simplified display
    /// Prioritizes: guardrail caps > high-impact penalties > high-impact boosts
    private func buildTopFactors(
        mapping: TierMappingOutput,
        guardrail: GuardrailOutcome,
        evaluation: PillarEvaluation
    ) -> [String] {
        var factors: [(priority: Int, message: String)] = []
        
        // Priority 1: Guardrail caps (deal-breakers)
        for cap in guardrail.capsApplied {
            let message: String
            switch cap.tier {
            case .tier0, .tier1:
                message = "⚠️ \(cap.reason.split(separator: ".").first ?? Substring(cap.reason))"
            case .tier2:
                message = "⚠️ Contains processed ingredients"
            case .tier3, .tier4:
                // Don't show generic "nutrients missing" - show specific reason if available
                if cap.reason.contains("allergen") {
                    message = "ℹ️ Allergen information not declared"
                } else {
                    // Skip showing tier 3/4 caps that aren't meaningful for the summary
                    continue
                }
            }
            factors.append((priority: 1, message: String(message)))
        }
        
        // Priority 2: Significant negative contributions
        let negativeContributions = evaluation.contributions
            .filter { $0.kind == .negative && $0.weightedPoints > 5.0 }
            .sorted { $0.weightedPoints > $1.weightedPoints }
        
        for contribution in negativeContributions.prefix(2) {
            let message: String
            switch contribution.nutrient {
            case .sugars:
                message = "⚠️ High sugar (\(Int(contribution.value ?? 0))g)"
            case .sodium:
                message = "⚠️ High sodium (\(Int(contribution.value ?? 0))mg)"
            case .saturatedFat:
                message = "⚠️ High saturated fat (\(String(format: "%.1f", contribution.value ?? 0))g)"
            case .energy:
                message = "⚠️ High calorie density"
            default:
                continue
            }
            factors.append((priority: 2, message: message))
        }
        
        // Priority 3: Significant positive contributions
        let positiveContributions = evaluation.contributions
            .filter { $0.kind == .positive && $0.weightedPoints > 3.0 }
            .sorted { $0.weightedPoints > $1.weightedPoints }
        
        for contribution in positiveContributions.prefix(2) {
            let message: String
            switch contribution.nutrient {
            case .protein:
                message = "✓ Good protein source (\(String(format: "%.1f", contribution.value ?? 0))g)"
            case .fiber:
                message = "✓ High fiber (\(String(format: "%.1f", contribution.value ?? 0))g)"
            case .fruitVegLegumeNut:
                if let value = contribution.value {
                    message = "✓ Contains produce (\(Int(value))%)"
                } else {
                    continue
                }
            default:
                continue
            }
            factors.append((priority: 3, message: message))
        }
        
        // Sort by priority and take top 3
        let topFactors = factors
            .sorted { $0.priority < $1.priority }
            .prefix(3)
            .map { $0.message }
        
        // If no significant factors, provide generic message based on score
        if topFactors.isEmpty {
            let score = guardrail.finalScore
            if score >= 70 {
                return ["✓ Balanced nutrition profile"]
            } else if score >= 40 {
                return ["~ Moderate nutritional quality"]
            } else {
                return ["⚠️ Consider healthier alternatives"]
            }
        }
        
        return Array(topFactors)
    }

    private func isConfidentCategoryClassification(for product: ProductModel) -> Bool {
        return product.category != nil || product.categorySlug != nil
    }

    private func deriveCategoryLabel(for product: ProductModel) -> String {
        if let category = product.category, !category.isEmpty {
            return category
        }

        if let categorySlug = product.categorySlug, !categorySlug.isEmpty {
            return categorySlug
                .replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }

        if product.isLikelyBeverage {
            return "Beverages"
        }

        return "General Foods"
    }

    private func deriveSuggestedSwapCategories(
        for product: ProductModel,
        tier: ScoreTier,
        evaluation: PillarEvaluation
    ) -> [String] {
        guard tier == .poor || tier == .fair else {
            return []
        }

        var suggestions: [String] = []

        if let categorySlug = product.categorySlug {
            if categorySlug.contains("snack") || categorySlug.contains("chip") {
                suggestions.append("fresh-fruit")
                suggestions.append("nuts-seeds")
                suggestions.append("yogurt")
            } else if categorySlug.contains("soda") || categorySlug.contains("juice") {
                suggestions.append("water")
                suggestions.append("unsweetened-tea")
            } else if categorySlug.contains("candy") || categorySlug.contains("chocolate") {
                suggestions.append("dark-chocolate")
                suggestions.append("fruit")
            } else if categorySlug.contains("breakfast") || categorySlug.contains("cereal") {
                suggestions.append("oatmeal")
                suggestions.append("whole-grain-cereal")
            }
        }

        let tempInput = inputNormalizer.normalize(product: product)
        let matchResult = tempInput.ingredientMatchResult

        if matchResult.containsRefinedOil {
            suggestions.append("unrefined-oils")
        }

        if matchResult.containsNonNutritiveSweetener {
            suggestions.append("naturally-sweetened")
        }

        if evaluation.pillarsDropped.contains(.p4PositiveNutrition) {
            suggestions.append("nutrient-dense")
        }

        return Array(Set(suggestions)).sorted()
    }
}
