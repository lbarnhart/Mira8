import Foundation

// MARK: - Product Profile

/// A scoring profile that defines expectations and rules for a specific product category
struct ProductProfile: Codable {
    let id: String
    let displayName: String

    // Nutritional percentiles (50th percentile = typical, 75th = good, 90th = excellent)
    let nutritionPercentiles: NutritionPercentiles?

    // Macronutrient targets (overrides global thresholds)
    let macronutrientTargets: MacronutrientThresholds?

    // Processing expectations
    let processingExpectations: ProcessingExpectations?

    // Ingredient rules
    let ingredientRules: IngredientRules?

    // Additive tolerance
    let additiveTolerance: AdditiveTolerance?

    // Scoring modifiers
    let scoringModifiers: ScoringModifiers?
}

struct NutritionPercentiles: Codable {
    let calories: PercentileRange?
    let protein: PercentileRange?
    let fiber: PercentileRange?
    let sugar: PercentileRange?
    let sodium: PercentileRange?
    let potassium: PercentileRange?
    let calcium: PercentileRange?
}

struct PercentileRange: Codable {
    let p25: Double  // 25th percentile (below average)
    let p50: Double  // 50th percentile (typical)
    let p75: Double  // 75th percentile (good)
    let p90: Double  // 90th percentile (excellent)
}

struct ProcessingExpectations: Codable {
    let acceptable: [Int]  // Acceptable NOVA levels
    let penaltyMultiplier: Double  // Multiply standard penalty by this
}

struct IngredientRules: Codable {
    let simplicityThreshold: Int?  // ≤ this many ingredients gets bonus
    let simplicityBonus: Double?
    let wholeFoodTokens: [String]?  // Whitelist for simplicity bonus
    let beneficialPatterns: [String]?  // Keywords that provide bonuses
    let problematicPatterns: [String]?  // Keywords that trigger penalties
}

struct AdditiveTolerance: Codable {
    let acceptable: [String]  // Additives that are OK for this profile
    let maxAcceptable: Int  // Max number of acceptable additives before penalty
    let penaltyPerExcess: Double  // Penalty per additive beyond max
}

struct ScoringModifiers: Codable {
    let wholeFruitSugarExemption: Bool?  // Don't penalize sugar if from whole fruit
    let fermentationBonus: Double?  // Bonus for fermented products
    let fortificationBonus: Double?  // Bonus for fortified products (vitamins/minerals)
}

// MARK: - Classification Rules

/// Declarative rules for classifying products into profiles
struct ClassificationRule: Codable {
    let profileId: String
    let priority: Int  // Higher priority wins in case of multiple matches
    let conditions: ClassificationConditions
}

struct ClassificationConditions: Codable {
    // Category/metadata signals
    let categorySlugContains: [String]?
    let categorySlugEquals: String?
    let novaGroup: [Int]?

    // Nutritional thresholds
    let caloriesMax: Double?
    let caloriesMin: Double?
    let sugarMax: Double?
    let proteinMin: Double?

    // Ingredient patterns (all must be present if specified)
    let ingredientsContain: [String]?
    let ingredientsSubsetOf: [String]?  // All ingredients must be in this whitelist
    let ingredientCountMax: Int?

    // Macronutrient ratios
    let fatPercentageMin: Double?  // % of calories from fat
    let proteinPercentageMin: Double?

    // Logical operators
    let anyOf: [ClassificationConditions]?  // OR condition
    let allOf: [ClassificationConditions]?  // AND condition
}

// MARK: - Category Classifier

final class CategoryClassifier {
    private let rules: [ClassificationRule]
    private let profiles: [String: ProductProfile]
    private let defaultProfile: ProductProfile

