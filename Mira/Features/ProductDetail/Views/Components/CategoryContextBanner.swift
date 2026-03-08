import SwiftUI

/// Banner that displays category-specific context for foods like cheese, meat, nuts, etc.
/// Reduces unfair scoring penalties by explaining why certain nutrients are naturally higher
struct CategoryContextBanner: View {
    let context: CategoryContext

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Text(context.icon)
                .font(.title2)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Category Context")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)
                    .textCase(.uppercase)

                Text(context.message)
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(backgroundColor)
        .cornerRadius(CornerRadius.card)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .strokeBorder(borderColor, lineWidth: 1)
        )
    }

    private var backgroundColor: Color {
        switch context.type {
        case .positive:
            return Color.green.opacity(0.08)
        case .neutral:
            return Color.blue.opacity(0.08)
        case .informational:
            return Color.gray.opacity(0.08)
        }
    }

    private var borderColor: Color {
        switch context.type {
        case .positive:
            return Color.green.opacity(0.2)
        case .neutral:
            return Color.blue.opacity(0.2)
        case .informational:
            return Color.gray.opacity(0.2)
        }
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        CategoryContextBanner(
            context: CategoryContext(
                icon: "🧀",
                message: "For cheese: Naturally higher in saturated fat, which is expected. This cheese is an excellent protein source (8.0g) and rich in calcium.",
                type: .neutral
            )
        )

        CategoryContextBanner(
            context: CategoryContext(
                icon: "🥜",
                message: "For nuts: Higher calories are expected and come from healthy fats. The fats in nuts are mostly unsaturated (heart-healthy). Nuts provide essential nutrients, fiber, and sustained energy.",
                type: .positive
            )
        )

        CategoryContextBanner(
            context: CategoryContext(
                icon: "🦠",
                message: "For fermented foods: Contains beneficial bacteria (probiotics) that support gut health. Fermentation improves nutrient bioavailability and digestive benefits.",
                type: .positive
            )
        )
    }
    .padding()
}
