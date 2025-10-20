import Foundation

/// Represents the overall health score for a product with detailed breakdown
struct HealthScore {
    let overall: Double
    let components: ScoreComponents
    let explanation: String
    let focus: HealthFocus
    /// Detailed breakdown showing how each component contributed to the overall score
    let breakdown: [ComponentBreakdown]
    /// All adjustments made during scoring (e.g., heart-health bonuses/penalties)
    let adjustments: [ScoreAdjustment]
    /// Confidence level in the score based on data completeness
    let confidence: ScoreConfidence
    /// Warning message when data is incomplete or limited
    let confidenceWarning: String?
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

struct ScoreBreakdown {
    let component: String
    let score: Double
    let maxScore: Double
    let weight: Double
    let weightedScore: Double
    let explanation: String
    let color: ScoreColor
}

enum ScoreColor {
    case excellent // 80-100
    case good      // 60-79
    case fair      // 40-59
    case poor      // 0-39

    static func from(score: Double) -> ScoreColor {
        switch score {
        case 80...100:
            return .excellent
        case 60..<80:
            return .good
        case 40..<60:
            return .fair
        default:
            return .poor
        }
    }
}