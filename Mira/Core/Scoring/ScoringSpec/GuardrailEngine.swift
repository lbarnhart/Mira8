import Foundation

struct GuardrailCapOutcome {
    let ruleID: String
    let tier: GuardrailTier
    let reason: String
}

enum GuardrailTriggerSeverity: String {
    case red
    case hardFail
}

struct GuardrailTriggerOutcome {
    let ruleID: String
    let severity: GuardrailTriggerSeverity
    let message: String
}

enum GuardrailTier: Int, Codable {
    case tier0 = 0
    case tier1 = 1
    case tier2 = 2
    case tier3 = 3
    case tier4 = 4

    var maxScore: Double {
        switch self {
        case .tier0: return 25
        case .tier1: return 55
        case .tier2: return 80
        case .tier3: return 90
        case .tier4: return 100
        }
    }
}

enum GuardrailRuleOutcome {
    case none
    case cap(tier: GuardrailTier, reason: String)
    case redTrigger(reason: String)
    case hardFail(reason: String)
}

typealias GuardrailCategoryFilter = (NormalizedProduct) -> Bool

protocol GuardrailRule {
    var id: String { get }
    var categoryFilter: GuardrailCategoryFilter? { get }
    func evaluate(product: NormalizedProduct, evaluation: PillarEvaluation) -> GuardrailRuleOutcome
}

extension GuardrailRule {
    func applies(to product: NormalizedProduct) -> Bool {
        guard let filter = categoryFilter else { return true }
        return filter(product)
    }
}

struct GuardrailOutcome {
    let baseScore: Double
    let normalizedScore: Double
    let finalScore: Double
    let confidence: ScoreConfidence
    let confidenceRange: ClosedRange<Double>
    let warning: String?
    let capsApplied: [GuardrailCapOutcome]
    let triggers: [GuardrailTriggerOutcome]
}

final class GuardrailEngine {
    private enum Constants {
        static let baseRange: ClosedRange<Double> = 0...100
        static let redTriggerMaxScore: Double = 60
    }

    private let rules: [GuardrailRule]

    init(
        rules: [GuardrailRule]? = nil,
        dietaryRestrictions: [DietaryRestriction] = []
    ) {
        if let rules = rules {
            self.rules = rules
        } else {
            // Default rules, including new allergen and safety rules
            self.rules = [
                MissingCriticalNutrientsRule(),
                RefinedOilRule(),
                NonNutritiveSweetenerRule(),
                UltraProcessedMarkerRule(),
                CommonAllergenRule(userRestrictions: dietaryRestrictions),
                NutrientCeilingRule(),
                ExtremeHighSugarRule(),
                ExtremeHighSodiumRule(),
                MissingAllergenDeclarationRule()
            ]
        }
    }

