import Foundation

/// AI-powered ingredient analysis result from Claude API.
/// This provides research-backed context personalized to the user's health focus.
struct AIIngredientAnalysis: Codable, Equatable {
    let ingredientName: String
    let healthFocus: String
    let safetyRating: SafetyRating
    let summary: String
    let detailedExplanation: String
    let researchContext: String?
    let relevantRestrictions: [String]
    let alternatives: [String]?
    let confidence: Double

    enum SafetyRating: String, Codable, CaseIterable {
        case safe
        case caution
        case avoid

        var displayName: String {
            rawValue.capitalized
        }

        var iconName: String {
            switch self {
            case .safe: return "checkmark.circle.fill"
            case .caution: return "exclamationmark.triangle.fill"
            case .avoid: return "xmark.circle.fill"
            }
        }
    }
}
