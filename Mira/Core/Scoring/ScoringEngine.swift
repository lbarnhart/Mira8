import Foundation

enum ScoringConfigurationError: Error {
    case fileNotFound
    case invalidConfiguration
    case missingHealthFocus(String)

    var localizedDescription: String {
        switch self {
        case .fileNotFound:
            return "Scoring configuration file not found"
        case .invalidConfiguration:
            return "Invalid scoring configuration format"
        case .missingHealthFocus(let focus):
            return "Missing configuration for health focus: \(focus)"
        }
    }
}

final class ScoringEngine {
    static let shared = ScoringEngine()

    private let config: ScoringConfiguration
    private let healthFocusScorer: HealthFocusScorer

    private init() {
        do {
            self.config = try ScoringEngine.loadConfiguration()
        } catch {
            AppLog.warning("Failed to load scoring configuration, using defaults: \(error.localizedDescription)", category: .scoring)
            self.config = ScoringConfiguration.defaultConfiguration
        }
        self.healthFocusScorer = HealthFocusScorer(config: config)
    }

    func calculateHealthScore(
        for product: ProductModel,
        healthFocus: HealthFocus,
        dietaryRestrictions: [DietaryRestriction]
    ) -> HealthScore {
        AppLog.debug("Calculating score for \(product.name) with focus \(healthFocus.rawValue)", category: .scoring)
        let n = product.nutrition
        if n.calories <= 0 && n.protein == 0 && n.fiber == 0 && n.sugar == 0 && n.sodium == 0 {
            AppLog.warning("Nutrition appears incomplete or zero for \(product.name)", category: .scoring)
        } else {
            let cholesterolMg = (n.cholesterol * 1000).rounded()
            AppLog.debug("Nutrition - cals: \(n.calories), protein: \(n.protein), fiber: \(n.fiber), sugar: \(n.sugar), sodium: \(n.sodium), cholesterol: \(cholesterolMg)mg", category: .scoring)
        }
        return healthFocusScorer.calculateScore(
            for: product,
            focus: healthFocus,
            dietaryRestrictions: dietaryRestrictions
        )
    }

    func checkDietaryViolations(
        ingredients: [String],
        restrictions: [DietaryRestriction]
    ) -> [DietaryRestriction] {
        var violations: [DietaryRestriction] = []

        for restriction in restrictions {
            let violatingIngredients = config.dietaryViolations[restriction.rawValue] ?? []

            for ingredient in ingredients {
                let cleanIngredient = ingredient.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

                if violatingIngredients.contains(where: { violating in
                    cleanIngredient.contains(violating.lowercased())
                }) {
                    violations.append(restriction)
                    break
                }
            }
        }

        return violations
    }

    private static func loadConfiguration() throws -> ScoringConfiguration {
        guard let url = Bundle.main.url(forResource: "ScoringConfig", withExtension: "json") else {
            throw ScoringConfigurationError.fileNotFound
        }

        let data = try Data(contentsOf: url)
        let config = try JSONDecoder().decode(ScoringConfiguration.self, from: data)

        try config.validate()
        return config
    }
}

struct ScoringConfiguration: Codable {
    let healthFocusWeights: [String: ComponentWeights]
    let macronutrientThresholds: MacronutrientThresholds
    let processingLevelScores: [String: Int]
    let harmfulAdditives: [String]
    let beneficialIngredients: [String]
    let dietaryViolations: [String: [String]]

    func validate() throws {
        let requiredHealthFocuses = ["gut_health", "weight_loss", "protein_focus", "general_wellness", "heart_health"]
        for focus in requiredHealthFocuses {
            guard healthFocusWeights[focus] != nil else {
                throw ScoringConfigurationError.missingHealthFocus(focus)
            }
        }

        for (_, weights) in healthFocusWeights {
            let totalWeight = weights.macronutrientBalance + weights.micronutrientDensity +
                             weights.processingLevel + weights.ingredientQuality + weights.additives
            guard abs(totalWeight - 1.0) < 0.001 else {
                throw ScoringConfigurationError.invalidConfiguration
            }
        }
    }

