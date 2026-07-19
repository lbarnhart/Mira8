import SwiftUI

struct IngredientItem: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let displayName: String
    let category: IngredientCategory
    let explanation: String
    let position: Int

    init(analysis: IngredientAnalysis) {
        self.name = analysis.originalName
        self.displayName = analysis.displayName
        self.category = analysis.category
        self.explanation = analysis.explanation
        self.position = analysis.position
    }

    var accentColor: Color { category.accentColor }
    var backgroundColor: Color { category.backgroundColor }
    var iconName: String { category.iconName }
    var categoryLabel: String { category.displayLabel }
    var typicalUse: String { category.typicalUse }
    var healthImpact: String { category.healthImpact }

    var isSignificantAmount: Bool { position <= 5 }

    var positionText: String {
        if position == 1 {
            return "Primary ingredient"
        }
        return "\(position.ordinalString) ingredient"
    }
}

extension IngredientCategory {
    var accentColor: Color {
        switch self {
        case .beneficial:
            return Color.green
        case .neutral:
            return Color.gray
        case .concerning:
            return Color.orange
        case .unknown:
            return Color.textTertiary
        }
    }

    var backgroundColor: Color {
        switch self {
        case .beneficial:
            return Color.green.opacity(0.12)
        case .neutral:
            return Color.gray.opacity(0.12)
        case .concerning:
            return Color.orange.opacity(0.14)
        case .unknown:
            return Color.textTertiary.opacity(0.1)
        }
    }

    var iconName: String {
        switch self {
        case .beneficial:
            return "checkmark.circle.fill"
        case .neutral:
            return "info.circle"
        case .concerning:
            return "exclamationmark.triangle.fill"
        case .unknown:
            return "questionmark.circle"
        }
    }

    var displayLabel: String {
        switch self {
        case .beneficial:
            return "Beneficial"
        case .neutral:
            return "Neutral"
        case .concerning:
            return "Concerning"
        case .unknown:
            return "Needs Review"
        }
    }

    var typicalUse: String {
        switch self {
        case .beneficial:
            return "Often added for nutritional benefits or natural quality."
        case .neutral:
            return "Common ingredient used for flavor, texture, or preservation."
        case .concerning:
            return "May be added for sweetness, color, or shelf life; monitor intake."
        case .unknown:
            return "Insufficient data about this ingredient."
        }
    }

    var healthImpact: String {
        switch self {
        case .beneficial:
            return "May contribute useful nutrients or whole-food qualities. The amount present and the overall product still matter."
        case .neutral:
            return "Commonly used in foods. Individual tolerance, amount, and the overall product still matter."
        case .concerning:
            return "Mira flags this as an ingredient to review, not as a safety diagnosis. Risk depends on amount, frequency, and individual sensitivity."
        case .unknown:
            return "Mira does not have enough reliable context to classify this ingredient. Check the package and a qualified source if it matters to you."
        }
    }
}

extension Int {
    var ordinalString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)th"
    }
}
