import SwiftUI

/// A sheet view that explains what a score component measures and why it matters
struct ExplainerCard: View {
    let explainer: ScoreExplainer
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                // Full background
                Color.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // Header icon and title
                        HStack(spacing: Spacing.md) {
                            Image(systemName: explainer.icon)
                                .font(.title)
                                .foregroundColor(.primaryBlue)
                                .frame(width: 44, height: 44)
                                .background(Color.primaryBlue.opacity(0.12))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text(explainer.componentName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.textPrimary)

                                Text(explainer.subtitle)
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .padding(.horizontal, Spacing.md)

                        Divider()
                            .padding(.horizontal, Spacing.md)

                        // What it measures
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Label("What it measures", systemImage: "chart.bar.fill")
                                .font(.headline)
                                .foregroundColor(.textPrimary)

                            Text(explainer.whatItMeasures)
                                .font(.body)
                                .foregroundColor(.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, Spacing.md)

                        // Why it matters (health focus specific)
                        if let whyItMatters = explainer.whyItMatters {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Label("Why it matters for your goals", systemImage: "star.fill")
                                    .font(.headline)
                                    .foregroundColor(.textPrimary)

                                Text(whyItMatters)
                                    .font(.body)
                                    .foregroundColor(.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(Spacing.md)
                            .background(Color.primaryBlue.opacity(0.08))
                            .cornerRadius(CornerRadius.card)
                            .padding(.horizontal, Spacing.md)
                        }

                        // Examples
                        if !explainer.examples.isEmpty {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Label("Examples", systemImage: "lightbulb.fill")
                                    .font(.headline)
                                    .foregroundColor(.textPrimary)

                                ForEach(explainer.examples, id: \.self) { example in
                                    HStack(alignment: .top, spacing: Spacing.sm) {
                                        Text("•")
                                            .foregroundColor(.textSecondary)
                                        Text(example)
                                            .font(.body)
                                            .foregroundColor(.textSecondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .padding(.horizontal, Spacing.md)
                        }

                        // Learn more link
                        if let learnMoreURL = explainer.learnMoreURL {
                            Link(destination: learnMoreURL) {
                                HStack {
                                    Image(systemName: "arrow.up.right.square")
                                    Text("Learn More")
                                        .fontWeight(.medium)
                                }
                                .font(.body)
                                .foregroundColor(.primaryBlue)
                            }
                            .padding(.horizontal, Spacing.md)
                        }
                    }
                    .padding(.vertical, Spacing.lg)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
        }
    }
}

/// Model for explainer content
struct ScoreExplainer {
    let componentName: String
    let subtitle: String
    let icon: String
    let whatItMeasures: String
    let whyItMatters: String?
    let examples: [String]
    let learnMoreURL: URL?
}

#Preview {
    ExplainerCard(
        explainer: ScoreExplainer(
            componentName: "Macronutrient Balance",
            subtitle: "Protein, Carbs, Fiber, and Sugar",
            icon: "chart.pie.fill",
            whatItMeasures: "This component evaluates the balance of macronutrients (protein, carbohydrates, fat) and key nutrients like fiber and sugar. It looks at whether the product provides adequate protein, contains beneficial fiber, and avoids excess sugar.",
            whyItMatters: "For Gut Health, fiber is crucial. It feeds beneficial gut bacteria and supports digestive health. Higher fiber products score better for your goals.",
            examples: [
                "High in protein (10g+)",
                "Good fiber content (5g+)",
                "Low added sugars (<5g)"
            ],
            learnMoreURL: URL(string: "https://www.hsph.harvard.edu/nutritionsource/what-should-you-eat/")
        )
    )
}
