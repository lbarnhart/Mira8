import SwiftUI

/// A quick nutrition snapshot with the full label available on demand.
struct NutritionBreakdownView: View {
    let nutrition: ProductNutrition
    @State private var showFullLabel = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Nutrition")
                .font(.title3.weight(.semibold))

            Text("Per \(nutrition.servingSize)")
                .font(.caption)
                .foregroundColor(.textSubduedAccessible)

            if dynamicTypeSize.isAccessibilitySize {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: Spacing.sm),
                        GridItem(.flexible(), spacing: Spacing.sm)
                    ],
                    spacing: Spacing.md
                ) {
                    nutritionSummary
                }
            } else {
                HStack(spacing: Spacing.sm) {
                    nutritionSummary
                }
            }

            DisclosureGroup(isExpanded: $showFullLabel) {
                VStack(spacing: Spacing.sm) {
                    NutritionRow(name: "Calories", value: nutrition.calories, unit: "")
                    NutritionRow(name: "Protein", value: nutrition.protein, unit: "g")
                    NutritionRow(name: "Carbohydrates", value: nutrition.carbohydrates, unit: "g")
                    NutritionRow(name: "Fat", value: nutrition.fat, unit: "g")
                    NutritionRow(name: "Saturated Fat", value: nutrition.saturatedFat, unit: "g")
                    NutritionRow(name: "Fiber", value: nutrition.fiber, unit: "g")
                    NutritionRow(name: "Sugar", value: nutrition.sugar, unit: "g")
                    NutritionRow(name: "Sodium", value: nutrition.sodiumMilligrams, unit: "mg", precision: 0)
                    NutritionRow(name: "Cholesterol", value: nutrition.cholesterol * 1_000, unit: "mg", precision: 0)
                }
                .padding(.top, Spacing.md)
            } label: {
                Text(showFullLabel ? "Hide full nutrition facts" : "Full nutrition facts")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primaryBlue)
            }
            .accessibilityIdentifier("productDetail.fullNutrition")
        }
        .padding(Spacing.md)
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.card)
    }

    private func summaryValue(_ label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundColor(.textSubduedAccessible)
        }
        .frame(maxWidth: .infinity)
    }

    private func format(_ value: Double) -> String {
        value.rounded() == value ? "\(Int(value))" : String(format: "%.1f", value)
    }

    @ViewBuilder
    private var nutritionSummary: some View {
        summaryValue("Calories", value: "\(Int(nutrition.calories.rounded()))")
        summaryValue("Protein", value: "\(format(nutrition.protein))g")
        summaryValue("Sugar", value: "\(format(nutrition.sugar))g")
        summaryValue("Sodium", value: "\(Int(nutrition.sodiumMilligrams.rounded()))mg")
    }
}

struct NutritionRow: View {
    let name: String
    let value: Double
    let unit: String
    var precision: Int = 1

    var body: some View {
        HStack {
            Text(name)
                .font(.body)
                .foregroundColor(.textPrimary)

            Spacer()

            Text("\(String(format: "%.*f", precision, value))\(unit)")
                .font(.body.weight(.medium))
                .foregroundColor(.textPrimary)
        }
    }
}
