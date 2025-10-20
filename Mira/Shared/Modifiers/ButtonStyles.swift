import SwiftUI

// MARK: - Button Style Types
enum MiraButtonStyle {
    case primary
    case secondary
    case tertiary
    case destructive
    case ghost
    case outline
    case minimal

    var backgroundColor: Color {
        switch self {
        case .primary:
            return .buttonPrimary
        case .secondary:
            return .buttonSecondary
        case .tertiary:
            return .buttonTertiary
        case .destructive:
            return .error
        case .ghost:
            return .clear
        case .outline:
            return .clear
        case .minimal:
            return .clear
        }
    }

    var foregroundColor: Color {
        switch self {
        case .primary, .destructive:
            return .textOnDark
        case .secondary, .tertiary:
            return .textPrimary
        case .ghost, .outline, .minimal:
            return .buttonPrimary
        }
    }

    var borderColor: Color {
        switch self {
        case .primary, .secondary, .tertiary, .destructive, .ghost, .minimal:
            return .clear
        case .outline:
            return .buttonPrimary
        }
    }

    var borderWidth: CGFloat {
        switch self {
        case .primary, .secondary, .tertiary, .destructive, .ghost, .minimal:
            return 0
        case .outline:
            return Border.medium
        }
    }
}

// MARK: - Button Sizes
enum ButtonSize {
    case small
    case medium
    case large

    var height: CGFloat {
        switch self {
        case .small:
            return Size.buttonHeightSM
        case .medium:
            return Size.buttonHeightMD
        case .large:
            return Size.buttonHeightLG
        }
    }

    var font: Font {
        switch self {
        case .small:
            return .buttonSmall
        case .medium:
            return .buttonMedium
        case .large:
            return .buttonLarge
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small:
            return Spacing.md
        case .medium:
            return Spacing.lg
        case .large:
            return Spacing.xl
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small:
            return Size.iconSM
        case .medium:
            return Size.iconMD
        case .large:
            return Size.iconLG
        }
    }
}

// MARK: - Primary Button Style
struct PrimaryButtonStyle: ButtonStyle {
    let size: ButtonSize
    let isFullWidth: Bool
    let isDisabled: Bool

    init(size: ButtonSize = .medium, isFullWidth: Bool = false, isDisabled: Bool = false) {
        self.size = size
        self.isFullWidth = isFullWidth
        self.isDisabled = isDisabled
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(isDisabled ? .textTertiary : .textOnDark)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.button)
                    .fill(isDisabled ? .buttonSecondary : .buttonPrimary)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .buttonShadow()
    }
}

// MARK: - Secondary Button Style
struct SecondaryButtonStyle: ButtonStyle {
    let size: ButtonSize
    let isFullWidth: Bool
    let isDisabled: Bool

    init(size: ButtonSize = .medium, isFullWidth: Bool = false, isDisabled: Bool = false) {
        self.size = size
        self.isFullWidth = isFullWidth
        self.isDisabled = isDisabled
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(isDisabled ? .textTertiary : .textPrimary)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.button)
                    .fill(isDisabled ? .backgroundTertiary : .buttonSecondary)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Outline Button Style
struct OutlineButtonStyle: ButtonStyle {
    let size: ButtonSize
    let isFullWidth: Bool
    let isDisabled: Bool

    init(size: ButtonSize = .medium, isFullWidth: Bool = false, isDisabled: Bool = false) {
        self.size = size
        self.isFullWidth = isFullWidth
        self.isDisabled = isDisabled
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(isDisabled ? .textTertiary : .buttonPrimary)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.button)
                    .fill(.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.button)
                            .stroke(
                                isDisabled ? .textTertiary : .buttonPrimary,
                                lineWidth: Border.medium
                            )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Ghost Button Style
struct GhostButtonStyle: ButtonStyle {
    let size: ButtonSize
    let isFullWidth: Bool
    let isDisabled: Bool

    init(size: ButtonSize = .medium, isFullWidth: Bool = false, isDisabled: Bool = false) {
        self.size = size
        self.isFullWidth = isFullWidth
        self.isDisabled = isDisabled
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(isDisabled ? .textTertiary : .buttonPrimary)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.button)
                    .fill(configuration.isPressed ? .buttonSecondary : .clear)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Destructive Button Style
struct DestructiveButtonStyle: ButtonStyle {
    let size: ButtonSize
    let isFullWidth: Bool
    let isDisabled: Bool