    func apply(
        product: NormalizedProduct,
        evaluation: PillarEvaluation,
        activeCaps: Set<String>
    ) -> GuardrailOutcome {
        let normalizedScore = clamp(evaluation.baseScore, to: Constants.baseRange)

        let confidenceAssessment = confidence(from: evaluation.missingCriticalNutrients)
        var confidence = confidenceAssessment.level
        var confidenceRange = confidenceAssessment.range

        var warnings: [String] = []
        if let warning = confidenceAssessment.warning {
            warnings.append(warning)
        }

        // Get category-specific leniency
        let category = product.product.category ?? product.product.categorySlug
        let categoryProfile = CategoryAdjustments.adjustedThresholds(for: category)
        let leniency = categoryProfile.guardrailLeniency

        var finalScore = normalizedScore
        var capsApplied: [GuardrailCapOutcome] = []
        var triggers: [GuardrailTriggerOutcome] = []

        var stopProcessing = false
        
        #if DEBUG
        print("🚨 GuardrailEngine.apply() started for: \(product.product.name)")
        print("   Product category: \(category ?? "unknown")")
        print("   Leniency level: \(leniency)")
        print("   Base score: \(normalizedScore)")
        #endif
        
        for rule in rules {
            if stopProcessing { break }
            guard !activeCaps.contains(rule.id), rule.applies(to: product) else { continue }

            #if DEBUG
            print("   📋 Checking rule: \(rule.id)")
            #endif
            
            switch rule.evaluate(product: product, evaluation: evaluation) {
            case .none:
                #if DEBUG
                print("      ✓ No issue")
                #endif
                continue
            case .cap(let tier, let reason):
                // Skip applying further caps if already have a red/hard trigger
                guard triggers.isEmpty else {
                    continue
                }
                // Apply category leniency to raise the cap tier
                let adjustedTier = leniency.adjustTier(tier)
                let capOutcome = GuardrailCapOutcome(ruleID: rule.id, tier: adjustedTier, reason: reason)
                capsApplied.append(capOutcome)
                warnings.append(reason)
                finalScore = min(finalScore, adjustedTier.maxScore)
                confidenceRange = clampRange(confidenceRange, upper: adjustedTier.maxScore)
                #if DEBUG
                print("      🔶 CAP applied: \(rule.id) → tier \(adjustedTier) (max \(adjustedTier.maxScore))")
                #endif
            case .redTrigger(let reason):
                let trigger = GuardrailTriggerOutcome(ruleID: rule.id, severity: .red, message: reason)
                triggers.append(trigger)
                warnings.append(reason)
                finalScore = min(finalScore, Constants.redTriggerMaxScore)
                confidence = .low
                confidenceRange = clampRange(confidenceRange, upper: Constants.redTriggerMaxScore)
                #if DEBUG
                print("      🔴 RED TRIGGER: \(rule.id)")
                #endif
            case .hardFail(let reason):
                let trigger = GuardrailTriggerOutcome(ruleID: rule.id, severity: .hardFail, message: reason)
                triggers.append(trigger)
                warnings.append(reason)
                finalScore = 0
                confidence = .low
                confidenceRange = 0...0
                stopProcessing = true
                #if DEBUG
                print("      ⛔ HARD FAIL: \(rule.id) - \(reason)")
                #endif
            }
        }

        finalScore = clamp(finalScore, to: confidenceRange)

        let warningText = warnings.isEmpty ? nil : warnings.joined(separator: " ")
        
        #if DEBUG
        print("   Final score: \(finalScore)")
        print("   Caps applied: \(capsApplied.count)")
        print("   Hard fails: \(triggers.filter { $0.severity == .hardFail }.count)")
        #endif

        return GuardrailOutcome(
            baseScore: evaluation.baseScore,
            normalizedScore: normalizedScore,
            finalScore: finalScore,
            confidence: confidence,
            confidenceRange: confidenceRange,
            warning: warningText,
            capsApplied: capsApplied,
            triggers: triggers
        )
    }

    private func confidence(from missing: [String]) -> (level: ScoreConfidence, range: ClosedRange<Double>, warning: String?) {
        switch missing.count {
        case 0:
            return (.high, 0...100, nil)
        case 1, 2:
            let warning = "Missing \(missing.joined(separator: ", ")). Score constrained to 10–90."
            return (.medium, 10...90, warning)
        default:
            let warning = "Missing \(missing.joined(separator: ", ")). Score constrained to 20–80."
            return (.low, 20...80, warning)
        }
    }

    private func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }

    private func clampRange(_ range: ClosedRange<Double>, upper: Double) -> ClosedRange<Double> {
        let newUpper = min(range.upperBound, upper)
        let lower = min(range.lowerBound, newUpper)
        return lower...newUpper
    }
}

private struct MissingCriticalNutrientsRule: GuardrailRule {
    let id = "guardrail.missing-critical-nutrients"
    let categoryFilter: GuardrailCategoryFilter? = nil

    func evaluate(product: NormalizedProduct, evaluation: PillarEvaluation) -> GuardrailRuleOutcome {
        let missing = evaluation.missingCriticalNutrients
        guard !missing.isEmpty else { return .none }

        let label = missing.joined(separator: ", ")
        if missing.count <= 2 {
            return .cap(tier: .tier3, reason: "Missing \(label). Score capped at tier 3 (≤90).")
        }

        return .cap(tier: .tier2, reason: "Missing \(label). Score capped at tier 2 (≤80).")
    }
}

