import SwiftUI

/// Sheet that shows how a product scores across different health focuses
struct ScoreComparisonSheet: View {
    let product: ProductModel
    let currentFocus: HealthFocus
    @Environment(\.dismiss) private var dismiss

    @State private var comparisonScores: [HealthFocus: HealthScore] = [:]
    @State private var isLoading = true

    private let allFocuses: [HealthFocus] = [
        .gutHealth,
        .weightLoss,
        .proteinFocus,
        .heartHealth,
        .generalWellness
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header section
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 50))
                            .foregroundColor(.primaryBlue)

                        Text("How this product scores for different health goals")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.lg)
                    }
                    .padding(.top, Spacing.lg)

                    if isLoading {
                        ProgressView("Calculating scores...")
                            .padding()
                    } else {
                        // Score comparison list
                        VStack(spacing: Spacing.md) {
                            ForEach(allFocuses, id: \.self) { focus in
                                FocusScoreCard(
                                    focus: focus,
                                    score: comparisonScores[focus]?.overall ?? 0,
                                    isCurrentFocus: focus == currentFocus,
                                    components: comparisonScores[focus]?.breakdown ?? []
                                )
                            }
                        }
                        .padding(.horizontal, Spacing.lg)

                        // Why scores differ section
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.primaryBlue)
                                Text("Why do scores differ?")
                                    .font(.headline)
                                    .foregroundColor(.textPrimary)
                            }

                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                explanationRow(
                                    icon: "🫀",
                                    title: "Heart Health",
                                    description: "Prioritizes low sodium, low saturated fat, and high fiber"
                                )

                                explanationRow(
                                    icon: "🦠",
                                    title: "Gut Health",
                                    description: "Emphasizes fiber, probiotics, and minimal processing"
                                )

                                explanationRow(
                                    icon: "💪",
                                    title: "Protein Focus",
                                    description: "Rewards high protein content and optimal protein-to-calorie ratio"
                                )

                                explanationRow(
                                    icon: "⚖️",
                                    title: "Weight Loss",
                                    description: "Considers calorie density, satiety factors, and portion control"
                                )

                                explanationRow(
                                    icon: "✨",
                                    title: "General Wellness",
                                    description: "Balanced approach across all nutritional factors"
                                )
                            }
                        }
                        .padding(Spacing.lg)
                        .background(Color.backgroundSecondary)
                        .cornerRadius(CornerRadius.card)
                        .padding(.horizontal, Spacing.lg)

                        // Call to action
                        VStack(spacing: Spacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)

                            Text("Your scores are personalized to help you achieve **your** health goals")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.bottom, Spacing.xl)
                    }
                }
            }
            .navigationTitle("Compare Health Focuses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.textTertiary)
                    }
                }
            }
        }
        .onAppear {
            calculateAllScores()
        }
    }

    // MARK: - Helper Views

    private func explanationRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Text(icon)
                .font(.title3)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Score Calculation

    private func calculateAllScores() {
        Task {
            let dietaryRestrictions = UserDefaults.standard.stringArray(forKey: "selectedDietaryRestrictions")?.compactMap { DietaryRestriction(rawValue: $0) } ?? []

            var scores: [HealthFocus: HealthScore] = [:]

            for focus in allFocuses {
                let score = ScoringEngine.shared.calculateHealthScore(
                    for: product,
                    healthFocus: focus,
                    dietaryRestrictions: dietaryRestrictions
                )
                scores[focus] = score
            }

            await MainActor.run {
                comparisonScores = scores
                isLoading = false
            }
        }
    }
}

// MARK: - Focus Score Card

struct FocusScoreCard: View {
    let focus: HealthFocus
    let score: Double
    let isCurrentFocus: Bool
    let components: [ComponentBreakdown]

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Main card
            HStack(spacing: Spacing.md) {
                // Focus icon and name
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(focus.icon)
                        .font(.title2)

                    Text(focus.displayName)
                        .font(.subheadline)
                        .fontWeight(isCurrentFocus ? .bold : .semibold)
                        .foregroundColor(.textPrimary)

                    if isCurrentFocus {
                        Text("Your focus")
                            .font(.caption2)
                            .foregroundColor(.primaryBlue)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 2)
                            .background(Color.primaryBlue.opacity(0.12))
                            .cornerRadius(4)
                    }
                }

                Spacer()

                // Score gauge
                ScoreGauge(
                    score: score,
                    size: 70,
                    style: .minimal,
                    showAnimation: false
                )

                // Expand button
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                        .font(.title3)
                        .foregroundColor(.textTertiary)
                }
            }
            .padding(Spacing.md)
            .background(
                isCurrentFocus
                    ? Color.primaryBlue.opacity(0.08)
                    : Color.backgroundSecondary
            )
            .cornerRadius(CornerRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .strokeBorder(
                        isCurrentFocus ? Color.primaryBlue.opacity(0.3) : Color.clear,
                        lineWidth: 2
                    )
            )

            // Expandable component breakdown
            if isExpanded && !components.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Score breakdown:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.textSecondary)
                        .padding(.top, Spacing.sm)

                    ForEach(components.prefix(4), id: \.componentName) { component in
                        HStack {
                            Text(component.componentName)
                                .font(.caption)
                                .foregroundColor(.textSecondary)

                            Spacer()

                            Text("\(Int(component.rawScore))")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.scoreColor(for: component.rawScore))
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.sm)
                .background(Color.backgroundSecondary.opacity(0.5))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleProduct = ProductModel(
        id: UUID(),
        name: "Greek Yogurt",
        brand: "Chobani",
        category: "Dairy",
        categorySlug: "dairy",
        barcode: "1234567890",
        nutrition: ProductNutrition(
            calories: 100,
            protein: 15,
            carbohydrates: 6,
            fat: 0,
            fiber: 0,
            sugar: 4,
            sodium: 0.06,
            cholesterol: 5,
            servingSize: "150g"
        ),
        ingredients: ["Cultured nonfat milk", "Live active cultures"],
        additives: [],
        processingLevel: .processed,
        dietaryFlags: [],
        imageURL: nil,
        thumbnailURL: nil,
        healthScore: 85,
        createdAt: Date(),
        updatedAt: Date(),
        isCached: false,
        rawIngredientsText: nil
    )

    return ScoreComparisonSheet(
        product: sampleProduct,
        currentFocus: .gutHealth
    )
}
