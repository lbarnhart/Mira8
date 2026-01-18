import SwiftUI

struct ProductNutritionView: View {
    let nutrition: ProductNutrition

    // Sodium is stored in grams, convert to mg for display and thresholds
    private var sodiumInMg: Double {
        nutrition.sodium * 1000
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Serving Info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Nutrition Facts")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)

                HStack {
                    Text("Serving Size:")
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                    Text(nutrition.servingSize)
                        .font(.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Traffic Light Summary
            TrafficLightRow(
                sugar: nutrition.sugar,
                sodium: sodiumInMg,
                saturatedFat: nutrition.saturatedFat,
                style: .pill
            )
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Macros
            VStack(spacing: Spacing.md) {
                nutritionRow(label: "Calories", value: "\(Int(nutrition.calories))", unit: "", percentage: nil, trafficLight: nil)
                nutritionRow(label: "Total Fat", value: "\(Int(nutrition.fat))", unit: "g", percentage: calculatePercentage(nutrition.fat, dailyValue: 78), trafficLight: nil)
                nutritionRow(label: "Saturated Fat", value: "\(Int(nutrition.saturatedFat))", unit: "g", percentage: calculatePercentage(nutrition.saturatedFat, dailyValue: 20), trafficLight: TrafficLightNutrient.saturatedFat.level(for: nutrition.saturatedFat))
                nutritionRow(label: "Sodium", value: "\(Int(sodiumInMg))", unit: "mg", percentage: calculatePercentage(sodiumInMg, dailyValue: 2300), trafficLight: TrafficLightNutrient.sodium.level(for: sodiumInMg))
                nutritionRow(label: "Total Carb", value: "\(Int(nutrition.carbohydrates))", unit: "g", percentage: calculatePercentage(nutrition.carbohydrates, dailyValue: 275), trafficLight: nil)
                nutritionRow(label: "Fiber", value: "\(Int(nutrition.fiber))", unit: "g", percentage: calculatePercentage(nutrition.fiber, dailyValue: 28), trafficLight: nil)
                nutritionRow(label: "Sugars", value: "\(Int(nutrition.sugar))", unit: "g", percentage: calculatePercentage(nutrition.sugar, dailyValue: 50), trafficLight: TrafficLightNutrient.sugar.level(for: nutrition.sugar))
                nutritionRow(label: "Protein", value: "\(Int(nutrition.protein))", unit: "g", percentage: calculatePercentage(nutrition.protein, dailyValue: 50), trafficLight: nil)
            }
            
            if hasVitamins {
                Divider()
                
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Vitamins & Minerals")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    
                    if let d = nutrition.vitaminD {
                         nutritionRow(label: "Vitamin D", value: "\(Int(d))", unit: "mcg", percentage: calculatePercentage(d, dailyValue: 20), trafficLight: nil)
                    }
                    if let ca = nutrition.calcium {
                         nutritionRow(label: "Calcium", value: "\(Int(ca))", unit: "mg", percentage: calculatePercentage(ca, dailyValue: 1300), trafficLight: nil)
                    }
                    if let fe = nutrition.iron {
                         nutritionRow(label: "Iron", value: String(format: "%.1f", fe), unit: "mg", percentage: calculatePercentage(fe, dailyValue: 18), trafficLight: nil)
                    }
                    if let k = nutrition.potassium {
                         nutritionRow(label: "Potassium", value: "\(Int(k))", unit: "mg", percentage: calculatePercentage(k, dailyValue: 4700), trafficLight: nil)
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.md)
        .shadow(color: .cardShadow, radius: 4, x: 0, y: 2)
    }
    
    private var hasVitamins: Bool {
        nutrition.vitaminD != nil || nutrition.calcium != nil || nutrition.iron != nil || nutrition.potassium != nil
    }
    
    // MARK: - Helpers
    
    private func calculatePercentage(_ value: Double, dailyValue: Double) -> Double {
        guard dailyValue > 0 else { return 0 }
        return (value / dailyValue) * 100
    }
    
    private func nutritionRow(label: String, value: String, unit: String, percentage: Double?, trafficLight: TrafficLightLevel?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                HStack(spacing: Spacing.sm) {
                    Text(label)
                        .font(.bodyMedium)
                        .foregroundColor(.textPrimary)

                    // Traffic light indicator
                    if let level = trafficLight {
                        Circle()
                            .fill(level.color)
                            .frame(width: 8, height: 8)
                    }
                }

                Spacer()

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(value + unit)
                        .font(.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)

                    if let p = percentage {
                        Text("(\(Int(p))%)")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
            }

            if let p = percentage {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.backgroundTertiary)
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(trafficLight?.color ?? Color.accent)
                            .frame(width: min(geometry.size.width * (p / 100), geometry.size.width), height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
    }
}
