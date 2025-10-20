import SwiftUI

/// Displays a detailed breakdown of how each scoring component contributed to the overall health score
struct ScoreBreakdownView: View {
    let healthScore: HealthScore

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Score Breakdown")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal, Spacing.md)

            VStack(spacing: Spacing.md) {
                ForEach(healthScore.breakdown, id: \.componentName) { component in
                    ComponentScoreCard(component: component)
                }
            }
            .padding(.horizontal, Spacing.md)
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
            // Header with component name only
            Text(component.componentName)
                .font(.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)

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

#Preview {
    let sampleBreakdown = [
        ComponentBreakdown(
            componentName: "Macronutrients",
            rawScore: 85.0,
            weight: 0.35,
            weightedScore: 29.75,
            explanation: "Heart health analysis: Low cholesterol (30mg); heart-friendly amount. Excellent sodium level (300mg); AHA recommends ≤1.5g sodium per day; this translates to ~500mg per serving",
            keyFactors: ["Cholesterol: 30mg", "Sodium: 300mg", "Fiber: 5.0g"]
        ),
        ComponentBreakdown(
            componentName: "Micronutrients",
            rawScore: 60.0,
            weight: 0.2,
            weightedScore: 12.0,
            explanation: "Good nutrient density based on protein (10.0g) and fiber (5.0g). Note: Full micronutrient data not available—score uses proxy.",
            keyFactors: ["Iron", "Vitamin B12", "Zinc", "Magnesium", "Vitamin E", "Folate"]
        ),
        ComponentBreakdown(
            componentName: "Processing Level",
            rawScore: 80.0,
            weight: 0.15,
            weightedScore: 12.0,
            explanation: "Processing level: Minimally Processed. Based on NOVA classification: minimize ultra-processed foods (Group 4)",
            keyFactors: ["Processing: Minimally Processed"]
        ),
        ComponentBreakdown(
            componentName: "Ingredient Quality",
            rawScore: 70.0,
            weight: 0.2,
            weightedScore: 14.0,
            explanation: "Ingredient quality could be improved (2 beneficial out of 8 total)",
            keyFactors: ["Total ingredients: 8", "Beneficial ingredients: 2"]
        ),
        ComponentBreakdown(
            componentName: "Additives",
            rawScore: 95.0,
            weight: 0.1,
            weightedScore: 9.5,
            explanation: "Minimal harmful additives detected (0 harmful, 1 total)",
            keyFactors: ["Total additives: 1", "Harmful additives: 0"]
        )
    ]

    let sampleScore = HealthScore(
        overall: 77.25,
        components: ScoreComponents(
            macronutrientBalance: ComponentScore(score: 85, weight: 0.35, explanation: "", recommendations: []),
            micronutrientDensity: ComponentScore(score: 60, weight: 0.2, explanation: "", recommendations: []),
            processingLevel: ComponentScore(score: 80, weight: 0.15, explanation: "", recommendations: []),
            ingredientQuality: ComponentScore(score: 70, weight: 0.2, explanation: "", recommendations: []),
            additives: ComponentScore(score: 95, weight: 0.1, explanation: "", recommendations: [])
        ),
        explanation: "Sample explanation",
        focus: .heartHealth,
        breakdown: sampleBreakdown,
        adjustments: [],
        confidence: .high,
        confidenceWarning: nil
    )

    ScoreBreakdownView(healthScore: sampleScore)
        .padding()
        .background(Color.backgroundPrimary)
}