    init(rules: [ClassificationRule], profiles: [ProductProfile]) {
        self.rules = rules.sorted { $0.priority > $1.priority }
        self.profiles = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })

        // Default profile for products that don't match any rules
        self.defaultProfile = ProductProfile(
            id: "default",
            displayName: "General Food",
            nutritionPercentiles: nil,
            macronutrientTargets: nil,
            processingExpectations: nil,
            ingredientRules: nil,
            additiveTolerance: nil,
            scoringModifiers: nil
        )
    }

    /// Classify a product and return its profile
    func classify(_ product: ProductModel) -> ProductProfile {
        for rule in rules {
            if evaluateConditions(rule.conditions, for: product) {
                return profiles[rule.profileId] ?? defaultProfile
            }
        }
        return defaultProfile
    }

    /// Calculate a percentile-based score (0-100) for a nutrient value
    func percentileScore(value: Double, percentiles: PercentileRange, higherIsBetter: Bool = true) -> Double {
        if higherIsBetter {
            if value >= percentiles.p90 { return 100 }
            if value >= percentiles.p75 { return 85 }
            if value >= percentiles.p50 { return 70 }
            if value >= percentiles.p25 { return 55 }
            return 40
        } else {
            if value <= percentiles.p25 { return 100 }
            if value <= percentiles.p50 { return 85 }
            if value <= percentiles.p75 { return 70 }
            if value <= percentiles.p90 { return 55 }
            return 40
        }
    }

    // MARK: - Private Evaluation

    private func evaluateConditions(_ conditions: ClassificationConditions, for product: ProductModel) -> Bool {
        // Handle logical operators first
        if let anyOf = conditions.anyOf {
            return anyOf.contains { evaluateConditions($0, for: product) }
        }

        if let allOf = conditions.allOf {
            return allOf.allSatisfy { evaluateConditions($0, for: product) }
        }

        // Category checks
        if let contains = conditions.categorySlugContains {
            let slug = product.categorySlug?.lowercased() ?? ""
            let category = product.category?.lowercased() ?? ""
            let matches = contains.contains { pattern in
                slug.contains(pattern.lowercased()) || category.contains(pattern.lowercased())
            }
            if !matches { return false }
        }

        if let equals = conditions.categorySlugEquals {
            let slug = product.categorySlug?.lowercased() ?? ""
            if slug != equals.lowercased() { return false }
        }

        if let novaGroups = conditions.novaGroup {
            let productNova = product.processingLevel.rawValue
            if !novaGroups.contains(productNova) { return false }
        }

        // Nutritional checks
        if let max = conditions.caloriesMax {
            if product.nutrition.calories > max { return false }
        }

        if let min = conditions.caloriesMin {
            if product.nutrition.calories < min { return false }
        }

        if let max = conditions.sugarMax {
            if product.nutrition.sugar > max { return false }
        }

        if let min = conditions.proteinMin {
            if product.nutrition.protein < min { return false }
        }

        // Ingredient checks
        if let contains = conditions.ingredientsContain {
            let ingredientsText = product.ingredients.joined(separator: " ").lowercased()
            let allPresent = contains.allSatisfy { pattern in
                ingredientsText.contains(pattern.lowercased())
            }
            if !allPresent { return false }
        }

        if let subsetOf = conditions.ingredientsSubsetOf {
            let whitelistSet = Set(subsetOf.map { $0.lowercased() })
            let productIngredients = product.ingredients.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }

            let allMatch = productIngredients.allSatisfy { ingredient in
                whitelistSet.contains { whitelistItem in
                    ingredient.contains(whitelistItem)
                }
            }
            if !allMatch { return false }
        }

        if let max = conditions.ingredientCountMax {
            if product.ingredients.count > max { return false }
        }

        // Macronutrient ratio checks
        if let minFatPct = conditions.fatPercentageMin {
            let totalCals = product.nutrition.calories
            if totalCals > 0 {
                let fatCals = product.nutrition.fat * 9
                let fatPct = (fatCals / totalCals) * 100
                if fatPct < minFatPct { return false }
            }
        }

        if let minProteinPct = conditions.proteinPercentageMin {
            let totalCals = product.nutrition.calories
            if totalCals > 0 {
                let proteinCals = product.nutrition.protein * 4
                let proteinPct = (proteinCals / totalCals) * 100
                if proteinPct < minProteinPct { return false }
            }
        }

        return true
    }
}

// MARK: - Scoring Components

/// Reusable scoring components that accept parameters from profile definitions
struct ScoringComponents {

