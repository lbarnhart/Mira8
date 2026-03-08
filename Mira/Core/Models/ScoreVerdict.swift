import Foundation

/// NutriScore verdict based on A-E grading system
enum NutriScoreVerdict: String, Codable {
    case excellent = "A"  // NutriScore A
    case good = "B"       // NutriScore B
    case fair = "C"       // NutriScore C
    case poor = "D"       // NutriScore D
    case avoid = "E"      // NutriScore E
    case unknown = "?"    // Unknown/unavailable

    var displayName: String {
        switch self {
        case .excellent: return "A"
        case .good: return "B"
        case .fair: return "C"
        case .poor: return "D"
        case .avoid: return "E"
        case .unknown: return "?"
        }
    }

    var displayLabel: String {
        displayName
    }

    /// Initialize from NutriScore string (A, B, C, D, E, or empty/unknown)
    init(from nutriScore: String) {
        switch nutriScore.uppercased() {
        case "A": self = .excellent
        case "B": self = .good
        case "C": self = .fair
        case "D": self = .poor
        case "E": self = .avoid
        default: self = .unknown
        }
    }
}

/// Simple, user-friendly verdict for grocery store decision-making
enum ScoreVerdict: String, Codable {
    case excellent  // 85-100
    case good       // 70-84
    case okay       // 55-69
    case fair       // 40-54
    case avoid      // 0-39
    
    /// Initialize verdict from a score value (0-100 scale)
    init(score: Double) {
        switch score {
        case 85...100:
            self = .excellent
        case 70..<85:
            self = .good
        case 55..<70:
            self = .okay
        case 40..<55:
            self = .fair
        default:
            self = .avoid
        }
    }
    
    /// Short, actionable message for quick decisions
    /// Uses positive, anxiety-reducing language
    var message: String {
        switch self {
        case .excellent:
            return "Great choice!"
        case .good:
            return "Solid option for your goals"
        case .okay:
            return "Good choice! See alternatives for even better options"
        case .fair:
            return "Okay in moderation. For better fits, check alternatives below"
        case .avoid:
            return "Not the best fit for your goals. Let's find a better match"
        }
    }
    
    /// Display label (neutral, non-judgmental)
    var label: String {
        switch self {
        case .excellent:
            return "Excellent"
        case .good:
            return "Good"
        case .okay:
            return "Okay"
        case .fair:
            return "Fair"
        case .avoid:
            return "Poor" // Less judgmental than "Avoid"
        }
    }
    
    /// Emoji for visual feedback
    var emoji: String {
        switch self {
        case .excellent:
            return "⭐"
        case .good:
            return "✓"
        case .okay:
            return "~"
        case .fair:
            return "⚠"
        case .avoid:
            return "✗"
        }
    }
    
    /// Color indicator for traffic light system
    var colorName: String {
        switch self {
        case .excellent:
            return "green"
        case .good:
            return "lightGreen"
        case .okay:
            return "yellow"
        case .fair:
            return "orange"
        case .avoid:
            return "red"
        }
    }
    
    /// SF Symbol name for icon
    var systemIcon: String {
        switch self {
        case .excellent:
            return "star.fill"
        case .good:
            return "checkmark.circle.fill"
        case .okay:
            return "minus.circle.fill"
        case .fair:
            return "exclamationmark.triangle.fill"
        case .avoid:
            return "xmark.circle.fill"
        }
    }
}

// MARK: - Nutriscore Conversion
extension ScoreVerdict {
    /// Convert from NutriScoreVerdict to ScoreVerdict
    init(from nutriScoreVerdict: NutriScoreVerdict) {
        switch nutriScoreVerdict {
        case .excellent:
            self = .excellent
        case .good:
            self = .good
        case .fair:
            self = .fair  // Map "Fair" (C) to "Fair" (not "okay")
        case .poor:
            self = .avoid  // Map "Poor" (D) to "Avoid"
        case .avoid:
            self = .avoid
        case .unknown:
            self = .fair  // Default to fair for unknown
        }
    }
}



