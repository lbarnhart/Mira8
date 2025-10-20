import Foundation

/// Evidence-based nutrition guidelines from authoritative health organizations
/// Used to ground scoring adjustments in explicit health recommendations
struct NutritionGuidelines {

    // MARK: - Heart Health Guidelines

    /// American Heart Association (AHA) recommendations for cardiovascular health
    struct HeartHealth {
        /// AHA recommends <300mg cholesterol per day for general population
        static let cholesterolDailyLimit: Double = 300 // mg

        /// AHA recommends <200mg cholesterol per day for those at risk
        static let cholesterolHighRiskLimit: Double = 200 // mg

        /// Per-serving thresholds (assuming 3 servings per day)
        static let cholesterolExcellent: Double = 0 // mg - cholesterol-free
        static let cholesterolGood: Double = 50 // mg - low cholesterol
        static let cholesterolModerate: Double = 100 // mg - moderate cholesterol

        /// AHA recommends ≤1.5g (1500mg) sodium per day
        static let sodiumDailyLimit: Double = 1.5 // g

        /// Per-serving sodium thresholds (assuming 3 servings per day)
        static let sodiumExcellent: Double = 0.3 // g per serving (300mg)
        static let sodiumGood: Double = 0.6 // g per serving (600mg)
        static let sodiumFair: Double = 1.2 // g per serving (1200mg)

        /// AHA recommends <6% of calories from saturated fat
        static let saturatedFatPercentageLimit: Double = 6.0

        /// Per-serving saturated fat thresholds
        static let saturatedFatExcellent: Double = 2 // g
        static let saturatedFatGood: Double = 5 // g
        static let saturatedFatFair: Double = 8 // g

        /// Heart-friendly ingredients backed by research
        static let heartFriendlyIngredients = [
            "oat", "oats", "flax", "chia", "walnut", "almond", "avocado",
            "olive oil", "canola oil", "sunflower oil", "pumpkin seed", "sunflower seed",
            "quinoa", "lentil", "bean", "beans", "black bean", "chickpea",
            "pea protein", "soy protein", "tofu", "tempeh", "edamame", "omega"
        ]

        static let cholesterolGuideline = "AHA recommends limiting cholesterol intake; ideally <100mg per serving"
        static let sodiumGuideline = "AHA recommends ≤1.5g sodium per day; this translates to ~500mg per serving"
        static let saturatedFatGuideline = "AHA recommends <6% of calories from saturated fat"
        static let heartFriendlyGuideline = "Contains ingredients associated with cardiovascular benefits"
    }

    // MARK: - Fiber Guidelines

    /// FDA and dietary guideline recommendations for fiber
    struct Fiber {
        /// FDA Daily Value for fiber
        static let dailyValue: Double = 28 // g

        /// Per-serving thresholds (based on 3 servings per day)
        static let excellent: Double = 6 // g - provides >20% DV
        static let good: Double = 3 // g - provides >10% DV
        static let fair: Double = 1 // g - provides >3% DV

        static let guideline = "FDA recommends 28g fiber per day; aim for ≥3g per serving"
    }

    // MARK: - Protein Guidelines

    /// Protein recommendations for general population
    struct Protein {
        /// RDA for protein (varies by body weight, using average)
        static let dailyValue: Double = 50 // g (FDA DV)

        /// Per-serving thresholds for protein content
        static let excellent: Double = 20 // g - high protein
        static let good: Double = 10 // g - good protein source
        static let fair: Double = 5 // g - moderate protein

        static let guideline = "FDA Daily Value is 50g protein; aim for ≥10g per serving"
    }

    // MARK: - Sugar Guidelines

    /// WHO and AHA sugar recommendations
    struct Sugar {
        /// WHO recommends <10% of calories from free sugars (~50g for 2000 cal diet)
        static let dailyLimit: Double = 50 // g

        /// AHA stricter recommendation: <25g added sugar per day for women, <36g for men
        static let ahaLimit: Double = 25 // g (using more conservative value)

        /// Per-serving thresholds (assuming 3 servings per day)
        static let excellent: Double = 5 // g - low sugar
        static let good: Double = 10 // g - moderate sugar
        static let fair: Double = 15 // g - higher sugar

        static let guideline = "WHO/AHA recommend limiting added sugars; ideally <10g per serving"
    }

    // MARK: - Micronutrient Guidelines

    /// Micronutrient density scoring based on % Daily Value
    struct Micronutrients {
        /// Percentage of DV that qualifies as "excellent source"
        static let excellentSourceThreshold: Double = 20.0 // 20% DV

        /// Percentage of DV that qualifies as "good source"
        static let goodSourceThreshold: Double = 10.0 // 10% DV

        /// Minimum number of micronutrients to consider data "complete"
        static let minimumForFullConfidence: Int = 5

        static let guideline = "FDA defines 'excellent source' as ≥20% DV, 'good source' as ≥10% DV"

        // FDA Daily Values for adults (used to calculate % DV)
        static let vitaminADV: Double = 900 // mcg
        static let vitaminCDV: Double = 90 // mg
        static let vitaminDDV: Double = 20 // mcg
        static let vitaminEDV: Double = 15 // mg
        static let vitaminKDV: Double = 120 // mcg
        static let thiaminDV: Double = 1.2 // mg
        static let riboflavinDV: Double = 1.3 // mg
        static let niacinDV: Double = 16 // mg
        static let vitaminB6DV: Double = 1.7 // mg
        static let folateDV: Double = 400 // mcg
        static let vitaminB12DV: Double = 2.4 // mcg
        static let calciumDV: Double = 1300 // mg
        static let ironDV: Double = 18 // mg
        static let magnesiumDV: Double = 420 // mg
        static let phosphorusDV: Double = 1250 // mg
        static let potassiumDV: Double = 4700 // mg
        static let zincDV: Double = 11 // mg
    }

