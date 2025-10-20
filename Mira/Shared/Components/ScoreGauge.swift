import SwiftUI

// MARK: - Score Gauge Styles
enum ScoreGaugeStyle {
    case minimal
    case standard
    case detailed
    case prominent

    var showLabel: Bool {
        switch self {
        case .minimal:
            return false
        case .standard, .detailed, .prominent:
            return true
        }
    }

    var showPercentage: Bool {
        switch self {
        case .minimal, .standard:
            return false
        case .detailed, .prominent:
            return true
        }
    }

    var lineWidth: (CGFloat) -> CGFloat {
        return { size in
            switch self {
            case .minimal:
                return size * 0.08
            case .standard:
                return size * 0.1
            case .detailed:
                return size * 0.12
            case .prominent:
                return size * 0.14
            }
        }
    }

    var backgroundOpacity: Double {
        switch self {
        case .minimal:
            return 0.1
        case .standard:
            return 0.15
        case .detailed, .prominent:
            return 0.2
        }
    }
}

// MARK: - Animated Score Gauge
struct ScoreGauge: View {
    let score: Double
    let size: CGFloat
    let style: ScoreGaugeStyle
    let showAnimation: Bool
    let animationDelay: Double

    @State private var animatedScore: Double = 0
    @State private var isAnimating = false

    init(
        score: Double,
        size: CGFloat = Size.scoreGaugeMD,
        style: ScoreGaugeStyle = .standard,
        showAnimation: Bool = true,
        animationDelay: Double = 0.0
    ) {
        self.score = score
        self.size = size
        self.style = style
        self.showAnimation = showAnimation
        self.animationDelay = animationDelay
    }

    private var normalizedScore: Double {
        min(max(score, 0), 100)
    }

    private var displayScore: Double {
        showAnimation ? animatedScore : normalizedScore
    }

    private var scoreColor: Color {
        Color.scoreColor(for: displayScore)
    }

    private var progress: Double {
        displayScore / 100
    }

    private var lineWidth: CGFloat {
        style.lineWidth(size)
    }

    private var backgroundStrokeColor: Color {
        scoreColor.opacity(style.backgroundOpacity)
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    backgroundStrokeColor,
                    lineWidth: lineWidth
                )

            // Progress circle with gradient
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            scoreColor.opacity(0.8),
                            scoreColor,
                            scoreColor.opacity(0.9)
                        ]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))

            // Inner content
            VStack(spacing: style == .minimal ? 0 : 2) {
                // Score number
                Text("\(Int(displayScore))")
                    .font(scoreFont)
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor)
                    .contentTransition(.numericText())

                // Label and percentage
                if style.showLabel {
                    VStack(spacing: 0) {
                        Text("SCORE")
                            .font(labelFont)
                            .fontWeight(.semibold)
                            .foregroundColor(.textTertiary)

                        if style.showPercentage {
                            Text("\(Int(displayScore))%")
                                .font(.caption2)
                                .foregroundColor(.textQuaternary)
                        }
                    }
                }
            }

            // Glowing effect for prominent style
            if style == .prominent && displayScore > 0 {
                Circle()
                    .stroke(
                        scoreColor.opacity(0.3),
                        lineWidth: 1
                    )
                    .frame(width: size + 12, height: size + 12)
                    .blur(radius: 2)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            if showAnimation {
                startAnimation()
            } else {
                animatedScore = normalizedScore
            }
        }
        .onChange(of: score) { newValue in
            if showAnimation {
                animateToScore(newValue)
            } else {
                animatedScore = min(max(newValue, 0), 100)
            }
        }
    }

    private var scoreFont: Font {
        switch style {
        case .minimal:
            return .system(size: size * 0.25, weight: .bold, design: .rounded)
        case .standard:
            return .system(size: size * 0.3, weight: .bold, design: .rounded)
        case .detailed:
            return .system(size: size * 0.28, weight: .bold, design: .rounded)
        case .prominent:
            return .system(size: size * 0.32, weight: .bold, design: .rounded)
        }
    }

    private var labelFont: Font {
        switch style {
        case .minimal:
            return .system(size: size * 0.08, weight: .medium)
        case .standard:
            return .system(size: size * 0.1, weight: .medium)
        case .detailed, .prominent:
            return .system(size: size * 0.09, weight: .medium)
        }
    }

    private func startAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay) {
            withAnimation(.easeOut(duration: 1.5).delay(0.1)) {
                animatedScore = normalizedScore
            }
        }
    }

    private func animateToScore(_ newScore: Double) {
        let targetScore = min(max(newScore, 0), 100)
        withAnimation(.easeInOut(duration: 0.8)) {
            animatedScore = targetScore
        }
    }
}

