import SwiftUI

// MARK: - Nutrient Types
enum NutrientType: String, CaseIterable {
    case protein = "Protein"
    case carbohydrates = "Carbs"
    case fat = "Fat"
    case fiber = "Fiber"
    case sugar = "Sugar"
    case sodium = "Sodium"
    case calories = "Calories"

    var color: Color {
        switch self {
        case .protein:
            return .nutrientProtein
        case .carbohydrates:
            return .nutrientCarbs
        case .fat:
            return .nutrientFat
        case .fiber:
            return .nutrientFiber
        case .sugar:
            return .nutrientSugar
        case .sodium:
            return .nutrientSodium
        case .calories:
            return .warning
        }
    }

    var icon: String {
        switch self {
        case .protein:
            return "flame.fill"
        case .carbohydrates:
            return "leaf.fill"
        case .fat:
            return "drop.fill"
        case .fiber:
            return "circle.grid.cross.fill"
        case .sugar:
            return "cube.fill"
        case .sodium:
            return "sparkles"
        case .calories:
            return "bolt.fill"
        }
    }

    var unit: String {
        switch self {
        case .protein, .carbohydrates, .fat, .fiber, .sugar, .sodium:
            return "g"
        case .calories:
            return "kcal"
        }
    }
}

// MARK: - Nutrient Bar Styles
enum NutrientBarStyle {
    case minimal
    case standard
    case detailed
    case compact

    var height: CGFloat {
        switch self {
        case .minimal:
            return 6
        case .compact:
            return 8
        case .standard:
            return 12
        case .detailed:
            return 16
        }
    }

    var showLabel: Bool {
        switch self {
        case .minimal, .compact:
            return false
        case .standard, .detailed:
            return true
        }
    }

    var showValue: Bool {
        switch self {
        case .minimal:
            return false
        case .compact, .standard, .detailed:
            return true
        }
    }

    var showIcon: Bool {
        switch self {
        case .minimal, .compact, .standard:
            return false
        case .detailed:
            return true
        }
    }
}

// MARK: - Nutrient Bar Component
struct NutrientBar: View {
    let nutrient: NutrientType
    let value: Double
    let maxValue: Double
    let style: NutrientBarStyle
    let showAnimation: Bool
    let animationDelay: Double

    @State private var animatedProgress: Double = 0

    init(
        nutrient: NutrientType,
        value: Double,
        maxValue: Double,
        style: NutrientBarStyle = .standard,
        showAnimation: Bool = true,
        animationDelay: Double = 0.0
    ) {
        self.nutrient = nutrient
        self.value = value
        self.maxValue = maxValue
        self.style = style
        self.showAnimation = showAnimation
        self.animationDelay = animationDelay
    }

    private var progress: Double {
        guard maxValue > 0 else { return 0 }
        return min(value / maxValue, 1.0)
    }

    private var displayProgress: Double {
        showAnimation ? animatedProgress : progress
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Header (label, icon, value)
            if style.showLabel || style.showValue {
                HStack {
                    // Icon and label
                    if style.showLabel {
                        HStack(spacing: Spacing.xs) {
                            if style.showIcon {
                                Image(systemName: nutrient.icon)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(nutrient.color)
                            }

                            Text(nutrient.rawValue)
                                .font(.labelMedium)
                                .foregroundColor(.textSecondary)
                        }
                    }

                    Spacer()

                    // Value
                    if style.showValue {
                        HStack(spacing: 2) {
                            Text("\(value, specifier: "%.1f")")
                                .font(.labelMedium)
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)

                            Text(nutrient.unit)
                                .font(.labelSmall)
                                .foregroundColor(.textTertiary)
                        }
                    }
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: style.height / 2)
                        .fill(nutrient.color.opacity(0.15))
                        .frame(height: style.height)

                    // Progress fill
                    RoundedRectangle(cornerRadius: style.height / 2)
                        .fill(nutrientGradient)
                        .frame(
                            width: geometry.size.width * displayProgress,
                            height: style.height
                        )
                        .animation(
                            showAnimation ? .easeOut(duration: 1.0).delay(animationDelay) : .none,
                            value: displayProgress
                        )
                }
            }
            .frame(height: style.height)
        }
        .onAppear {
            if showAnimation {
                DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay) {
                    withAnimation(.easeOut(duration: 1.0)) {
                        animatedProgress = progress
                    }
                }
            } else {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newValue in
            if showAnimation {
                withAnimation(.easeInOut(duration: 0.6)) {
                    animatedProgress = newValue
                }
            } else {
                animatedProgress = newValue
            }
        }
    }

    private var nutrientGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                nutrient.color.opacity(0.8),
                nutrient.color
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Nutrient Bar Group
struct NutrientBarGroup: View {
    let nutrients: [NutrientData]
    let style: NutrientBarStyle
    let spacing: CGFloat
    let showAnimation: Bool

    init(
        nutrients: [NutrientData],
        style: NutrientBarStyle = .standard,
        spacing: CGFloat = Spacing.md,
        showAnimation: Bool = true
    ) {
        self.nutrients = nutrients
        self.style = style
        self.spacing = spacing
        self.showAnimation = showAnimation
    }

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(Array(nutrients.enumerated()), id: \.offset) { index, nutrientData in
                NutrientBar(
                    nutrient: nutrientData.type,
                    value: nutrientData.value,
                    maxValue: nutrientData.maxValue,
                    style: style,
                    showAnimation: showAnimation,
                    animationDelay: Double(index) * 0.1
                )
            }
        }
    }
}

