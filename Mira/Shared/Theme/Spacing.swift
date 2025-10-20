import SwiftUI

// MARK: - Spacing System
struct Spacing {
    // MARK: - Base Spacing Unit (4pt)
    static let unit: CGFloat = 4

    // MARK: - Spacing Scale
    /// 2pt - Minimal spacing
    static let xxs: CGFloat = unit * 0.5

    /// 4pt - Extra small spacing
    static let xs: CGFloat = unit

    /// 8pt - Small spacing
    static let sm: CGFloat = unit * 2

    /// 12pt - Medium-small spacing
    static let md: CGFloat = unit * 3

    /// 16pt - Medium spacing (most common)
    static let lg: CGFloat = unit * 4

    /// 20pt - Medium-large spacing
    static let xl: CGFloat = unit * 5

    /// 24pt - Large spacing
    static let xxl: CGFloat = unit * 6

    /// 32pt - Extra large spacing
    static let xxxl: CGFloat = unit * 8

    /// 40pt - Huge spacing
    static let huge: CGFloat = unit * 10

    /// 48pt - Massive spacing
    static let massive: CGFloat = unit * 12

    // MARK: - Semantic Spacing
    /// Standard padding for cards and containers
    static let cardPadding: CGFloat = lg

    /// Standard padding for screen edges
    static let screenPadding: CGFloat = lg

    /// Standard spacing between sections
    static let sectionSpacing: CGFloat = xxl

    /// Standard spacing between related elements
    static let elementSpacing: CGFloat = md

    /// Standard spacing between components
    static let componentSpacing: CGFloat = lg

    /// Tight spacing for compact layouts
    static let tightSpacing: CGFloat = xs

    /// Loose spacing for spacious layouts
    static let looseSpacing: CGFloat = xl
}

// MARK: - Corner Radius System
struct CornerRadius {
    // MARK: - Corner Radius Scale
    /// 4pt - Small corner radius
    static let xs: CGFloat = 4

    /// 8pt - Medium corner radius (standard)
    static let sm: CGFloat = 8

    /// 12pt - Large corner radius
    static let md: CGFloat = 12

    /// 16pt - Extra large corner radius
    static let lg: CGFloat = 16

    /// 20pt - Huge corner radius
    static let xl: CGFloat = 20

    /// 24pt - Massive corner radius
    static let xxl: CGFloat = 24

    // MARK: - Semantic Corner Radius
    /// Standard corner radius for buttons
    static let button: CGFloat = sm

    /// Standard corner radius for cards
    static let card: CGFloat = md

    /// Corner radius for input fields
    static let input: CGFloat = sm

    /// Corner radius for large containers
    static let container: CGFloat = lg

    /// Corner radius for pills and badges
    static let pill: CGFloat = 100 // Fully rounded

    /// Corner radius for images
    static let image: CGFloat = md
}

// MARK: - Shadow System
struct Shadow {
    // MARK: - Shadow Definitions
    static let none = ShadowStyle(
        color: .clear,
        radius: 0,
        x: 0,
        y: 0
    )

    static let xs = ShadowStyle(
        color: .cardShadow,
        radius: 2,
        x: 0,
        y: 1
    )

    static let sm = ShadowStyle(
        color: .cardShadow,
        radius: 4,
        x: 0,
        y: 2
    )

    static let md = ShadowStyle(
        color: .cardShadow,
        radius: 8,
        x: 0,
        y: 4
    )

    static let lg = ShadowStyle(
        color: .cardShadow,
        radius: 16,
        x: 0,
        y: 8
    )

    static let xl = ShadowStyle(
        color: .cardShadow,
        radius: 24,
        x: 0,
        y: 12
    )

    // MARK: - Semantic Shadows
    static let card = sm
    static let button = xs
    static let floating = md
    static let modal = lg
    static let tooltip = xs
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Border System
struct Border {
    // MARK: - Border Widths
    static let thin: CGFloat = 0.5
    static let medium: CGFloat = 1
    static let thick: CGFloat = 2
    static let heavy: CGFloat = 4

    // MARK: - Semantic Border Widths
    static let card: CGFloat = thin
    static let input: CGFloat = medium
    static let focus: CGFloat = thick
    static let accent: CGFloat = thick
}

// MARK: - Size System
struct Size {
    // MARK: - Icon Sizes
    static let iconXS: CGFloat = 12
    static let iconSM: CGFloat = 16
    static let iconMD: CGFloat = 20
    static let iconLG: CGFloat = 24
    static let iconXL: CGFloat = 32
    static let iconXXL: CGFloat = 48

    // MARK: - Button Sizes
    static let buttonHeightSM: CGFloat = 32
    static let buttonHeightMD: CGFloat = 44
    static let buttonHeightLG: CGFloat = 56

    // MARK: - Input Sizes
    static let inputHeightSM: CGFloat = 36
    static let inputHeightMD: CGFloat = 44
    static let inputHeightLG: CGFloat = 52

    // MARK: - Component Sizes
    static let avatarXS: CGFloat = 24
    static let avatarSM: CGFloat = 32
    static let avatarMD: CGFloat = 40
    static let avatarLG: CGFloat = 56
    static let avatarXL: CGFloat = 80

    static let scoreGaugeSM: CGFloat = 60
    static let scoreGaugeMD: CGFloat = 100
    static let scoreGaugeLG: CGFloat = 140
    static let scoreGaugeXL: CGFloat = 180

    // MARK: - Icon Container Sizes
    static let iconContainerSM: CGFloat = 24
    static let iconContainerMD: CGFloat = 32
    static let iconContainerLG: CGFloat = 40
    static let iconContainerXL: CGFloat = 48

    // MARK: - Layout Sizes
    static let tabBarHeight: CGFloat = 49
    static let navigationBarHeight: CGFloat = 44
    static let toolbarHeight: CGFloat = 44
}

// MARK: - View Modifiers for Spacing
extension View {
    // MARK: - Padding Modifiers
    func paddingXS() -> some View {
        self.padding(Spacing.xs)
    }

    func paddingSM() -> some View {
        self.padding(Spacing.sm)
    }

    func paddingMD() -> some View {
        self.padding(Spacing.md)
    }

    func paddingLG() -> some View {
        self.padding(Spacing.lg)
    }

    func paddingXL() -> some View {
        self.padding(Spacing.xl)
    }

    func paddingXXL() -> some View {
        self.padding(Spacing.xxl)
    }

    // MARK: - Directional Padding
    func horizontalPadding(_ spacing: CGFloat = Spacing.lg) -> some View {
        self.padding(.horizontal, spacing)
    }

    func verticalPadding(_ spacing: CGFloat = Spacing.lg) -> some View {
        self.padding(.vertical, spacing)
    }

    // MARK: - Corner Radius Modifiers
    func cornerRadiusXS() -> some View {
        self.cornerRadius(CornerRadius.xs)
    }

    func cornerRadiusSM() -> some View {
        self.cornerRadius(CornerRadius.sm)
    }

    func cornerRadiusMD() -> some View {
        self.cornerRadius(CornerRadius.md)
    }

    func cornerRadiusLG() -> some View {
        self.cornerRadius(CornerRadius.lg)
    }

    // MARK: - Shadow Modifiers
    func shadowXS() -> some View {
        let shadow = Shadow.xs
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }

    func shadowSM() -> some View {
        let shadow = Shadow.sm
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }

    func shadowMD() -> some View {
        let shadow = Shadow.md
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }

    func shadowLG() -> some View {
        let shadow = Shadow.lg
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }

    func cardShadow() -> some View {
        self.shadowSM()
    }

    func buttonShadow() -> some View {
        self.shadowXS()
    }
}