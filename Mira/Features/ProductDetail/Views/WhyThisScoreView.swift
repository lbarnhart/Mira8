import SwiftUI

/// Modal view explaining why a product received its health score
/// Displays scoring factors, methodology, and actionable insights
struct WhyThisScoreView: View {
    let healthScore: HealthScore
    let productName: String
    @Environment(\.dismiss) private var dismiss
    
    private var positiveContributions: [NutrientContribution] {
        healthScore.contributions
            .filter { $0.kind == .positive && $0.weightedPoints > 0 }
            .sorted { $0.weightedPoints > $1.weightedPoints }
    }
    
    private var negativeContributions: [NutrientContribution] {
        healthScore.contributions
            .filter { $0.kind == .negative && $0.weightedPoints > 0 }
            .sorted { $0.weightedPoints > $1.weightedPoints }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Score summary header
                    scoreHeader
                    
                    // Key factors section
                    if !healthScore.topReasons.isEmpty {
                        keyFactorsSection
                    }
                    
                    // Detailed breakdown
                    if !positiveContributions.isEmpty || !negativeContributions.isEmpty {
                        detailedBreakdownSection
                    }
                    
                    // How we calculate section
                    methodologySection
                }
                .padding()
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Why This Score?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Score Header
    
    private var scoreHeader: some View {
        VStack(spacing: Spacing.md) {
            // Verdict with score
            HStack(spacing: Spacing.md) {
                // Score circle
                ZStack {
                    Circle()
                        .fill(verdictColor.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    VStack(spacing: 2) {
                        Text("\(Int(healthScore.overall))")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(verdictColor)
                        
                        Text("/ 100")
                            .font(.caption2)
                            .foregroundColor(.textTertiary)
                    }
                }
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(healthScore.verdict.label)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(verdictColor)
                    
                    Text(healthScore.verdict.message)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                    
                    if let categoryRank = healthScore.categoryRank {
                        Text(categoryRank)
                            .font(.caption)
                            .foregroundColor(.textTertiary)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color.backgroundSecondary)
            .cornerRadius(CornerRadius.md)
        }
    }
    
    // MARK: - Key Factors Section
    
    private var keyFactorsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Key Factors")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(healthScore.topReasons, id: \.self) { reason in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Image(systemName: factorIcon(for: reason))
                            .font(.system(size: 14))
                            .foregroundColor(factorColor(for: reason))
                            .frame(width: 20)
                        
                        Text(reason)
                            .font(.subheadline)
                            .foregroundColor(.textPrimary)
                    }
                }
            }
            .padding()
            .background(Color.backgroundSecondary)
            .cornerRadius(CornerRadius.md)
        }
    }
    
    // MARK: - Detailed Breakdown Section
    
    private var detailedBreakdownSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Score Breakdown")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            VStack(spacing: Spacing.md) {
                // Positive factors
                if !positiveContributions.isEmpty {
                    contributionGroup(
                        title: "Boosting Your Score",
                        icon: "arrow.up.circle.fill",
                        color: Color(red: 0.2, green: 0.7, blue: 0.4),
                        contributions: Array(positiveContributions.prefix(3))
                    )
                }
                
                // Negative factors
                if !negativeContributions.isEmpty {
                    contributionGroup(
                        title: "Lowering Your Score",
                        icon: "arrow.down.circle.fill",
                        color: Color(red: 0.95, green: 0.4, blue: 0.2),
                        contributions: Array(negativeContributions.prefix(3))
                    )
                }
            }
        }
    }
    
    private func contributionGroup(title: String, icon: String, color: Color, contributions: [NutrientContribution]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            ForEach(contributions) { contribution in
                HStack {
                    Text(contribution.label)
                        .font(.subheadline)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    if let value = contribution.value {
                        Text("\(formatValue(value, unit: contribution.unit))")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Text("+\(Int(contribution.weightedPoints)) pts")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(color)
                }
            }
        }
        .padding()
        .background(color.opacity(0.08))
        .cornerRadius(CornerRadius.sm)
    }
    
    // MARK: - Methodology Section
    
    private var methodologySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("How We Calculate")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            VStack(alignment: .leading, spacing: Spacing.md) {
                methodologyItem(
                    icon: "plus.circle.fill",
                    title: "Positive Nutrients",
                    description: "Protein, fiber, vitamins, and minerals add points to your score."
                )
                
                methodologyItem(
                    icon: "minus.circle.fill",
                    title: "Negative Nutrients",
                    description: "Sugar, sodium, and saturated fat reduce your score."
                )
                
                methodologyItem(
                    icon: "leaf.fill",
                    title: "Ingredient Quality",
                    description: "Whole foods and minimal processing boost your score."
                )
                
                methodologyItem(
                    icon: "exclamationmark.triangle.fill",
                    title: "Additives",
                    description: "Certain additives may lower the score based on health research."
                )
            }
            .padding()
            .background(Color.backgroundSecondary)
            .cornerRadius(CornerRadius.md)
            
            // Explanation text
            if !healthScore.explanation.isEmpty {
                Text(healthScore.explanation)
                    .font(.caption)
                    .foregroundColor(.textTertiary)
                    .padding(.top, Spacing.xs)
            }
        }
    }
    
    private func methodologyItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.primaryBlue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var verdictColor: Color {
        switch healthScore.verdict {
        case .excellent:
            return Color(red: 0.2, green: 0.7, blue: 0.4)
        case .good:
            return Color(red: 1.0, green: 0.8, blue: 0.0)
        case .okay:
            return Color(red: 1.0, green: 0.6, blue: 0.2)
        case .fair:
            return Color(red: 0.95, green: 0.5, blue: 0.2)
        case .avoid:
            return Color(red: 0.95, green: 0.2, blue: 0.2)
        }
    }
    
    private func factorIcon(for reason: String) -> String {
        if reason.contains("✓") || reason.contains("⭐") || reason.starts(with: "+") {
            return "checkmark.circle.fill"
        } else if reason.contains("⚠") || reason.contains("✗") {
            return "exclamationmark.circle.fill"
        } else if reason.contains("~") {
            return "minus.circle.fill"
        }
        return "circle.fill"
    }
    
    private func factorColor(for reason: String) -> Color {
        if reason.contains("✓") || reason.contains("⭐") || reason.starts(with: "+") {
            return Color(red: 0.2, green: 0.7, blue: 0.4)
        } else if reason.contains("⚠") || reason.contains("✗") {
            return Color(red: 0.95, green: 0.4, blue: 0.2)
        }
        return .textSecondary
    }
    
    private func formatValue(_ value: Double, unit: String) -> String {
        if value >= 1 {
            return "\(Int(value))\(unit)"
        } else {
            return String(format: "%.1f%@", value, unit)
        }
    }
}

#Preview {
    WhyThisScoreView(
        healthScore: HealthScore(
            rawScore: 75,
            overall: 72,
            tier: .good,
            grade: .b,
            explanation: "This product has a good nutritional profile with solid protein content.",
            confidence: .high,
            confidenceWarning: nil,
            confidenceRange: 70...74,
            rawPositivePoints: 25,
            rawNegativePoints: 15,
            weightedPositivePoints: 30,
            weightedNegativePoints: 18,
            contributions: [],
            breakdown: [],
            adjustments: [],
            topReasons: ["✓ Good protein content (8g)", "⚠️ Moderate sugar (12g)"],
            uxMessages: [],
            components: .empty,
            scoringResult: nil,
            verdict: .good,
            simplifiedDisplay: SimplifiedScoreDisplay(
                score: 72,
                verdict: .good,
                topFactors: ["Good protein", "Moderate sugar"],
                categoryContext: "Top 30% of yogurts"
            ),
            categoryPercentile: 70,
            categoryRank: "Top 30% of yogurts",
            nutriScoreVerdict: .good
        ),
        productName: "Greek Yogurt"
    )
}
