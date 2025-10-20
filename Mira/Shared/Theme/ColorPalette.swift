import SwiftUI
import Foundation
import UIKit

extension Color {
    // MARK: - Primary Brand Colors
    /// Ocean Teal - Primary brand color (#2B9B96)
    static let oceanTeal = Color(hex: "2B9B96")

    /// Seafoam Green - Secondary brand color (#4CAF7D)
    static let seafoamGreen = Color(hex: "4CAF7D")

    /// Deep Forest - Dark accent (#1A5A4A)
    static let deepForest = Color(hex: "1A5A4A")

    /// Mint Fresh - Light accent (#67D4A5)
    static let mintFresh = Color(hex: "67D4A5")

    /// Aqua Marine - Vibrant accent (#38C4B8)
    static let aquaMarine = Color(hex: "38C4B8")

    /// Sage - Muted green (#7FB069)
    static let sage = Color(hex: "7FB069")

    // MARK: - Semantic Colors
    static let primary = oceanTeal
    static let secondary = seafoamGreen
    static let accent = mintFresh
    static let success = Color(hex: "34C759")
    static let warning = Color(hex: "FF9F0A")
    static let error = Color(hex: "FF453A")
    static let info = aquaMarine

    // MARK: - Score Colors
    static let scoreExcellent = Color(hex: "34C759") // iOS Green
    static let scoreGood = Color(hex: "32D74B")      // Lighter green
    static let scoreFair = Color(hex: "FF9F0A")      // iOS Orange
    static let scorePoor = Color(hex: "FF453A")      // iOS Red

    // MARK: - Background Colors (Auto dark mode support)
    static let backgroundPrimary = Color(.systemBackground)
    static let backgroundSecondary = Color(.secondarySystemBackground)
    static let backgroundTertiary = Color(.tertiarySystemBackground)
    static let backgroundGrouped = Color(.systemGroupedBackground)
    static let backgroundSecondaryGrouped = Color(.secondarySystemGroupedBackground)

    // MARK: - Card Colors
    static let cardBackground = Color(.systemBackground)
    static let cardBackgroundElevated = Color(.secondarySystemBackground)
    static let cardBorder = Color(.separator)
    static let cardShadow = Color.black.opacity(0.1)

    // MARK: - Text Colors (Auto dark mode support)
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    static let textQuaternary = Color(.quaternaryLabel)
    static let textOnDark = Color.white
    static let textOnLight = Color.black

    // MARK: - Interactive Colors
    static let tabBarSelected = primary
    static let tabBarUnselected = Color(.secondaryLabel)
    static let buttonPrimary = primary
    static let buttonSecondary = Color(.secondarySystemFill)
    static let buttonTertiary = Color(.tertiarySystemFill)

    // MARK: - Scanner Colors
    static let scannerBackground = Color.black
    static let scannerOverlay = Color.black.opacity(0.6)
    static let scannerFrame = mintFresh
    static let scannerGuide = aquaMarine
    static let scannerCorner = Color.white

    // MARK: - Nutrient Colors
    static let nutrientProtein = Color(hex: "FF6B6B")
    static let nutrientCarbs = Color(hex: "4ECDC4")
    static let nutrientFat = Color(hex: "45B7D1")
    static let nutrientFiber = Color(hex: "96CEB4")
    static let nutrientSugar = Color(hex: "FECA57")
    static let nutrientSodium = Color(hex: "FF9FF3")

    // MARK: - Helper Functions
    static func scoreColor(for score: Double) -> Color {
        switch score {
        case 80...100:
            return .scoreExcellent
        case 60..<80:
            return .scoreGood
        case 40..<60:
            return .scoreFair
        default:
            return .scorePoor
        }
    }

    // MARK: - Gradients
    static var primaryGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [primary, secondary]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var scannerGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.black,
                Color.black.opacity(0.8)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var cardGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                primary.opacity(0.05),
                secondary.opacity(0.02)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var scoreGradient: (Double) -> LinearGradient = { score in
        let color = scoreColor(for: score)
        return LinearGradient(
            gradient: Gradient(colors: [
                color,
                color.opacity(0.8)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // MARK: - Legacy Aliases (for compatibility)
    static let primaryBlue = oceanTeal
    static let primaryGreen = seafoamGreen
}

// MARK: - ShapeStyle adapters for Color usages
// Enable usages like `.background(.backgroundSecondary)` and `.fill(.error)`
extension ShapeStyle where Self == Color {
    // Brand
    static var oceanTeal: Color { Color.oceanTeal }
    static var seafoamGreen: Color { Color.seafoamGreen }
    static var deepForest: Color { Color.deepForest }
    static var mintFresh: Color { Color.mintFresh }
    static var aquaMarine: Color { Color.aquaMarine }
    static var sage: Color { Color.sage }

    // Semantic
    static var primary: Color { Color.primary }
    static var secondary: Color { Color.secondary }
    static var accent: Color { Color.accent }
    static var success: Color { Color.success }
    static var warning: Color { Color.warning }
    static var error: Color { Color.error }
    static var info: Color { Color.info }

    // Backgrounds
    static var backgroundPrimary: Color { Color.backgroundPrimary }
    static var backgroundSecondary: Color { Color.backgroundSecondary }
    static var backgroundTertiary: Color { Color.backgroundTertiary }
    static var backgroundGrouped: Color { Color.backgroundGrouped }
    static var backgroundSecondaryGrouped: Color { Color.backgroundSecondaryGrouped }

    // Cards
    static var cardBackground: Color { Color.cardBackground }
    static var cardBackgroundElevated: Color { Color.cardBackgroundElevated }
    static var cardBorder: Color { Color.cardBorder }
    static var cardShadow: Color { Color.cardShadow }

    // Text
    static var textPrimary: Color { Color.textPrimary }
    static var textSecondary: Color { Color.textSecondary }
    static var textTertiary: Color { Color.textTertiary }
    static var textQuaternary: Color { Color.textQuaternary }
    static var textOnDark: Color { Color.textOnDark }
    static var textOnLight: Color { Color.textOnLight }

    // Interactive
    static var tabBarSelected: Color { Color.tabBarSelected }
    static var tabBarUnselected: Color { Color.tabBarUnselected }
    static var buttonPrimary: Color { Color.buttonPrimary }
    static var buttonSecondary: Color { Color.buttonSecondary }
    static var buttonTertiary: Color { Color.buttonTertiary }
}

// MARK: - LinearGradient conveniences
extension LinearGradient {
    static var primaryGradient: LinearGradient { Color.primaryGradient }
    static var cardGradient: LinearGradient { Color.cardGradient }
}

// Allow `.fill(.primaryGradient)` style lookup
extension ShapeStyle where Self == LinearGradient {
    static var primaryGradient: LinearGradient { Color.primaryGradient }
    static var cardGradient: LinearGradient { Color.cardGradient }
}
