import SwiftUI

// MARK: - Traffic Light Level
enum TrafficLightLevel: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var color: Color {
        switch self {
        case .low:
            return .trafficLightGreen
        case .medium:
            return .trafficLightYellow
        case .high:
            return .trafficLightRed
        }
    }

    var icon: String {
        switch self {
        case .low:
            return "checkmark.circle.fill"
        case .medium:
            return "exclamationmark.circle.fill"
        case .high:
            return "xmark.circle.fill"
        }
    }
}

// MARK: - Traffic Light Nutrient Types
enum TrafficLightNutrient: String, CaseIterable {
    case sugar = "Sugar"
    case sodium = "Sodium"
    case saturatedFat = "Sat Fat"

    var icon: String {
        switch self {
        case .sugar:
            return "cube.fill"
        case .sodium:
            return "sparkles"
        case .saturatedFat:
            return "drop.fill"
        }
    }

    var unit: String {
        switch self {
        case .sugar, .saturatedFat:
            return "g"
        case .sodium:
            return "mg"
        }
    }

    // FSA thresholds per 100g
    // Source: UK Food Standards Agency front-of-pack labeling guidelines
    func level(for value: Double) -> TrafficLightLevel {
        switch self {
        case .sugar:
            // Low: ≤5g, Medium: 5.1-22.5g, High: >22.5g per 100g
            if value <= 5.0 {
                return .low
            } else if value <= 22.5 {
                return .medium
            } else {
                return .high
            }

        case .sodium:
            // Low: ≤120mg, Medium: 121-600mg, High: >600mg per 100g
            if value <= 120.0 {
                return .low
            } else if value <= 600.0 {
                return .medium
            } else {
                return .high
            }

        case .saturatedFat:
            // Low: ≤1.5g, Medium: 1.6-5g, High: >5g per 100g
            if value <= 1.5 {
                return .low
            } else if value <= 5.0 {
                return .medium
            } else {
                return .high
            }
        }
    }
}

// MARK: - Traffic Light Display Style
enum TrafficLightStyle {
    case dot           // Simple colored dot
    case pill          // Pill with label (e.g., "Low Sugar")
    case compact       // Icon + colored indicator
    case detailed      // Full display with value
}

// MARK: - Nutrient Traffic Light Component
struct NutrientTrafficLight: View {
    let nutrient: TrafficLightNutrient
    let value: Double
    let style: TrafficLightStyle

    init(nutrient: TrafficLightNutrient, value: Double, style: TrafficLightStyle = .compact) {
        self.nutrient = nutrient
        self.value = value
        self.style = style
    }

    private var level: TrafficLightLevel {
        nutrient.level(for: value)
    }

    var body: some View {
        switch style {
        case .dot:
            dotView
        case .pill:
            pillView
        case .compact:
            compactView
        case .detailed:
            detailedView
        }
    }

    // MARK: - Dot Style
    private var dotView: some View {
        Circle()
            .fill(level.color)
            .frame(width: 10, height: 10)
    }

    // MARK: - Pill Style
    private var pillView: some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(level.color)
                .frame(width: 8, height: 8)

            Text("\(level.rawValue) \(nutrient.rawValue)")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(level.color.opacity(0.15))
        .cornerRadius(CornerRadius.pill)
    }

    // MARK: - Compact Style
    private var compactView: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: nutrient.icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(level.color)

            Circle()
                .fill(level.color)
                .frame(width: 8, height: 8)
        }
    }

    // MARK: - Detailed Style
    private var detailedView: some View {
        HStack(spacing: Spacing.sm) {
            // Icon
            Image(systemName: nutrient.icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(level.color)
                .frame(width: 20)

            // Label and value
            VStack(alignment: .leading, spacing: 2) {
                Text(nutrient.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)

                HStack(spacing: Spacing.xs) {
                    Text(formattedValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)

                    Text(nutrient.unit)
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
            }

            Spacer()

            // Level indicator
            HStack(spacing: Spacing.xs) {
                Circle()
                    .fill(level.color)
                    .frame(width: 10, height: 10)

                Text(level.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(level.color)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(level.color.opacity(0.1))
            .cornerRadius(CornerRadius.pill)
        }
    }

    private var formattedValue: String {
        if nutrient == .sodium {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
}

// MARK: - Traffic Light Row (Multiple Nutrients)
struct TrafficLightRow: View {
    let sugar: Double?
    let sodium: Double?
    let saturatedFat: Double?
    let style: TrafficLightStyle

    init(
        sugar: Double? = nil,
        sodium: Double? = nil,
        saturatedFat: Double? = nil,
        style: TrafficLightStyle = .compact
    ) {
        self.sugar = sugar
        self.sodium = sodium
        self.saturatedFat = saturatedFat
        self.style = style
    }

    var body: some View {
        HStack(spacing: style == .dot ? Spacing.xs : Spacing.md) {
            if let sugar = sugar {
                NutrientTrafficLight(nutrient: .sugar, value: sugar, style: style)
            }

            if let sodium = sodium {
                NutrientTrafficLight(nutrient: .sodium, value: sodium, style: style)
            }

            if let saturatedFat = saturatedFat {
                NutrientTrafficLight(nutrient: .saturatedFat, value: saturatedFat, style: style)
            }
        }
    }
}

// MARK: - Traffic Light Card (Full Display)
struct TrafficLightCard: View {
    let sugar: Double?
    let sodium: Double?
    let saturatedFat: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Nutrient Levels")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)

            VStack(spacing: Spacing.sm) {
                if let sugar = sugar {
                    NutrientTrafficLight(nutrient: .sugar, value: sugar, style: .detailed)
                }

                if let sodium = sodium {
                    NutrientTrafficLight(nutrient: .sodium, value: sodium, style: .detailed)
                }

                if let saturatedFat = saturatedFat {
                    NutrientTrafficLight(nutrient: .saturatedFat, value: saturatedFat, style: .detailed)
                }
            }
        }
        .padding(Spacing.cardPadding)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.card)
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: Spacing.xxl) {
            // Dot style
            Text("Dot Style")
                .font(.headline)

            HStack(spacing: Spacing.lg) {
                TrafficLightRow(sugar: 3.0, sodium: 100, saturatedFat: 1.0, style: .dot)
                Text("Low values")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            HStack(spacing: Spacing.lg) {
                TrafficLightRow(sugar: 15.0, sodium: 400, saturatedFat: 3.0, style: .dot)
                Text("Medium values")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            HStack(spacing: Spacing.lg) {
                TrafficLightRow(sugar: 30.0, sodium: 800, saturatedFat: 8.0, style: .dot)
                Text("High values")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Divider()

            // Pill style
            Text("Pill Style")
                .font(.headline)

            HStack {
                NutrientTrafficLight(nutrient: .sugar, value: 3.0, style: .pill)
                NutrientTrafficLight(nutrient: .sodium, value: 800, style: .pill)
                NutrientTrafficLight(nutrient: .saturatedFat, value: 3.0, style: .pill)
            }

            Divider()

            // Compact style
            Text("Compact Style")
                .font(.headline)

            TrafficLightRow(sugar: 15.0, sodium: 400, saturatedFat: 6.0, style: .compact)

            Divider()

            // Full card
            Text("Traffic Light Card")
                .font(.headline)

            TrafficLightCard(sugar: 12.5, sodium: 450, saturatedFat: 4.2)
        }
        .padding()
    }
}
