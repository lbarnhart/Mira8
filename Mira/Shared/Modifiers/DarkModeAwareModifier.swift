import SwiftUI

// MARK: - Dark Mode Aware Card Modifier

/// Applies dark mode optimized styling to cards and containers
struct DarkModeCardModifier: ViewModifier {
    let elevation: Int
    let cornerRadius: CGFloat

    init(elevation: Int = 1, cornerRadius: CGFloat = CornerRadius.card) {
        self.elevation = elevation
        self.cornerRadius = cornerRadius
    }

    func body(content: Content) -> some View {
        content
            .background(Color.cardBackground)
            .cornerRadius(cornerRadius)
            .shadow(
                color: Color.cardShadow,
                radius: CGFloat(elevation * 4),
                x: 0,
                y: CGFloat(elevation * 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.elevationOverlay(level: elevation), lineWidth: 0.5)
            )
    }
}

extension View {
    /// Applies dark mode optimized card styling
    /// - Parameters:
    ///   - elevation: Elevation level (1-3)
    ///   - cornerRadius: Corner radius
    func darkModeCard(elevation: Int = 1, cornerRadius: CGFloat = CornerRadius.card) -> some View {
        modifier(DarkModeCardModifier(elevation: elevation, cornerRadius: cornerRadius))
    }
}

// MARK: - Dark Mode Aware Text Modifier

/// Ensures text has proper contrast in dark mode
struct DarkModeTextModifier: ViewModifier {
    let style: TextStyle

    enum TextStyle {
        case primary
        case secondary
        case tertiary
        case onAccent
        case onCard

        var color: Color {
            switch self {
            case .primary: return .textPrimary
            case .secondary: return .textSecondary
            case .tertiary: return .textTertiary
            case .onAccent: return .textOnDark
            case .onCard: return .textPrimary
            }
        }
    }

    func body(content: Content) -> some View {
        content
            .foregroundColor(style.color)
    }
}

extension View {
    /// Applies dark mode optimized text color
    func darkModeText(_ style: DarkModeTextModifier.TextStyle = .primary) -> some View {
        modifier(DarkModeTextModifier(style: style))
    }
}

// MARK: - Dark Mode Aware Separator

struct DarkModeSeparator: View {
    var body: some View {
        Rectangle()
            .fill(Color.separatorEnhanced)
            .frame(height: 1)
    }
}

// MARK: - Dark Mode Preview Helper

/// Wrapper for previewing light and dark modes side by side
struct DarkModePreview<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Light mode
            content
                .environment(\.colorScheme, .light)
                .previewDisplayName("Light Mode")

            Divider()
                .frame(height: 4)
                .background(Color.gray)

            // Dark mode
            content
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Dark Mode")
        }
    }
}

// MARK: - Dark Mode Environment Helper

extension View {
    /// Forces a specific color scheme for testing
    func forceColorScheme(_ scheme: ColorScheme) -> some View {
        environment(\.colorScheme, scheme)
    }
}