private struct RefinedOilRule: GuardrailRule {
    let id = "guardrail.refined-oil"
    let categoryFilter: GuardrailCategoryFilter? = nil

    func evaluate(product: NormalizedProduct, evaluation: PillarEvaluation) -> GuardrailRuleOutcome {
        let matchResult = product.ingredientMatchResult
        guard matchResult.containsRefinedOil else { return .none }

        if matchResult.firstIngredientCategory == .refinedOil {
            return .cap(tier: .tier1, reason: "Primary ingredient is refined oil. Score capped at tier 1 (≤55).")
        }

        return .cap(tier: .tier2, reason: "Contains refined oils. Score capped at tier 2 (≤80).")
    }
}

private struct NonNutritiveSweetenerRule: GuardrailRule {
    let id = "guardrail.non-nutritive-sweetener"
    let categoryFilter: GuardrailCategoryFilter? = nil

    func evaluate(product: NormalizedProduct, evaluation: PillarEvaluation) -> GuardrailRuleOutcome {
        let matchResult = product.ingredientMatchResult
        guard matchResult.containsNonNutritiveSweetener else { return .none }

        let baseScore = evaluation.baseScore
        if baseScore > 75 {
            return .redTrigger(reason: "Contains non-nutritive sweeteners. High-scoring products should use natural ingredients.")
        }

        return .cap(tier: .tier2, reason: "Contains non-nutritive sweeteners. Score capped at tier 2 (≤80).")
    }
}

private struct UltraProcessedMarkerRule: GuardrailRule {
    let id = "guardrail.ultra-processed-marker"
    let categoryFilter: GuardrailCategoryFilter? = nil

    func evaluate(product: NormalizedProduct, evaluation: PillarEvaluation) -> GuardrailRuleOutcome {
        let matchResult = product.ingredientMatchResult
        guard matchResult.containsUltraProcessedMarker else { return .none }

        if matchResult.firstIngredientCategory == .ultraProcessed {
            return .cap(tier: .tier0, reason: "Primary ingredient is ultra-processed marker. Score capped at tier 0 (≤25).")
        }

        return .cap(tier: .tier2, reason: "Contains ultra-processed markers. Score capped at tier 2 (≤80).")
    }
}

private struct CommonAllergenRule: GuardrailRule {
    let id = "guardrail.common-allergen"
    let categoryFilter: GuardrailCategoryFilter? = nil
    let userRestrictions: [DietaryRestriction]

    init(userRestrictions: [DietaryRestriction]) {
        self.userRestrictions = userRestrictions
    }

    func evaluate(product: NormalizedProduct, evaluation: PillarEvaluation) -> GuardrailRuleOutcome {
        guard !userRestrictions.isEmpty else { return .none }

        let ingredientsText = product.product.ingredients.joined(separator: " ").lowercased()
        for restriction in userRestrictions {
            switch restriction {
            case .vegan:
                if ingredientsText.contains("milk") || ingredientsText.contains("egg") || ingredientsText.contains("honey") {
                    return .hardFail(reason: "Product contains ingredients that violate vegan dietary restriction.")
                }
            case .vegetarian:
                if ingredientsText.contains("meat") || ingredientsText.contains("fish") {
                    return .hardFail(reason: "Product contains ingredients that violate vegetarian dietary restriction.")
                }
            case .glutenFree:
                if ingredientsText.contains("wheat") || ingredientsText.contains("barley") || ingredientsText.contains("rye") {
                    return .hardFail(reason: "Product contains gluten-containing ingredients.")
                }
            case .dairyFree:
                if ingredientsText.contains("milk") || ingredientsText.contains("cheese") || ingredientsText.contains("whey") {
                    return .hardFail(reason: "Product contains dairy ingredients.")
                }
            case .nutFree:
                if ingredientsText.contains("peanut") || ingredientsText.contains("tree nut") || ingredientsText.contains("almond") {
                    return .hardFail(reason: "Product contains nut ingredients.")
                }
            case .lowSodium, .sugarFree:
                // These are preferences rather than hard restrictions
                continue
            }
        }

        return .none
    }
}