    /// Represents a micronutrient with its value and % Daily Value
    struct MicronutrientInfo {
        let name: String
        let amount: Double
        let unit: String
        let percentDV: Double
        let dailyValue: Double

        var displayString: String {
            return "\(name): \(Int(percentDV))% DV"
        }
    }

    // MARK: - Processing Levels

    /// NOVA food classification system for processing levels
    struct Processing {
        static let guideline = "Based on NOVA classification: minimize ultra-processed foods (Group 4)"

        static let novaGroup1 = "Unprocessed or minimally processed foods"
        static let novaGroup2 = "Processed culinary ingredients"
        static let novaGroup3 = "Processed foods"
        static let novaGroup4 = "Ultra-processed foods"
    }

    // MARK: - Scoring Adjustments

    /// Standardized adjustment values for score modifications
    struct Adjustments {
        // Heart health adjustments
        static let cholesterolHighPenalty: Double = -15 // >100mg
        static let cholesterolModeratePenalty: Double = -8 // 50-100mg
        static let cholesterolLowBonus: Double = 5 // 0-50mg
        static let cholesterolFreeBonus: Double = 5 // 0mg
        static let heartFriendlyBonus: Double = 3 // contains heart-healthy ingredients

        // General adjustments
        static let beneficialIngredientBonus: Double = 2
        static let harmfulAdditivePerItemPenalty: Double = 20
        static let totalAdditivePerItemPenalty: Double = 5
        static let longIngredientListPenaltyPerItem: Double = 2
        static let longIngredientListThreshold: Int = 10
    }

    // MARK: - Data Completeness Thresholds

    /// Thresholds for determining score confidence based on data availability
    struct DataCompleteness {
        /// Minimum number of non-zero macronutrients for high confidence
        static let minMacronutrientsForHighConfidence: Int = 4

        /// Minimum number of ingredients for high confidence
        static let minIngredientsForHighConfidence: Int = 3

        /// Percentage of expected data fields that should be present
        static let dataCompletenessThreshold: Double = 0.7 // 70%
    }
}

// MARK: - Helper Extensions

extension NutritionGuidelines.HeartHealth {
    /// Get explanation for cholesterol level
    static func getCholesterolExplanation(milligrams: Double) -> String {
        if milligrams > cholesterolModerate {
            return "High cholesterol (\(Int(milligrams))mg); \(cholesterolGuideline)"
        } else if milligrams > cholesterolGood {
            return "Moderate cholesterol (\(Int(milligrams))mg); \(cholesterolGuideline)"
        } else if milligrams > 0 {
            return "Low cholesterol (\(Int(milligrams))mg); heart-friendly amount"
        } else {
            return "Cholesterol-free; excellent for heart health"
        }
    }

    /// Get explanation for sodium level
    static func getSodiumExplanation(grams: Double) -> String {
        let milligrams = Int(grams * 1000)
        if grams <= sodiumExcellent {
            return "Excellent sodium level (\(milligrams)mg); \(sodiumGuideline)"
        } else if grams <= sodiumGood {
            return "Good sodium level (\(milligrams)mg); \(sodiumGuideline)"
        } else if grams <= sodiumFair {
            return "Moderate sodium (\(milligrams)mg); \(sodiumGuideline)"
        } else {
            return "High sodium (\(milligrams)mg); exceeds recommended limit. \(sodiumGuideline)"
        }
    }
}

extension NutritionGuidelines.Fiber {
    /// Get fiber content explanation
    static func getFiberExplanation(grams: Double) -> String {
        if grams >= excellent {
            return "Excellent fiber content (\(grams.formatted(.number.precision(.fractionLength(0...1))))g); \(guideline)"
        } else if grams >= good {
            return "Good fiber content (\(grams.formatted(.number.precision(.fractionLength(0...1))))g); \(guideline)"
        } else if grams >= fair {
            return "Fair fiber content (\(grams.formatted(.number.precision(.fractionLength(0...1))))g); could be improved"
        } else {
            return "Low fiber (\(grams.formatted(.number.precision(.fractionLength(0...1))))g); \(guideline)"
        }
    }
}

extension NutritionGuidelines.Protein {
    /// Get protein content explanation
    static func getProteinExplanation(grams: Double) -> String {
        if grams >= excellent {
            return "Excellent protein content (\(grams.formatted(.number.precision(.fractionLength(0...1))))g); \(guideline)"
        } else if grams >= good {
            return "Good protein content (\(grams.formatted(.number.precision(.fractionLength(0...1))))g); \(guideline)"
        } else if grams >= fair {
            return "Fair protein content (\(grams.formatted(.number.precision(.fractionLength(0...1))))g); could be improved"
        } else {
            return "Low protein (\(grams.formatted(.number.precision(.fractionLength(0...1))))g); \(guideline)"
        }
    }
}

extension NutritionGuidelines.Sugar {
    /// Get sugar content explanation
    static func getSugarExplanation(grams: Double) -> String {
        if grams <= excellent {
            return "Excellent sugar level (\(grams.formatted(.number.precision(.fractionLength(0...1))))g); \(guideline)"
        } else if grams <= good {
            return "Good sugar level (\(grams.formatted(.number.precision(.fractionLength(0...1))))g); \(guideline)"
        } else if grams <= fair {
            return "Moderate sugar (\(grams.formatted(.number.precision(.fractionLength(0...1))))g); \(guideline)"
        } else {
            return "High sugar (\(grams.formatted(.number.precision(.fractionLength(0...1))))g); exceeds recommendation. \(guideline)"
        }
    }
}
