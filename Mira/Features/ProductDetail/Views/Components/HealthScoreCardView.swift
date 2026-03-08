import SwiftUI

/// Displays the health score with gauge, focus pill, component breakdown, and explanation
struct HealthScoreCardView: View {
    let healthScore: HealthScore
    var healthFocus: HealthFocus = .generalWellness

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Title
            HStack {
                Text("Health Score")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }

            HStack(alignment: .top, spacing: Spacing.lg) {
                // Left column: Overall score (just gauge and focus pill)
                VStack(spacing: Spacing.sm) {
                    // Score gauge (score shown inside donut) with confidence badge
                    ScoreGauge(
                        score: healthScore.overall,
                        size: 100,
                        confidence: healthScore.confidence
                    )

                    // Focus pill
                    Text(healthFocus.displayName)
                        .font(.caption)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.primaryBlue.opacity(0.12))
                        .foregroundColor(.primaryBlue)
                        .cornerRadius(CornerRadius.pill)
                }

                // Right side: Component scores grid (no weight badges)
                VStack(spacing: Spacing.sm) {
                    // Get top 4 components to display
                    let topComponents = Array(healthScore.breakdown.prefix(4))

                    ForEach(topComponents, id: \.componentName) { component in
                        ComponentScoreRow(component: component)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            // Bottom section - spans full width
            VStack(spacing: Spacing.sm) {
                // Microcopy hints
                if let bestArea = healthScore.breakdown.max(by: { $0.rawScore < $1.rawScore }),
                   let weakArea = healthScore.breakdown.min(by: { $0.rawScore < $1.rawScore }) {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        if bestArea.rawScore >= 70 {
                            Text("Best area: \(bestArea.componentName)")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        if weakArea.rawScore < 70 {
                            Text("Needs attention: \(weakArea.componentName)")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Narrative copy in disclosure group
                DisclosureGroup("Why this matters") {
                    Text(healthScore.explanation)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .padding(.top, Spacing.xs)
                }
                .font(.caption)
                .foregroundColor(.textPrimary)
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.card)
    }
}

/// Component score row for the right-side grid (no weight badge)
struct ComponentScoreRow: View {
    let component: ComponentBreakdown

    var body: some View {
        HStack(spacing: Spacing.xs) {
            // Label
            Text(component.componentName)
                .font(.caption)
                .foregroundColor(.textSecondary)
                .lineLimit(1)

            Spacer()

            // Score value (color-coded)
            Text("\(Int(component.rawScore))")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color.scoreColor(for: component.rawScore))
        }
        .padding(.vertical, Spacing.xxs)
    }
}
