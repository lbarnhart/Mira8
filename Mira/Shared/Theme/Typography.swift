import SwiftUI

// MARK: - Typography System
extension Font {
    // MARK: - Display Fonts (Large, attention-grabbing)
    /// Large display font for hero sections
    static let displayLarge = Font.system(size: 57, weight: .bold, design: .rounded)
    /// Medium display font for prominent headings
    static let displayMedium = Font.system(size: 45, weight: .bold, design: .rounded)
    /// Small display font for section headers
    static let displaySmall = Font.system(size: 36, weight: .semibold, design: .rounded)

    // MARK: - Headline Fonts
    /// Large headline for main titles
    static let headlineLarge = Font.system(size: 32, weight: .bold, design: .default)
    /// Medium headline for section titles
    static let headlineMedium = Font.system(size: 28, weight: .semibold, design: .default)
    /// Small headline for subsection titles
    static let headlineSmall = Font.system(size: 24, weight: .semibold, design: .default)

    // MARK: - Title Fonts
    /// Large title for prominent content
    static let titleLarge = Font.system(size: 22, weight: .medium, design: .default)
    /// Medium title for cards and sections
    static let titleMedium = Font.system(size: 20, weight: .medium, design: .default)
    /// Small title for compact layouts
    static let titleSmall = Font.system(size: 18, weight: .medium, design: .default)

    // MARK: - Body Text
    /// Large body text for important content
    static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
    /// Medium body text (standard)
    static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
    /// Small body text for supporting content
    static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)

    // MARK: - Caption Text
    /// Large caption for prominent metadata
    static let captionLarge = Font.system(size: 13, weight: .medium, design: .default)
    /// Medium caption for secondary metadata
    static let captionMedium = Font.system(size: 12, weight: .medium, design: .default)
    /// Small caption for subtle metadata
    static let captionSmall = Font.system(size: 11, weight: .regular, design: .default)

    // MARK: - Label Text
    /// Large labels for form inputs
    static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
    /// Medium labels for standard UI
    static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
    /// Small labels for metadata
    static let labelSmall = Font.system(size: 10, weight: .medium, design: .default)

    // MARK: - Special Purpose Fonts
    /// Score display with rounded design
    static let scoreDisplay = Font.system(size: 48, weight: .bold, design: .rounded)
    /// Large score display
    static let scoreLarge = Font.system(size: 32, weight: .bold, design: .rounded)
    /// Medium score display
    static let scoreMedium = Font.system(size: 24, weight: .semibold, design: .rounded)

    /// Button text
    static let buttonLarge = Font.system(size: 17, weight: .semibold, design: .default)
    static let buttonMedium = Font.system(size: 15, weight: .semibold, design: .default)
    static let buttonSmall = Font.system(size: 13, weight: .medium, design: .default)

    /// Navigation elements
    static let navigationTitle = Font.system(size: 17, weight: .semibold, design: .default)
    static let tabBar = Font.system(size: 10, weight: .medium, design: .default)

    /// Monospace for numbers and data
    static let monoLarge = Font.system(size: 16, weight: .regular, design: .monospaced)
    static let monoMedium = Font.system(size: 14, weight: .regular, design: .monospaced)
    static let monoSmall = Font.system(size: 12, weight: .regular, design: .monospaced)
}

// MARK: - Text Style Extensions
extension Text {
    // MARK: - Display Styles
    func displayLargeStyle() -> some View {
        self.font(.displayLarge)
            .foregroundColor(.textPrimary)
    }

    func displayMediumStyle() -> some View {
        self.font(.displayMedium)
            .foregroundColor(.textPrimary)
    }

    func displaySmallStyle() -> some View {
        self.font(.displaySmall)
            .foregroundColor(.textPrimary)
    }

    // MARK: - Headline Styles
    func headlineLargeStyle() -> some View {
        self.font(.headlineLarge)
            .foregroundColor(.textPrimary)
    }

    func headlineMediumStyle() -> some View {
        self.font(.headlineMedium)
            .foregroundColor(.textPrimary)
    }

    func headlineSmallStyle() -> some View {
        self.font(.headlineSmall)
            .foregroundColor(.textPrimary)
    }

    // MARK: - Title Styles
    func titleLargeStyle() -> some View {
        self.font(.titleLarge)
            .foregroundColor(.textPrimary)
    }

    func titleMediumStyle() -> some View {
        self.font(.titleMedium)
            .foregroundColor(.textPrimary)
    }

    func titleSmallStyle() -> some View {
        self.font(.titleSmall)
            .foregroundColor(.textPrimary)
    }

    // MARK: - Body Styles
    func bodyLargeStyle() -> some View {
        self.font(.bodyLarge)
            .foregroundColor(.textPrimary)
            .lineSpacing(2)
    }

    func bodyMediumStyle() -> some View {
        self.font(.bodyMedium)
            .foregroundColor(.textSecondary)
            .lineSpacing(1)
    }

    func bodySmallStyle() -> some View {
        self.font(.bodySmall)
            .foregroundColor(.textTertiary)
    }

    // MARK: - Caption Styles
    func captionLargeStyle() -> some View {
        self.font(.captionLarge)
            .foregroundColor(.textSecondary)
    }

    func captionMediumStyle() -> some View {
        self.font(.captionMedium)
            .foregroundColor(.textSecondary)
    }

    func captionSmallStyle() -> some View {
        self.font(.captionSmall)
            .foregroundColor(.textTertiary)
    }

    // MARK: - Label Styles
    func labelLargeStyle() -> some View {
        self.font(.labelLarge)
            .foregroundColor(.textSecondary)
    }

    func labelMediumStyle() -> some View {
        self.font(.labelMedium)
            .foregroundColor(.textSecondary)
    }

    func labelSmallStyle() -> some View {
        self.font(.labelSmall)
            .foregroundColor(.textTertiary)
    }

    // MARK: - Special Styles
    func scoreStyle(_ score: Double) -> some View {
        self.font(.scoreDisplay)
            .foregroundColor(.scoreColor(for: score))
            .fontWeight(.bold)
    }

    func buttonStyle() -> some View {
        self.font(.buttonLarge)
            .foregroundColor(.textOnDark)
    }

    func navigationStyle() -> some View {
        self.font(.navigationTitle)
            .foregroundColor(.textPrimary)
    }

    func monoStyle() -> some View {
        self.font(.monoMedium)
            .foregroundColor(.textSecondary)
    }

    // MARK: - Utility Styles
    func emphasized() -> some View {
        self.fontWeight(.semibold)
            .foregroundColor(.textPrimary)
    }

    func subtle() -> some View {
        self.foregroundColor(.textTertiary)
    }

    func onDark() -> some View {
        self.foregroundColor(.textOnDark)
    }

    func branded() -> some View {
        self.foregroundColor(.primary)
    }
}

// MARK: - Line Height and Spacing
extension Text {
    func withOptimalLineHeight() -> some View {
        self.lineSpacing(2)
    }

    func withTightLineHeight() -> some View {
        self.lineSpacing(0)
    }

    func withLooseLineHeight() -> some View {
        self.lineSpacing(6)
    }
}

// MARK: - View-level helpers for non-Text views
// Mirrors a subset of Text style helpers so they can be applied to views like TextField and Button labels
extension View {
    func bodyMediumStyle() -> some View {
        self.font(.bodyMedium)
            .foregroundColor(.textSecondary)
            .lineSpacing(1)
    }

    func captionMediumStyle() -> some View {
        self.font(.captionMedium)
            .foregroundColor(.textSecondary)
    }
}
