import SwiftUI

// MARK: - Score Gauge Styles
enum ScoreGaugeStyle {
    case minimal
    case standard
    case detailed
    case prominent

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

}

// MARK: - Animated Score Gauge
struct ScoreGauge: View {
    let score: Double
    let size: CGFloat
    let style: ScoreGaugeStyle
    let showAnimation: Bool
    let animationDelay: Double
    let confidence: ScoreConfidence?
    @ScaledMetric(relativeTo: .body) private var scaledSize: CGFloat = Size.scoreGaugeMD

    @State private var animatedScore: Double = 0
    @State private var showConfetti = false

    init(
        score: Double,
        size: CGFloat = Size.scoreGaugeMD,
        style: ScoreGaugeStyle = .standard,
        showAnimation: Bool = true,
        animationDelay: Double = 0.0,
        confidence: ScoreConfidence? = nil
    ) {
        self.score = score
        self.size = size
        self.style = style
        self.showAnimation = showAnimation
        self.animationDelay = animationDelay
        self.confidence = confidence
        self._scaledSize = ScaledMetric(wrappedValue: size, relativeTo: .body)
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
        style.lineWidth(scaledSize)
    }

    private var backgroundStrokeColor: Color {
        .textSubduedAccessible
    }

    private var backgroundLineWidth: CGFloat {
        min(2, max(1, lineWidth * 0.4))
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    backgroundStrokeColor,
                    lineWidth: backgroundLineWidth
                )

            // Progress circle with gradient
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

            // Inner content
            VStack(spacing: style == .minimal ? 0 : 2) {
                // Score number
                Text("\(Int(displayScore.rounded()))")
                    .font(scoreFont)
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor)
                    .contentTransition(.numericText())
            }

            // Glowing effect for prominent style
            if style == .prominent && displayScore > 0 {
                Circle()
                    .stroke(
                        scoreColor.opacity(0.3),
                        lineWidth: 1
                    )
                    .frame(width: scaledSize + 12, height: scaledSize + 12)
                    .blur(radius: 2)
            }

            // Confidence badge
            if let confidence = confidence, style != .minimal {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        confidenceBadge(for: confidence)
                            .offset(x: scaledSize * 0.15, y: scaledSize * 0.15)
                    }
                }
            }

            // Confetti for excellent scores
            if showConfetti && normalizedScore >= 80 {
                ConfettiView()
                    .frame(width: scaledSize * 2, height: scaledSize * 2)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: scaledSize, height: scaledSize)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mira score")
        .accessibilityValue("\(Int(normalizedScore.rounded())) out of 100")
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
            return .system(.caption2, design: .rounded, weight: .bold)
        case .standard:
            return .system(.title2, design: .rounded, weight: .bold)
        case .detailed:
            return .system(.title, design: .rounded, weight: .bold)
        case .prominent:
            return .system(.largeTitle, design: .rounded, weight: .bold)
        }
    }

    private func startAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay) {
            withAnimation(.easeOut(duration: 1.5).delay(0.1)) {
                animatedScore = normalizedScore
            }

            // Trigger confetti for excellent scores after animation completes
            if normalizedScore >= 80 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                    showConfetti = true

                    // Auto-dismiss confetti after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        showConfetti = false
                    }
                }
            }
        }
    }

    private func animateToScore(_ newScore: Double) {
        let targetScore = min(max(newScore, 0), 100)
        withAnimation(.easeInOut(duration: 0.8)) {
            animatedScore = targetScore
        }
    }

    @ViewBuilder
    private func confidenceBadge(for confidence: ScoreConfidence) -> some View {
        let badgeSize = scaledSize * 0.22
        let (letter, color, bgColor) = confidenceBadgeStyle(for: confidence)

        ZStack {
            Circle()
                .fill(bgColor)
                .frame(width: badgeSize, height: badgeSize)

            Circle()
                .strokeBorder(Color.white, lineWidth: 1.5)
                .frame(width: badgeSize, height: badgeSize)

            Text(letter)
                .font(.caption2.weight(.bold))
                .foregroundColor(color)
        }
    }

    private func confidenceBadgeStyle(for confidence: ScoreConfidence) -> (String, Color, Color) {
        switch confidence {
        case .high:
            return ("H", .green, Color.green.opacity(0.15))
        case .medium:
            return ("M", .orange, Color.orange.opacity(0.15))
        case .low:
            return ("L", .red, Color.red.opacity(0.15))
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
