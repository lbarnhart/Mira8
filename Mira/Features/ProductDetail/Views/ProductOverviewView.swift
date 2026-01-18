import SwiftUI

struct ProductOverviewView: View {
    let product: ProductModel
    let healthScore: HealthScore?
    let dietaryRestrictions: Set<String>

    // Callbacks/Navigation
    var onAlternativesTap: () -> Void = {}

    var body: some View {
        VStack(spacing: Spacing.md) {
            // 1. Quick Nutrient Summary - Compact horizontal pills
            nutrientSummarySection()

            // 2. Key Takeaways - What matters most
            if let score = healthScore {
                keyTakeawaysSection(score)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Sections

    private func nutrientSummarySection() -> some View {
        let nutrition = product.nutrition
        let sodiumMg = nutrition.sodium * 1000

        return HStack(spacing: Spacing.sm) {
            nutrientPill(
                nutrient: .sugar,
                value: nutrition.sugar,
                label: "Sugar"
            )

            nutrientPill(
                nutrient: .sodium,
                value: sodiumMg,
                label: "Sodium"
            )

            nutrientPill(
                nutrient: .saturatedFat,
                value: nutrition.saturatedFat,
                label: "Sat Fat"
            )
        }
    }

    private func nutrientPill(nutrient: TrafficLightNutrient, value: Double, label: String) -> some View {
        let level = nutrient.level(for: value)

        return HStack(spacing: 6) {
            Circle()
                .fill(level.color)
                .frame(width: 10, height: 10)

            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)

            Text(level.rawValue)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(level.color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(level.color.opacity(0.1))
        .cornerRadius(CornerRadius.pill)
    }

    private func keyTakeawaysSection(_ score: HealthScore) -> some View {
        let pros = extractPositiveFactors(from: score)
        let cons = extractNegativeFactors(from: score)

        // If no highlights, don't show the section
        guard !pros.isEmpty || !cons.isEmpty else {
            return AnyView(EmptyView())
        }

        return AnyView(
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Good things
                ForEach(pros, id: \.self) { pro in
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.scoreGood)
                            .font(.system(size: 14))
                        Text(pro)
                            .font(.subheadline)
                            .foregroundColor(.textPrimary)
                        Spacer()
                    }
                }

                // Watch out for
                ForEach(cons, id: \.self) { con in
                    HStack(spacing: 8) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.scorePoor)
                            .font(.system(size: 14))
                        Text(con)
                            .font(.subheadline)
                            .foregroundColor(.textPrimary)
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color.backgroundSecondary)
            .cornerRadius(CornerRadius.md)
        )
    }

    // MARK: - Helpers (Copied/Adapted logic)
    
    private func extractPositiveFactors(from healthScore: HealthScore) -> [String] {
        healthScore.contributions
            .filter { $0.kind == .positive && $0.weightedPoints > 3.0 }
            .sorted { $0.weightedPoints > $1.weightedPoints }
            .prefix(3)
            .compactMap { contribution -> String? in
                switch contribution.nutrient {
                case .protein: return "Good protein source"
                case .fiber: return "High fiber"
                case .fruitVegLegumeNut: return "Contains fruits/veggies"
                default: return nil
                }
            }
    }
    
    private func extractNegativeFactors(from healthScore: HealthScore) -> [String] {
        healthScore.contributions
            .filter { $0.kind == .negative && $0.weightedPoints > 5.0 }
            .sorted { $0.weightedPoints > $1.weightedPoints }
            .prefix(3)
            .compactMap { contribution -> String? in
                switch contribution.nutrient {
                case .sugars: return "High sugar"
                case .sodium: return "High sodium"
                case .saturatedFat: return "High saturated fat"
                default: return nil
                }
            }
    }
}