private struct NutrientCeilingRule: GuardrailRule {
    let id = "guardrail.nutrient-ceiling"
    let categoryFilter: GuardrailCategoryFilter? = nil

    func evaluate(product: NormalizedProduct, evaluation: PillarEvaluation) -> GuardrailRuleOutcome {
        let nutrition = product.product.nutrition

        // Extreme sodium (>1500mg per serving)
        if nutrition.sodium > 1.5 {
            return .cap(tier: .tier1, reason: "Extremely high sodium content. Score capped at tier 1 (≤55).")
        }

        // Extreme sugar (>30g per serving)
        if nutrition.sugar > 30 {
            return .cap(tier: .tier1, reason: "Extremely high sugar content. Score capped at tier 1 (≤55).")
        }

        // Extreme saturated fat (>15g per serving)
        if nutrition.saturatedFat > 15 {
            return .cap(tier: .tier2, reason: "Extremely high saturated fat content. Score capped at tier 2 (≤80).")
        }

        return .none
    }
}

private struct ExtremeHighSugarRule: GuardrailRule {
    let id = "guardrail.extreme-sugar"
    let categoryFilter: GuardrailCategoryFilter? = nil

    func evaluate(product: NormalizedProduct, evaluation: PillarEvaluation) -> GuardrailRuleOutcome {
        let nutrition = product.product.nutrition
        let servingGrams = parseServingSizeGrams(from: nutrition.servingSize)
        
        // Calculate sugar per ACTUAL serving (nutrition values are per 100g)
        let sugarPerServing = nutrition.sugar * (servingGrams / 100.0)

        // >40g sugar per actual serving is concerning
        if sugarPerServing > 40 {
            let formattedSugar = String(format: "%.1f", sugarPerServing)
            return .hardFail(reason: "Sugar content exceeds safe limits (\(formattedSugar)g per \(Int(servingGrams))g serving).")
        }

        return .none
    }
    
    private func parseServingSizeGrams(from servingString: String) -> Double {
        ServingSizeParser.extractGrams(from: servingString)
    }
}

private struct ExtremeHighSodiumRule: GuardrailRule {
    let id = "guardrail.extreme-sodium"
    let categoryFilter: GuardrailCategoryFilter? = nil

    func evaluate(product: NormalizedProduct, evaluation: PillarEvaluation) -> GuardrailRuleOutcome {
        let nutrition = product.product.nutrition
        let servingGrams = parseServingSizeGrams(from: nutrition.servingSize)
        
        // Calculate sodium per ACTUAL serving (nutrition values are per 100g)
        let sodiumPerServing = nutrition.sodium * (servingGrams / 100.0)

        // >2g sodium per actual serving is concerning
        if sodiumPerServing > 2.0 {
            let sodiumMg = sodiumPerServing * 1000  // Convert to mg for user display
            return .hardFail(reason: "Sodium content exceeds safe limits (\(Int(sodiumMg))mg per \(Int(servingGrams))g serving).")
        }

        return .none
    }
    
    private func parseServingSizeGrams(from servingString: String) -> Double {
        ServingSizeParser.extractGrams(from: servingString)
    }
}

private struct MissingAllergenDeclarationRule: GuardrailRule {
    let id = "guardrail.missing-allergen-declaration"
    let categoryFilter: GuardrailCategoryFilter? = nil

    func evaluate(product: NormalizedProduct, evaluation: PillarEvaluation) -> GuardrailRuleOutcome {
        let ingredients = product.product.ingredients
        let dietaryFlags = product.product.dietaryFlags

        // Check if product has ingredients but no dietary flags (suggesting missing allergen info)
        if !ingredients.isEmpty && dietaryFlags.isEmpty {
            // Only cap if it's a category where allergen info is typically important
            let category = (product.product.category ?? product.product.categorySlug ?? "").lowercased()
            if category.contains("nut") || category.contains("milk") || category.contains("dairy") || category.contains("gluten") {
                return .cap(tier: .tier3, reason: "Allergen information missing. Score capped at tier 3 (≤90).")
            }
        }

        return .none
    }
}