// MARK: - Score Ring (Minimal variant)
struct ScoreRing: View {
    let score: Double
    let size: CGFloat
    let lineWidth: CGFloat

    init(score: Double, size: CGFloat = 40, lineWidth: CGFloat = 4) {
        self.score = score
        self.size = size
        self.lineWidth = lineWidth
    }

    private var normalizedScore: Double {
        min(max(score, 0), 100)
    }

    private var scoreColor: Color {
        Color.scoreColor(for: normalizedScore)
    }

    private var progress: Double {
        normalizedScore / 100
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    scoreColor.opacity(0.15),
                    lineWidth: lineWidth
                )

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    scoreColor,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.0), value: progress)

            // Score text (optional for very small sizes)
            if size >= 30 {
                Text("\(Int(normalizedScore))")
                    .font(.system(size: size * 0.25, weight: .semibold, design: .rounded))
                    .foregroundColor(scoreColor)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Score Gauge with Breakdown
struct DetailedScoreGauge: View {
    let score: Double
    let breakdown: [ScoreComponent]
    let size: CGFloat

    init(score: Double, breakdown: [ScoreComponent] = [], size: CGFloat = Size.scoreGaugeLG) {
        self.score = score
        self.breakdown = breakdown
        self.size = size
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Main score gauge
            ScoreGauge(
                score: score,
                size: size,
                style: .prominent
            )

            // Breakdown components
            if !breakdown.isEmpty {
                VStack(spacing: Spacing.xs) {
                    ForEach(Array(breakdown.enumerated()), id: \.offset) { index, component in
                        HStack {
                            Circle()
                                .fill(Color.scoreColor(for: component.score))
                                .frame(width: 8, height: 8)

                            Text(component.name)
                                .font(.labelSmall)
                                .foregroundColor(.textSecondary)

                            Spacer()

                            Text("\(Int(component.score))")
                                .font(.labelSmall)
                                .fontWeight(.medium)
                                .foregroundColor(Color.scoreColor(for: component.score))
                        }
                        .padding(.horizontal, Spacing.sm)
                    }
                }
                .padding(.vertical, Spacing.xs)
                .background(.backgroundSecondary)
                .cornerRadius(CornerRadius.sm)
            }
        }
    }
}

// MARK: - Supporting Models
struct ScoreComponent {
    let name: String
    let score: Double
    let weight: Double

    init(name: String, score: Double, weight: Double = 1.0) {
        self.name = name
        self.score = score
        self.weight = weight
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: Spacing.xxl) {
            // Style variations
            Text("Score Gauge Styles")
                .headlineMediumStyle()

            HStack(spacing: Spacing.lg) {
                VStack {
                    ScoreGauge(score: 85, size: 80, style: .minimal)
                    Text("Minimal")
                        .labelSmallStyle()
                }

                VStack {
                    ScoreGauge(score: 73, size: 100, style: .standard)
                    Text("Standard")
                        .labelSmallStyle()
                }

                VStack {
                    ScoreGauge(score: 92, size: 120, style: .prominent)
                    Text("Prominent")
                        .labelSmallStyle()
                }
            }

            // Size variations
            Text("Size Variations")
                .headlineMediumStyle()

            HStack(spacing: Spacing.lg) {
                ScoreGauge(score: 67, size: 60)
                ScoreGauge(score: 78, size: 80)
                ScoreGauge(score: 89, size: 100)
                ScoreGauge(score: 95, size: 120)
            }

            // Score rings
            Text("Score Rings")
                .headlineMediumStyle()

            HStack(spacing: Spacing.md) {
                ScoreRing(score: 45, size: 30)
                ScoreRing(score: 67, size: 40)
                ScoreRing(score: 84, size: 50)
                ScoreRing(score: 92, size: 60)
            }

            // Detailed gauge with breakdown
            Text("Detailed Score Gauge")
                .headlineMediumStyle()

            DetailedScoreGauge(
                score: 82,
                breakdown: [
                    ScoreComponent(name: "Nutrition", score: 85),
                    ScoreComponent(name: "Processing", score: 78),
                    ScoreComponent(name: "Ingredients", score: 90),
                    ScoreComponent(name: "Additives", score: 75)
                ]
            )
        }
        .padding()
    }
}