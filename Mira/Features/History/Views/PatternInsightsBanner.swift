import SwiftUI

/// Banner displaying pattern insights from scan history
struct PatternInsightsBanner: View {
    let patterns: [HistoryPattern]
    let onViewInsights: () -> Void

    var body: some View {
        if !patterns.isEmpty {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.caption)
                        .foregroundColor(.primaryBlue)

                    Text("Your Patterns")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    Button {
                        onViewInsights()
                    } label: {
                        HStack(spacing: 4) {
                            Text("See All")
                                .font(.caption)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                        }
                        .foregroundColor(.primaryBlue)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)

                Divider()

                // Pattern cards
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.md) {
                        ForEach(patterns.prefix(3)) { pattern in
                            CompactPatternCard(pattern: pattern)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                }
            }
            .background(Color.backgroundSecondary)
            .cornerRadius(CornerRadius.card)
        }
    }
}

/// Individual pattern card for horizontal scroll
private struct CompactPatternCard: View {
    let pattern: HistoryPattern

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Icon and title
            HStack(spacing: Spacing.xs) {
                Image(systemName: pattern.iconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(severityColor)

                Text(pattern.title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
            }

            // Message
            Text(pattern.message)
                .font(.caption2)
                .foregroundColor(.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Recommendation (if present)
            if let recommendation = pattern.recommendation {
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)

                    Text(recommendation)
                        .font(.caption2)
                        .foregroundColor(.textTertiary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 2)
            }
        }
        .padding(Spacing.sm)
        .frame(width: 220)
        .background(Color.backgroundPrimary)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .strokeBorder(severityBorderColor, lineWidth: 1)
        )
    }

    private var severityColor: Color {
        switch pattern.severity {
        case .positive: return .scoreExcellent
        case .neutral: return .primaryBlue
        case .attention: return .orange
        }
    }

    private var severityBorderColor: Color {
        severityColor.opacity(0.2)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.lg) {
        // With patterns
        PatternInsightsBanner(
            patterns: [
                HistoryPattern(
                    type: .categoryDominance,
                    title: "45% Snacks",
                    message: "You've been scanning mostly snack products",
                    recommendation: "Try adding more variety to balance your micronutrient intake",
                    severity: .attention,
                    iconName: "chart.pie.fill"
                ),
                HistoryPattern(
                    type: .scoreTrend,
                    title: "Scores Improving",
                    message: "Your average score improved by 8 points",
                    recommendation: "Keep up the great work choosing healthier options!",
                    severity: .positive,
                    iconName: "chart.line.uptrend.xyaxis"
                ),
                HistoryPattern(
                    type: .varietyIssue,
                    title: "Great Product Variety",
                    message: "You're exploring many different products",
                    recommendation: nil,
                    severity: .positive,
                    iconName: "sparkles"
                )
            ],
            onViewInsights: {}
        )
        .padding()

        Spacer()
    }
    .background(Color.backgroundPrimary)
}
