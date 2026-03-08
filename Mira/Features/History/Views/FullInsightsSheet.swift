import SwiftUI

/// Full-screen sheet showing detailed pattern insights
struct FullInsightsSheet: View {
    let patterns: [HistoryPattern]
    let timeframe: TimeframeFilter
    let onTimeframeChange: (TimeframeFilter) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Timeframe filter
                    timeframeSelector

                    if patterns.isEmpty {
                        emptyState
                    } else {
                        // Pattern cards
                        ForEach(patterns) { pattern in
                            DetailedPatternCard(pattern: pattern)
                        }
                    }
                }
                .padding()
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Your Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var timeframeSelector: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(TimeframeFilter.allCases, id: \.self) { filter in
                Button {
                    onTimeframeChange(filter)
                } label: {
                    Text(filter.rawValue)
                        .font(.caption)
                        .fontWeight(timeframe == filter ? .semibold : .regular)
                        .foregroundColor(timeframe == filter ? .white : .textSecondary)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(timeframe == filter ? Color.primaryBlue : Color.backgroundSecondary)
                        .cornerRadius(CornerRadius.pill)
                }
            }
        }
        .padding(.horizontal)
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundColor(.textTertiary)

            Text("No Patterns Yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)

            Text("Scan more products to see insights about your habits")
                .font(.callout)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 60)
    }
}

/// Detailed pattern card with full information
private struct DetailedPatternCard: View {
    let pattern: HistoryPattern

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header with icon and title
            HStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(severityColor.opacity(0.12))
                        .frame(width: 40, height: 40)

                    Image(systemName: pattern.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(severityColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(pattern.title)
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Text(patternTypeLabel)
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                        .textCase(.uppercase)
                }

                Spacer()

                severityBadge
            }

            Divider()

            // Message
            Text(pattern.message)
                .font(.callout)
                .foregroundColor(.textSecondary)

            // Recommendation
            if let recommendation = pattern.recommendation {
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.yellow)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recommendation")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.textSecondary)
                            .textCase(.uppercase)

                        Text(recommendation)
                            .font(.callout)
                            .foregroundColor(.textPrimary)
                    }
                }
                .padding(Spacing.sm)
                .background(Color.yellow.opacity(0.05))
                .cornerRadius(CornerRadius.sm)
            }
        }
        .padding(Spacing.md)
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.card)
    }

    private var severityColor: Color {
        switch pattern.severity {
        case .positive: return .scoreExcellent
        case .neutral: return .primaryBlue
        case .attention: return .orange
        }
    }

    private var severityBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: severityIconName)
                .font(.system(size: 10))
            Text(severityLabel)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(severityColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(severityColor.opacity(0.12))
        .cornerRadius(CornerRadius.pill)
    }

    private var severityIconName: String {
        switch pattern.severity {
        case .positive: return "checkmark.circle.fill"
        case .neutral: return "info.circle.fill"
        case .attention: return "exclamationmark.circle.fill"
        }
    }

    private var severityLabel: String {
        switch pattern.severity {
        case .positive: return "Great"
        case .neutral: return "Info"
        case .attention: return "Consider"
        }
    }

    private var patternTypeLabel: String {
        switch pattern.type {
        case .categoryDominance: return "Category"
        case .scoreTrend: return "Trend"
        case .dietaryCompliance: return "Dietary"
        case .nutritionGap: return "Nutrition"
        case .varietyIssue: return "Variety"
        }
    }
}

// MARK: - Preview

#Preview {
    FullInsightsSheet(
        patterns: [
            HistoryPattern(
                type: .scoreTrend,
                title: "Scores Improving",
                message: "Your average score improved by 8 points over the past week",
                recommendation: "Keep up the great work choosing healthier options!",
                severity: .positive,
                iconName: "chart.line.uptrend.xyaxis"
            ),
            HistoryPattern(
                type: .categoryDominance,
                title: "45% Snacks",
                message: "You've been scanning mostly snack products",
                recommendation: "Try adding more variety to balance your micronutrient intake",
                severity: .attention,
                iconName: "chart.pie.fill"
            ),
            HistoryPattern(
                type: .varietyIssue,
                title: "Great Product Variety",
                message: "You're exploring many different products (70% unique)",
                recommendation: nil,
                severity: .positive,
                iconName: "sparkles"
            )
        ],
        timeframe: .week,
        onTimeframeChange: { _ in }
    )
}
