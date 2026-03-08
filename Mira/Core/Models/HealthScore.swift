import Foundation

/// Represents the overall health score for a product with detailed breakdown
struct HealthScore {
    let rawScore: Double
    let overall: Double
    let tier: ScoreTier
    let grade: ScoreGrade
    let explanation: String
    let confidence: ScoreConfidence
    let confidenceWarning: String?
    let confidenceRange: ClosedRange<Double>
    let rawPositivePoints: Double
    let rawNegativePoints: Double
    let weightedPositivePoints: Double
    let weightedNegativePoints: Double
    let contributions: [NutrientContribution]
    let breakdown: [ComponentBreakdown]
    let adjustments: [ScoreAdjustment]
    let topReasons: [String]
    let uxMessages: [String]
    let components: ScoreComponents
    let scoringResult: ScoringResult?
    let verdict: ScoreVerdict
    let simplifiedDisplay: SimplifiedScoreDisplay
    let categoryPercentile: Double?
    let categoryRank: String?
    let nutriScoreVerdict: NutriScoreVerdict
}

struct ScoreComponents {
    let macronutrientBalance: ComponentScore
    let micronutrientDensity: ComponentScore
    let processingLevel: ComponentScore
    let ingredientQuality: ComponentScore
    let additives: ComponentScore
}

struct ComponentScore {
    let score: Double
    let weight: Double
    let explanation: String
    let recommendations: [String]
}

/// Detailed breakdown of a scoring component's contribution
struct ComponentBreakdown {
    let componentName: String
    let rawScore: Double
    let weight: Double
    let weightedScore: Double
    let explanation: String
    let keyFactors: [String]
}

/// Represents an adjustment made to the score with explanation
struct ScoreAdjustment {
    let label: String
    let delta: Double
    let reason: String
}

/// Confidence level based on data completeness
enum ScoreConfidence: String {
    case high = "high"
    case medium = "medium"
    case low = "low"

    var displayName: String {
        switch self {
        case .high:
            return "High Confidence"
        case .medium:
            return "Medium Confidence"
        case .low:
            return "Low Confidence"
        }
    }
}

/// Contribution from a specific nutrient to the health score
struct NutrientContribution: Codable, Identifiable {
    enum Kind: String, Codable {
        case positive
        case negative
    }

    enum Nutrient: String, Codable {
        case energy
        case sugars
        case saturatedFat
        case sodium
        case fiber
        case protein
        case fruitVegLegumeNut
    }

    var id: String { "\(nutrient.rawValue)_\(label)" }

    let kind: Kind
    let nutrient: Nutrient
    let label: String
    let rawPoints: Int
    let maxPoints: Int
    let weight: Double
    let weightedPoints: Double
    let value: Double?
    let unit: String
    let explanation: String
    let guideline: String
    let dataAvailable: Bool
    let modifiers: [String]
}

extension ScoreComponents {
    static var empty: ScoreComponents {
        ScoreComponents(
            macronutrientBalance: ComponentScore(score: 0, weight: 0, explanation: "", recommendations: []),
            micronutrientDensity: ComponentScore(score: 0, weight: 0, explanation: "", recommendations: []),
            processingLevel: ComponentScore(score: 0, weight: 0, explanation: "", recommendations: []),
            ingredientQuality: ComponentScore(score: 0, weight: 0, explanation: "", recommendations: []),
            additives: ComponentScore(score: 0, weight: 0, explanation: "", recommendations: [])
        )
    }
}