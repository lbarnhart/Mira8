import SwiftUI

// MARK: - Card Style Types
enum CardStyle {
    case standard
    case elevated
    case outlined
    case filled
    case minimal
    case prominent

    var backgroundColor: Color {
        switch self {
        case .standard:
            return .cardBackground
        case .elevated:
            return .cardBackgroundElevated
        case .outlined:
            return .cardBackground
        case .filled:
            return .backgroundSecondary
        case .minimal:
            return .clear
        case .prominent:
            return .cardBackground
        }
    }

    var borderColor: Color {
        switch self {
        case .standard, .elevated, .filled, .minimal:
            return .clear
        case .outlined:
            return .cardBorder
        case .prominent:
            return .primary.opacity(0.2)
        }
    }

    var borderWidth: CGFloat {
        switch self {
        case .standard, .elevated, .filled, .minimal:
            return 0
        case .outlined:
            return Border.thin
        case .prominent:
            return Border.medium
        }
    }

    var shadowStyle: ShadowStyle {
        switch self {
        case .standard:
            return Shadow.xs
        case .elevated:
            return Shadow.sm
        case .outlined, .filled, .minimal:
            return Shadow.none
        case .prominent:
            return Shadow.md
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .standard, .elevated, .outlined, .filled:
            return CornerRadius.card
        case .minimal:
            return 0
        case .prominent:
            return CornerRadius.lg
        }
    }

    var padding: CGFloat {
        switch self {
        case .standard, .elevated, .outlined, .filled, .prominent:
            return Spacing.cardPadding
        case .minimal:
            return 0
        }
    }
}

// MARK: - Card Modifier
struct CardModifier: ViewModifier {
    let style: CardStyle
    let isPressed: Bool

    init(style: CardStyle = .standard, isPressed: Bool = false) {
        self.style = style
        self.isPressed = isPressed
    }

    func body(content: Content) -> some View {
        content
            .padding(style.padding)
            .background(style.backgroundColor)
            .cornerRadius(style.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .stroke(style.borderColor, lineWidth: style.borderWidth)
            )
            .shadow(
                color: style.shadowStyle.color.opacity(isPressed ? 0.5 : 1.0),
                radius: style.shadowStyle.radius * (isPressed ? 0.5 : 1.0),
                x: style.shadowStyle.x,
                y: style.shadowStyle.y * (isPressed ? 0.5 : 1.0)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

// MARK: - Pressable Card Modifier
struct PressableCardModifier: ViewModifier {
    let style: CardStyle
    let action: () -> Void
    @State private var isPressed = false

    init(style: CardStyle = .standard, action: @escaping () -> Void) {
        self.style = style
        self.action = action
    }

    func body(content: Content) -> some View {
        content
            .modifier(CardModifier(style: style, isPressed: isPressed))
            .onTapGesture {
                action()
            }
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            }, perform: {})
    }
}

// MARK: - Gradient Card Modifier
struct GradientCardModifier: ViewModifier {
    let gradient: LinearGradient
    let cornerRadius: CGFloat
    let shadowStyle: ShadowStyle

    init(
        gradient: LinearGradient = .cardGradient,
        cornerRadius: CGFloat = CornerRadius.card,
        shadowStyle: ShadowStyle = Shadow.sm
    ) {
        self.gradient = gradient
        self.cornerRadius = cornerRadius
        self.shadowStyle = shadowStyle
    }

    func body(content: Content) -> some View {
        content
            .padding(Spacing.cardPadding)
            .background(gradient)
            .cornerRadius(cornerRadius)
            .shadow(
                color: shadowStyle.color,
                radius: shadowStyle.radius,
                x: shadowStyle.x,
                y: shadowStyle.y
            )
    }
}

// MARK: - Score Card Modifier (Special case for score displays)
struct ScoreCardModifier: ViewModifier {
    let score: Double
    let size: CGFloat

    init(score: Double, size: CGFloat = Size.scoreGaugeMD) {
        self.score = score
        self.size = size
    }

    func body(content: Content) -> some View {
        content
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(.cardGradient)
                    .overlay(
                        Circle()
                            .stroke(
                                Color.scoreColor(for: score).opacity(0.3),
                                lineWidth: 2
                            )
                    )
            )
            .shadow(
                color: Color.scoreColor(for: score).opacity(0.2),
                radius: 8,
                x: 0,
                y: 4
            )
    }
}

// MARK: - View Extensions
extension View {
    // MARK: - Standard Card Styles
    func cardStyle(_ style: CardStyle = .standard) -> some View {
        self.modifier(CardModifier(style: style))
    }

    func standardCard() -> some View {
        self.modifier(CardModifier(style: .standard))
    }

    func elevatedCard() -> some View {
        self.modifier(CardModifier(style: .elevated))
    }

    func outlinedCard() -> some View {
        self.modifier(CardModifier(style: .outlined))
    }

    func filledCard() -> some View {
        self.modifier(CardModifier(style: .filled))
    }

    func minimalCard() -> some View {
        self.modifier(CardModifier(style: .minimal))
    }

    func prominentCard() -> some View {
        self.modifier(CardModifier(style: .prominent))
    }

    // MARK: - Interactive Cards
    func pressableCard(style: CardStyle = .standard, action: @escaping () -> Void) -> some View {
        self.modifier(PressableCardModifier(style: style, action: action))
    }

    func tappableCard(action: @escaping () -> Void) -> some View {
        self.modifier(PressableCardModifier(style: .standard, action: action))
    }

    // MARK: - Special Cards
    func gradientCard(
        gradient: LinearGradient = .cardGradient,
        cornerRadius: CGFloat = CornerRadius.card,
        shadowStyle: ShadowStyle = Shadow.sm
    ) -> some View {
        self.modifier(GradientCardModifier(
            gradient: gradient,
            cornerRadius: cornerRadius,
            shadowStyle: shadowStyle
        ))
    }

    func scoreCard(score: Double, size: CGFloat = Size.scoreGaugeMD) -> some View {
        self.modifier(ScoreCardModifier(score: score, size: size))
    }

    // MARK: - Content-Specific Cards
    func productCard() -> some View {
        self.modifier(CardModifier(style: .elevated))
    }

    func settingsCard() -> some View {
        self.modifier(CardModifier(style: .standard))
    }

    func historyCard() -> some View {
        self.modifier(CardModifier(style: .outlined))
    }

    func alertCard() -> some View {
        self.modifier(CardModifier(style: .prominent))
    }
}

// MARK: - Card Container Views
struct Card<Content: View>: View {
    let style: CardStyle
    let content: () -> Content

    init(style: CardStyle = .standard, @ViewBuilder content: @escaping () -> Content) {
        self.style = style
        self.content = content
    }

    var body: some View {
        content()
            .modifier(CardModifier(style: style))
    }
}

struct PressableCard<Content: View>: View {
    let style: CardStyle
    let action: () -> Void
    let content: () -> Content

    init(
        style: CardStyle = .standard,
        action: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.style = style
        self.action = action
        self.content = content
    }

    var body: some View {
        content()
            .modifier(PressableCardModifier(style: style, action: action))
    }
}