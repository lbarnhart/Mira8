import SwiftUI

struct DietaryRestrictionBadge: View {
    let result: DietaryRestrictionResult

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundColor(iconColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(statusText)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(textColor)

                if let passes = result.passes {
                    if let detailText = detailText(for: passes) {
                        Text(detailText)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                } else {
                    Text("Cannot verify - ingredient data unavailable")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .italic()
                }
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(backgroundColor)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private var statusText: String {
        guard let passes = result.passes else {
            return "⚠️ \(result.restriction) - Unknown"
        }

        if passes {
            return "✓ \(result.restriction)"
        }

        return "✗ \(result.reason)"
    }

    private func detailText(for passes: Bool) -> String? {
        if passes {
            return result.reason
        }

        return "Violates \(result.restriction) restriction"
    }

    private var iconName: String {
        guard let passes = result.passes else {
            return "questionmark.circle.fill"
        }
        return passes ? "checkmark.circle.fill" : "xmark.circle.fill"
    }

    private var iconColor: Color {
        guard let passes = result.passes else {
            return .orange
        }
        return passes ? .scoreExcellent : .scorePoor
    }

    private var textColor: Color {
        guard let passes = result.passes else {
            return .orange
        }
        return passes ? .scoreExcellent : .scorePoor
    }

    private var backgroundColor: Color {
        guard let passes = result.passes else {
            return Color.orange.opacity(0.12)
        }
        return passes ? Color.scoreExcellent.opacity(0.12) : Color.scorePoor.opacity(0.12)
    }

    private var borderColor: Color {
        guard let passes = result.passes else {
            return Color.orange.opacity(0.35)
        }
        return passes ? Color.scoreExcellent.opacity(0.35) : Color.scorePoor.opacity(0.35)
    }
}

#Preview {
    VStack(spacing: Spacing.sm) {
        DietaryRestrictionBadge(
            result: DietaryRestrictionResult(
                restriction: "Vegan",
                passes: true,
                reason: "No animal-derived ingredients detected"
            )
        )

        DietaryRestrictionBadge(
            result: DietaryRestrictionResult(
                restriction: "Gluten-Free",
                passes: false,
                reason: "Contains Wheat"
            )
        )

        DietaryRestrictionBadge(
            result: DietaryRestrictionResult(
                restriction: "Nut-Free",
                passes: nil,
                reason: "Ingredient data not available"
            )
        )
    }
    .padding()
    .background(Color.backgroundPrimary)
}