    init(size: ButtonSize = .medium, isFullWidth: Bool = false, isDisabled: Bool = false) {
        self.size = size
        self.isFullWidth = isFullWidth
        self.isDisabled = isDisabled
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .foregroundColor(isDisabled ? .textTertiary : .textOnDark)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.button)
                    .fill(isDisabled ? .buttonSecondary : .error)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .buttonShadow()
    }
}

// MARK: - Floating Action Button Style
struct FloatingActionButtonStyle: ButtonStyle {
    let size: CGFloat
    let isDisabled: Bool

    init(size: CGFloat = 56, isDisabled: Bool = false) {
        self.size = size
        self.isDisabled = isDisabled
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.4, weight: .medium))
            .foregroundColor(isDisabled ? .textTertiary : .textOnDark)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(
                        isDisabled
                        ? LinearGradient(
                            gradient: Gradient(colors: [.buttonSecondary, .buttonSecondary]),
                            startPoint: .top,
                            endPoint: .bottom
                          )
                        : .primaryGradient
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .shadow(
                color: isDisabled ? .clear : .cardShadow,
                radius: configuration.isPressed ? 4 : 8,
                x: 0,
                y: configuration.isPressed ? 2 : 4
            )
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Icon Button Style
struct IconButtonStyle: ButtonStyle {
    let size: ButtonSize
    let style: MiraButtonStyle
    let isDisabled: Bool

    init(size: ButtonSize = .medium, style: MiraButtonStyle = .ghost, isDisabled: Bool = false) {
        self.size = size
        self.style = style
        self.isDisabled = isDisabled
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size.iconSize, weight: .medium))
            .foregroundColor(isDisabled ? .textTertiary : style.foregroundColor)
            .frame(width: size.height, height: size.height)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.button)
                    .fill(isDisabled ? .backgroundTertiary : style.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.button)
                            .stroke(
                                isDisabled ? .clear : style.borderColor,
                                lineWidth: style.borderWidth
                            )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - View Extensions for Button Styles
extension View {
    // MARK: - Primary Button Styles
    func primaryButtonStyle(
        size: ButtonSize = .medium,
        isFullWidth: Bool = false,
        isDisabled: Bool = false
    ) -> some View {
        self.buttonStyle(PrimaryButtonStyle(
            size: size,
            isFullWidth: isFullWidth,
            isDisabled: isDisabled
        ))
    }

    func secondaryButtonStyle(
        size: ButtonSize = .medium,
        isFullWidth: Bool = false,
        isDisabled: Bool = false
    ) -> some View {
        self.buttonStyle(SecondaryButtonStyle(
            size: size,
            isFullWidth: isFullWidth,
            isDisabled: isDisabled
        ))
    }

    func outlineButtonStyle(
        size: ButtonSize = .medium,
        isFullWidth: Bool = false,
        isDisabled: Bool = false
    ) -> some View {
        self.buttonStyle(OutlineButtonStyle(
            size: size,
            isFullWidth: isFullWidth,
            isDisabled: isDisabled
        ))
    }

    func ghostButtonStyle(
        size: ButtonSize = .medium,
        isFullWidth: Bool = false,
        isDisabled: Bool = false
    ) -> some View {
        self.buttonStyle(GhostButtonStyle(
            size: size,
            isFullWidth: isFullWidth,
            isDisabled: isDisabled
        ))
    }

    func destructiveButtonStyle(
        size: ButtonSize = .medium,
        isFullWidth: Bool = false,
        isDisabled: Bool = false
    ) -> some View {
        self.buttonStyle(DestructiveButtonStyle(
            size: size,
            isFullWidth: isFullWidth,
            isDisabled: isDisabled
        ))
    }

    func floatingActionButtonStyle(
        size: CGFloat = 56,
        isDisabled: Bool = false
    ) -> some View {
        self.buttonStyle(FloatingActionButtonStyle(
            size: size,
            isDisabled: isDisabled
        ))
    }

    func iconButtonStyle(
        size: ButtonSize = .medium,
        style: MiraButtonStyle = .ghost,
        isDisabled: Bool = false
    ) -> some View {
        self.buttonStyle(IconButtonStyle(
            size: size,
            style: style,
            isDisabled: isDisabled
        ))
    }
}