    static var defaultConfiguration: ScoringConfiguration {
        return ScoringConfiguration(
            healthFocusWeights: [
                "general_wellness": ComponentWeights(
                    macronutrientBalance: 0.25,
                    micronutrientDensity: 0.2,
                    processingLevel: 0.2,
                    ingredientQuality: 0.2,
                    additives: 0.15
                ),
                "gut_health": ComponentWeights(
                    macronutrientBalance: 0.2,
                    micronutrientDensity: 0.15,
                    processingLevel: 0.25,
                    ingredientQuality: 0.25,
                    additives: 0.15
                ),
                "weight_loss": ComponentWeights(
                    macronutrientBalance: 0.3,
                    micronutrientDensity: 0.2,
                    processingLevel: 0.2,
                    ingredientQuality: 0.15,
                    additives: 0.15
                ),
                "protein_focus": ComponentWeights(
                    macronutrientBalance: 0.4,
                    micronutrientDensity: 0.15,
                    processingLevel: 0.15,
                    ingredientQuality: 0.15,
                    additives: 0.15
                ),
                "heart_health": ComponentWeights(
                    macronutrientBalance: 0.35,
                    micronutrientDensity: 0.2,
                    processingLevel: 0.15,
                    ingredientQuality: 0.2,
                    additives: 0.1
                )
            ],
            macronutrientThresholds: MacronutrientThresholds(
                protein: NutrientThreshold(excellent: 20, good: 10, fair: 5, poor: 0),
                fiber: NutrientThreshold(excellent: 6, good: 3, fair: 1, poor: 0),
                sugar: NutrientThreshold(excellent: 5, good: 10, fair: 15, poor: 100),
                sodium: NutrientThreshold(excellent: 0.3, good: 0.6, fair: 1.2, poor: 10),
                saturatedFat: NutrientThreshold(excellent: 2, good: 5, fair: 8, poor: 100)
            ),
            processingLevelScores: ["1": 100, "2": 80, "3": 60, "4": 30],
            harmfulAdditives: [
                "monosodium glutamate", "high fructose corn syrup", "artificial colors",
                "artificial flavors", "sodium nitrate", "trans fat"
            ],
            beneficialIngredients: [
                "organic", "whole grain", "probiotics", "fiber", "omega-3", "natural"
            ],
            dietaryViolations: [
                "vegan": ["milk", "cheese", "meat", "eggs", "honey"],
                "vegetarian": ["meat", "fish", "gelatin"],
                "gluten_free": ["wheat", "barley", "rye", "gluten"],
                "dairy_free": ["milk", "cheese", "butter", "whey"],
                "nut_free": ["peanuts", "tree nuts", "almonds", "walnuts"]
            ]
        )
    }
}

struct ComponentWeights: Codable {
    let macronutrientBalance: Double
    let micronutrientDensity: Double
    let processingLevel: Double
    let ingredientQuality: Double
    let additives: Double
}

struct MacronutrientThresholds: Codable {
    let protein: NutrientThreshold
    let fiber: NutrientThreshold
    let sugar: NutrientThreshold
    let sodium: NutrientThreshold
    let saturatedFat: NutrientThreshold
}

struct NutrientThreshold: Codable {
    let excellent: Double
    let good: Double
    let fair: Double
    let poor: Double

    func getScore(for value: Double, isLowerBetter: Bool = false) -> Double {
        if isLowerBetter {
            if value <= excellent { return 100 }
            if value <= good { return 80 }
            if value <= fair { return 60 }
            return 40
        } else {
            if value >= excellent { return 100 }
            if value >= good { return 80 }
            if value >= fair { return 60 }
            return 40
        }
    }

    func getExplanation(for value: Double, nutrientName: String, isLowerBetter: Bool = false) -> String {
        let score = getScore(for: value, isLowerBetter: isLowerBetter)

        switch score {
        case 100:
            return isLowerBetter ?
                "\(nutrientName) content is excellent (very low)" :
                "\(nutrientName) content is excellent (high)"
        case 80:
            return isLowerBetter ?
                "\(nutrientName) content is good (low)" :
                "\(nutrientName) content is good"
        case 60:
            return isLowerBetter ?
                "\(nutrientName) content is fair (moderate)" :
                "\(nutrientName) content is fair"
        default:
            return isLowerBetter ?
                "\(nutrientName) content is high (concerning)" :
                "\(nutrientName) content is low"
        }
    }
}
