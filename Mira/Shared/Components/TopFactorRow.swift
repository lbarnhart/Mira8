import SwiftUI

/// Displays a single nutrition factor with intelligent parsing, color-coding, and intensity indicators
/// Examples:
/// ✓ High protein (15g) ●●● [Green background]
/// ⚠️ High sugar (18g) ●●●● [Red background]
struct TopFactorRow: View {
    let factor: String
    @State private var isVisible = false

    private let positiveKeywords = ["good", "high protein", "high fiber", "rich", "excellent", "great"]
    private let negativeKeywords = ["high sugar", "high sodium", "high saturated fat", "excessive", "too much"]

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(factorColor)
                .frame(width: 24)

            // Factor text with bold value
            HStack(spacing: 4) {
                Text(factorLabel)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.primary)

                if let value = extractedValue {
                    Text(value)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }

            Spacer()

            // Intensity indicator (dots)
            intensityIndicator
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(factorColor.opacity(0.08))
        .cornerRadius(10)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.95, anchor: .leading)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                isVisible = true
            }
        }
    }

    // MARK: - Computed Properties

    private var factorType: FactorType {
        let lowerFactor = factor.lowercased()

        if factor.hasPrefix("✓") || lowerFactor.contains("good") {
            return .positive
        } else if factor.hasPrefix("⚠️") || negativeKeywords.contains(where: { lowerFactor.contains($0) }) {
            return .negative
        } else {
            return .neutral
        }
    }

    private var factorColor: Color {
        switch factorType {
        case .positive:
            return .green
        case .negative:
            return .red
        case .neutral:
            return .yellow
        }
    }

    private var iconName: String {
        switch factorType {
        case .positive:
            return "checkmark.circle.fill"
        case .negative:
            return "exclamationmark.triangle.fill"
        case .neutral:
            return "info.circle.fill"
        }
    }

    private var factorLabel: String {
        // Remove emoji prefix if present
        var text = factor
        if text.hasPrefix("✓ ") {
            text = String(text.dropFirst(2))
        } else if text.hasPrefix("⚠️ ") {
            text = String(text.dropFirst(2))
        }

        // Remove value in parentheses (will be extracted separately)
        if let rangeStart = text.firstIndex(of: "("),
           let _ = text.firstIndex(of: ")") {
            return String(text[..<rangeStart]).trimmingCharacters(in: .whitespaces)
        }

        return text
    }

    private var extractedValue: String? {
        if let rangeStart = factor.firstIndex(of: "("),
           let rangeEnd = factor.firstIndex(of: ")") {
            let value = String(factor[rangeStart...rangeEnd])
            return value
        }
        return nil
    }

    private var intensityLevel: Int {
        guard let valueStr = extractedValue else { return 1 }

        // Extract numeric value from parentheses
        let numericString = valueStr.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        guard let numericValue = Double(numericString) else { return 1 }

        // Determine intensity based on nutrient type and value
        let lowerFactor = factor.lowercased()

        // Protein: excellent (>15g), good (10-15g), medium (5-10g), low (<5g)
        if lowerFactor.contains("protein") {
            if numericValue >= 15 { return 4 }
            if numericValue >= 10 { return 3 }
            if numericValue >= 5 { return 2 }
            return 1
        }

        // Fiber: excellent (>6g), good (3-6g), medium (1-3g), low (<1g)
        if lowerFactor.contains("fiber") {
            if numericValue >= 6 { return 4 }
            if numericValue >= 3 { return 3 }
            if numericValue >= 1 { return 2 }
            return 1
        }

        // Sugar: low (<5g), medium (5-10g), high (10-20g), very high (>20g)
        if lowerFactor.contains("sugar") {
            if numericValue > 20 { return 4 }
            if numericValue > 10 { return 3 }
            if numericValue > 5 { return 2 }
            return 1
        }

        // Sodium: low (<200mg), medium (200-500mg), high (500-1000mg), very high (>1000mg)
        if lowerFactor.contains("sodium") {
            if numericValue > 1000 { return 4 }
            if numericValue > 500 { return 3 }
            if numericValue > 200 { return 2 }
            return 1
        }

        // Saturated Fat: low (<2g), medium (2-5g), high (5-10g), very high (>10g)
        if lowerFactor.contains("saturated fat") {
            if numericValue > 10 { return 4 }
            if numericValue > 5 { return 3 }
            if numericValue > 2 { return 2 }
            return 1
        }

        // Default: scale based on value
        if numericValue > 20 { return 4 }
        if numericValue > 10 { return 3 }
        if numericValue > 5 { return 2 }
        return 1
    }

    private var intensityIndicator: some View {
        HStack(spacing: 2) {
            ForEach(0..<intensityLevel, id: \.self) { _ in
                Circle()
                    .fill(factorColor)
                    .frame(width: 4, height: 4)
            }
        }
        .opacity(0.7)
    }
}

// MARK: - Factor Type Enum
enum FactorType {
    case positive
    case negative
    case neutral
}

// MARK: - Previews
#Preview("Positive Factors") {
    VStack(spacing: 12) {
        TopFactorRow(factor: "✓ High protein (15g)")
        TopFactorRow(factor: "Good fiber content (6.2g)")
        TopFactorRow(factor: "✓ Rich in potassium (280mg)")
    }
    .padding()
}

#Preview("Negative Factors") {
    VStack(spacing: 12) {
        TopFactorRow(factor: "⚠️ High sugar (18g)")
        TopFactorRow(factor: "High sodium (450mg)")
        TopFactorRow(factor: "⚠️ High saturated fat (12g)")
    }
    .padding()
}

#Preview("Mixed Factors") {
    VStack(spacing: 12) {
        TopFactorRow(factor: "✓ High protein (22g)")
        TopFactorRow(factor: "⚠️ High sugar (25g)")
        TopFactorRow(factor: "Good source of fiber (4g)")
        TopFactorRow(factor: "⚠️ High sodium (580mg)")
        TopFactorRow(factor: "✓ Contains probiotics")
    }
    .padding()
}