    /// Calculate simplicity bonus based on ingredient count and whole-food tokens
    static func simplicityBonus(
        ingredients: [String],
        threshold: Int,
        bonusPoints: Double,
        wholeFoodTokens: [String]?
    ) -> ScoreAdjustment? {
        guard ingredients.count <= threshold else { return nil }

        // If whitelist is provided, verify all ingredients match
        if let whitelist = wholeFoodTokens {
            let whitelistSet = Set(whitelist.map { $0.lowercased() })
            let allMatch = ingredients.allSatisfy { ingredient in
                let normalized = ingredient.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                return whitelistSet.contains { token in
                    normalized.contains(token)
                }
            }
            guard allMatch else { return nil }
        }

        return ScoreAdjustment(
            label: "Ingredient Simplicity Bonus",
            delta: bonusPoints,
            reason: "Clean formulation with ≤\(threshold) whole-food ingredients"
        )
    }

    /// Calculate fermentation bonus
    static func fermentationBonus(
        ingredients: [String],
        bonusPoints: Double
    ) -> ScoreAdjustment? {
        let fermentationKeywords = ["fermented", "cultured", "probiotics", "live cultures", "active cultures", "kefir", "kombucha"]
        let ingredientsText = ingredients.joined(separator: " ").lowercased()

        let isFermented = fermentationKeywords.contains { keyword in
            ingredientsText.contains(keyword)
        }

        guard isFermented else { return nil }

        return ScoreAdjustment(
            label: "Fermentation Bonus",
            delta: bonusPoints,
            reason: "Contains beneficial fermented/probiotic ingredients"
        )
    }

    /// Calculate fortification bonus based on micronutrient presence
    static func fortificationBonus(
        nutrition: ProductNutrition,
        bonusPoints: Double
    ) -> ScoreAdjustment? {
        var fortifiedCount = 0

        if let calcium = nutrition.calcium, calcium > 100 { fortifiedCount += 1 }
        if let vitaminD = nutrition.vitaminD, vitaminD > 1 { fortifiedCount += 1 }
        if let vitaminB12 = nutrition.vitaminB12, vitaminB12 > 0.5 { fortifiedCount += 1 }
        if let iron = nutrition.iron, iron > 2 { fortifiedCount += 1 }

        guard fortifiedCount >= 2 else { return nil }

        return ScoreAdjustment(
            label: "Fortification Bonus",
            delta: bonusPoints,
            reason: "Fortified with \(fortifiedCount) essential micronutrients"
        )
    }

    /// Check if sugar comes from whole fruit (exemption from penalties)
    static func hasWholeFruitSugar(ingredients: [String]) -> Bool {
        let wholeFruits = [
            "apple", "banana", "orange", "strawberry", "blueberry", "raspberry",
            "mango", "pineapple", "grape", "cherry", "peach", "pear", "date",
            "fig", "plum", "apricot", "kiwi", "watermelon", "cantaloupe"
        ]

        let ingredientsText = ingredients.joined(separator: " ").lowercased()

        // Check for whole fruit mentions without "juice" or "concentrate"
        return wholeFruits.contains { fruit in
            ingredientsText.contains(fruit) &&
            !ingredientsText.contains("\(fruit) juice") &&
            !ingredientsText.contains("\(fruit) concentrate")
        }
    }

    /// Calculate adaptive additive penalty based on profile tolerance
    static func additivesPenalty(
        additives: [String],
        tolerance: AdditiveTolerance
    ) -> ScoreAdjustment? {
        let acceptableSet = Set(tolerance.acceptable.map { $0.lowercased() })
        var acceptableCount = 0
        var problematicCount = 0

        for additive in additives {
            let normalized = additive.lowercased()
            if acceptableSet.contains(where: { normalized.contains($0) }) {
                acceptableCount += 1
            } else {
                problematicCount += 1
            }
        }

        // Penalty if we exceed acceptable additive threshold
        let excessCount = max(0, acceptableCount - tolerance.maxAcceptable)
        let totalPenalty = (Double(excessCount) * tolerance.penaltyPerExcess) + (Double(problematicCount) * tolerance.penaltyPerExcess * 2)

        guard totalPenalty > 0 else { return nil }

        return ScoreAdjustment(
            label: "Additive Complexity Penalty",
            delta: -totalPenalty,
            reason: "\(acceptableCount + problematicCount) additives (\(problematicCount) problematic, \(excessCount) excess acceptable)"
        )
    }
}