// MARK: - Compact Nutrient Display
struct CompactNutrientDisplay: View {
    let nutrients: [NutrientData]
    let maxItems: Int

    init(nutrients: [NutrientData], maxItems: Int = 4) {
        self.nutrients = nutrients
        self.maxItems = maxItems
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(Array(nutrients.prefix(maxItems).enumerated()), id: \.offset) { index, nutrientData in
                VStack(spacing: Spacing.xs) {
                    // Circular progress indicator
                    ZStack {
                        Circle()
                            .stroke(nutrientData.type.color.opacity(0.2), lineWidth: 3)

                        Circle()
                            .trim(from: 0, to: min(nutrientData.value / nutrientData.maxValue, 1.0))
                            .stroke(
                                nutrientData.type.color,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))

                        // Icon
                        Image(systemName: nutrientData.type.icon)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(nutrientData.type.color)
                    }
                    .frame(width: 24, height: 24)

                    // Value
                    VStack(spacing: 0) {
                        Text("\(nutrientData.value, specifier: "%.0f")")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)

                        Text(nutrientData.type.unit)
                            .font(.system(size: 8))
                            .foregroundColor(.textTertiary)
                    }
                }
            }
        }
    }
}

// MARK: - Macronutrient Pie Chart
struct MacronutrientChart: View {
    let protein: Double
    let carbs: Double
    let fat: Double
    let size: CGFloat

    init(protein: Double, carbs: Double, fat: Double, size: CGFloat = 120) {
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.size = size
    }

    private var total: Double {
        protein + carbs + fat
    }

    private var proteinAngle: Double {
        guard total > 0 else { return 0 }
        return (protein / total) * 360
    }

    private var carbsAngle: Double {
        guard total > 0 else { return 0 }
        return (carbs / total) * 360
    }

    private var fatAngle: Double {
        guard total > 0 else { return 0 }
        return (fat / total) * 360
    }

    var body: some View {
        ZStack {
            // Protein segment
            PieSlice(
                startAngle: 0,
                endAngle: proteinAngle
            )
            .fill(NutrientType.protein.color)

            // Carbs segment
            PieSlice(
                startAngle: proteinAngle,
                endAngle: proteinAngle + carbsAngle
            )
            .fill(NutrientType.carbohydrates.color)

            // Fat segment
            PieSlice(
                startAngle: proteinAngle + carbsAngle,
                endAngle: proteinAngle + carbsAngle + fatAngle
            )
            .fill(NutrientType.fat.color)

            // Center label
            VStack(spacing: 2) {
                Text("Macros")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)

                Text("\(Int(total))g")
                    .font(.system(size: size * 0.15, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Supporting Views
struct PieSlice: Shape {
    let startAngle: Double
    let endAngle: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startAngle - 90),
            endAngle: .degrees(endAngle - 90),
            clockwise: false
        )
        path.closeSubpath()

        return path
    }
}

// MARK: - Supporting Models
struct NutrientData {
    let type: NutrientType
    let value: Double
    let maxValue: Double

    init(type: NutrientType, value: Double, maxValue: Double = 100) {
        self.type = type
        self.value = value
        self.maxValue = maxValue
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: Spacing.xxl) {
            // Standard nutrient bars
            Text("Nutrient Bars")
                .headlineMediumStyle()

            VStack(spacing: Spacing.lg) {
                NutrientBarGroup(
                    nutrients: [
                        NutrientData(type: .protein, value: 25, maxValue: 50),
                        NutrientData(type: .carbohydrates, value: 45, maxValue: 100),
                        NutrientData(type: .fat, value: 15, maxValue: 30),
                        NutrientData(type: .fiber, value: 8, maxValue: 25)
                    ],
                    style: .standard
                )
            }
            .standardCard()

            // Detailed style
            Text("Detailed Style")
                .headlineMediumStyle()

            NutrientBarGroup(
                nutrients: [
                    NutrientData(type: .protein, value: 18, maxValue: 50),
                    NutrientData(type: .sugar, value: 12, maxValue: 30),
                    NutrientData(type: .sodium, value: 2.5, maxValue: 6)
                ],
                style: .detailed
            )
            .standardCard()

            // Compact display
            Text("Compact Display")
                .headlineMediumStyle()

            CompactNutrientDisplay(
                nutrients: [
                    NutrientData(type: .protein, value: 20, maxValue: 50),
                    NutrientData(type: .carbohydrates, value: 60, maxValue: 100),
                    NutrientData(type: .fat, value: 18, maxValue: 30),
                    NutrientData(type: .fiber, value: 12, maxValue: 25)
                ]
            )
            .standardCard()

            // Macronutrient chart
            Text("Macronutrient Distribution")
                .headlineMediumStyle()

            MacronutrientChart(
                protein: 25,
                carbs: 45,
                fat: 18
            )
            .standardCard()
        }
        .padding()
    }
}