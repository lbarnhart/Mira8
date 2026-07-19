import SwiftUI

/// Displays nutrition facts in a card layout
struct NutritionBreakdownView: View {
    let nutrition: ProductNutrition

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition Facts")
                .font(.title3)
                .fontWeight(.semibold)

            HStack {
                Text("Serving Size:")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Text(nutrition.servingSize)
                    .font(.caption)
                    .foregroundColor(.textPrimary)
            }

            VStack(spacing: 8) {
                NutritionRow(name: "Calories", value: nutrition.calories, unit: "")
                NutritionRow(name: "Protein", value: nutrition.protein, unit: "g")
                NutritionRow(name: "Carbohydrates", value: nutrition.carbohydrates, unit: "g")
                NutritionRow(name: "Fat", value: nutrition.fat, unit: "g")
                NutritionRow(name: "Fiber", value: nutrition.fiber, unit: "g")
                NutritionRow(name: "Sugar", value: nutrition.sugar, unit: "g")
                NutritionRow(name: "Sodium", value: nutrition.sodiumMilligrams, unit: "mg")
                NutritionRow(name: "Cholesterol", value: nutrition.cholesterol * 1000, unit: "mg", precision: 0)
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
}

/// Single row in nutrition facts
struct NutritionRow: View {
    let name: String
    let value: Double
    let unit: String
    var precision: Int = 1

    var body: some View {
        let formattedValue = String(format: "%.*f", precision, value)

        HStack {
            Text(name)
                .font(.bodyMedium)
                .foregroundColor(.textPrimary)

            Spacer()

            Text("\(formattedValue)\(unit)")
                .font(.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
        }
    }
}

#Preview {
    NutritionBreakdownView(
        nutrition: ProductNutrition(
            calories: 150,
            protein: 5,
            carbohydrates: 25,
            fat: 4,
            fiber: 3,
            sugar: 12,
            sodium: 0.15,
            cholesterol: 0.01,
            servingSize: "100g"
        )
    )
    .padding()
}
