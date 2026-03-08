import SwiftUI

/// Displays a detailed breakdown of how each scoring component contributed to the overall health score
struct ScoreBreakdownView: View {
    let healthScore: HealthScore
    let healthFocus: HealthFocus

    @State private var selectedExplainer: ScoreExplainer?
    @State private var showExplainer = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Score Breakdown")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal, Spacing.md)

            VStack(spacing: Spacing.md) {
                ForEach(healthScore.breakdown, id: \.componentName) { component in
                    ComponentScoreCard(component: component)
                        .onTapGesture {
                            if let explainer = ExplainerLibrary.explainer(
                                for: component.componentName,
                                healthFocus: healthFocus
                            ) {
                                selectedExplainer = explainer
                                showExplainer = true
                            }
                        }
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .sheet(isPresented: $showExplainer) {
            if let explainer = selectedExplainer {
                ExplainerCard(explainer: explainer)
            }
        }
    }
}

/// Individual score card for each component showing weighted contribution
private struct ComponentScoreCard: View {
    let component: ComponentBreakdown
    @State private var showDetails = false

    // Use neutral blue color for all components
    private let neutralColor: Color = .primaryBlue

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header with component name and info icon
            HStack {
                Text(component.componentName)
                    .font(.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)

                Spacer()

                Image(systemName: "info.circle")
                    .font(.body)
                    .foregroundColor(.primaryBlue.opacity(0.7))
            }

            // Points earned out of maximum possible
            let maxPoints = component.weight * 100
            Text("\(component.weightedScore, specifier: "%.1f") of \(maxPoints, specifier: "%.0f") points")
                .font(.caption)
                .foregroundColor(.textSecondary)

            // Progress bar showing percentage of max points earned
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    // Filled portion based on percentage of max points
                    let percentage = maxPoints > 0 ? component.weightedScore / maxPoints : 0
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(neutralColor)
                        .frame(width: geometry.size.width * CGFloat(percentage), height: 8)
                }
            }
            .frame(height: 8)

            // Key factors as pills
            if !component.keyFactors.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(component.keyFactors, id: \.self) { factor in
                            Text(factor)
                                .font(.caption)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xxs)
                                .background(neutralColor.opacity(0.12))
                                .foregroundColor(neutralColor)
                                .cornerRadius(CornerRadius.pill)
                        }
                    }
                }
            }

            // Short description
            if !component.explanation.isEmpty {
                Text(component.explanation)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.md)
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.card)
    }
}

// Preview temporarily disabled during HealthScore model refactor
// TODO: Update preview once HealthScore model is finalized