// MARK: - Serving Size Parser Utility

/// Utility to parse serving size strings and extract grams
/// Handles formats like: "33g", "2 tbsp (33g)", "100g", "1 cup (240g)", "30 ml"
private enum ServingSizeParser {
    
    /// Extract grams from serving size string
    /// Returns the parsed value or defaults to 100g if parsing fails
    static func extractGrams(from servingString: String) -> Double {
        let normalized = servingString.lowercased().trimmingCharacters(in: .whitespaces)
        
        #if DEBUG
        print("🔍 ServingSizeParser.extractGrams called with: '\(servingString)'")
        #endif
        
        // Pattern 1: Look for explicit grams - "33g" or "(33g)" or "33 g"
        // This handles: "33g", "2 tbsp (33g)", "(33g)", "33 g"
        if let grams = extractNumber(from: normalized, pattern: #"(\d+\.?\d*)\s*g\b"#) {
            #if DEBUG
            print("✓ ServingSizeParser: Extracted \(grams)g from explicit grams pattern")
            #endif
            return grams
        }
        
        // Pattern 2: Look for milliliters and assume 1ml ≈ 1g for liquids
        // This handles: "30ml", "30 ml", "(30ml)"
        if let ml = extractNumber(from: normalized, pattern: #"(\d+\.?\d*)\s*ml\b"#) {
            #if DEBUG
            print("✓ ServingSizeParser: Extracted \(ml)g from ml pattern")
            #endif
            return ml  // 1ml ≈ 1g for most liquids
        }
        
        // Pattern 3: Common volume measurements -> gram estimates
        if let grams = estimateFromVolumeDescription(normalized) {
            #if DEBUG
            print("✓ ServingSizeParser: Estimated \(grams)g from volume description")
            #endif
            return grams
        }
        
        // Default: assume 100g if we can't parse
        // This is safe because nutrition values are stored per 100g
        #if DEBUG
        print("⚠️ ServingSizeParser: Could not parse '\(servingString)', defaulting to 100g")
        #endif
        return 100.0
    }
    
    /// Extract numeric value using regex pattern
    private static func extractNumber(from text: String, pattern: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }
        
        // Extract the captured group (the number)
        if match.numberOfRanges >= 2,
           let numberRange = Range(match.range(at: 1), in: text) {
            let numberString = String(text[numberRange])
            return Double(numberString)
        }
        
        return nil
    }
    
    /// Estimate grams from common volume descriptions
    private static func estimateFromVolumeDescription(_ text: String) -> Double? {
        // Tablespoon conversions
        if text.contains("tbsp") || text.contains("tablespoon") {
            // Extract number of tablespoons (default 1)
            let count = extractNumber(from: text, pattern: #"(\d+\.?\d*)\s*(?:tbsp|tablespoon)"#) ?? 1.0
            return count * 15.0  // 1 tbsp ≈ 15g
        }
        
        // Teaspoon conversions
        if text.contains("tsp") || text.contains("teaspoon") {
            let count = extractNumber(from: text, pattern: #"(\d+\.?\d*)\s*(?:tsp|teaspoon)"#) ?? 1.0
            return count * 5.0  // 1 tsp ≈ 5g
        }
        
        // Cup conversions
        if text.contains("cup") {
            let count = extractNumber(from: text, pattern: #"(\d+\.?\d*)\s*cup"#) ?? 1.0
            return count * 240.0  // 1 cup ≈ 240g
        }
        
        // Ounce conversions
        if text.contains("oz") {
            let count = extractNumber(from: text, pattern: #"(\d+\.?\d*)\s*oz"#) ?? 1.0
            return count * 28.35  // 1 oz ≈ 28.35g
        }
        
        return nil
    }
}
