import SwiftUI

/// Interactive education sheet shown on first scan to explain personalization
struct FirstScanEducationSheet: View {
    let product: ProductModel
    let userScore: HealthScore
    let userFocus: HealthFocus
    @Environment(\.dismiss) private var dismiss

    @State private var currentPage = 0
    @State private var selectedFocus: HealthFocus = .generalWellness
    @State private var comparisonScores: [HealthFocus: Double] = [:]

    private let allFocuses: [HealthFocus] = [
        .gutHealth,
        .weightLoss,
        .proteinFocus,
        .heartHealth,
        .generalWellness
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.primaryBlue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, Spacing.md)

                // Page content
                TabView(selection: $currentPage) {
                    page1_YourScoreIsPersonal
                        .tag(0)

                    page2_CompareAcrossFocuses
                        .tag(1)

                    page3_WhyItMatters
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Navigation buttons
                HStack(spacing: Spacing.md) {
                    if currentPage > 0 {
                        Button {
                            withAnimation {
                                currentPage -= 1
                            }
                        } label: {
                            Text("Back")
                                .foregroundColor(.textSecondary)
                        }
                    }

                    Spacer()

                    Button {
                        if currentPage < 2 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            dismiss()
                        }
                    } label: {
                        Text(currentPage < 2 ? "Next" : "Got It!")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(Color.primaryBlue)
                            .cornerRadius(CornerRadius.button)
                    }
                }
                .padding(Spacing.lg)
            }
            .navigationTitle("Welcome to Mira")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            calculateComparisonScores()
        }
    }

    // MARK: - Page 1: Your Score is Personal

    private var page1_YourScoreIsPersonal: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Icon
            Image(systemName: "person.crop.circle.fill.badge.checkmark")
                .font(.system(size: 60))
                .foregroundColor(.primaryBlue)

            // Title
            Text("Your Score is Personal to You")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)

            // Product card with score
            VStack(spacing: Spacing.md) {
                Text(product.name)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                ScoreGauge(
                    score: userScore.overall,
                    size: 120,
                    style: .prominent,
                    showAnimation: true
                )

                Text("Score for your **\(userFocus.displayName)** focus")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(Spacing.lg)
            .background(Color.backgroundSecondary)
            .cornerRadius(CornerRadius.card)
            .padding(.horizontal, Spacing.lg)

            // Key message
            VStack(spacing: Spacing.xs) {
                Image(systemName: "lightbulb.fill")
                    .font(.title3)
                    .foregroundColor(.orange)

                Text("This score is tailored to your health goals")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()
        }
    }

    // MARK: - Page 2: Compare Across Focuses

    private var page2_CompareAcrossFocuses: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Icon
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 60))
                .foregroundColor(.primaryBlue)

            // Title
            Text("Different Goals, Different Scores")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)

            // Comparison picker
            VStack(spacing: Spacing.md) {
                Text("See how this product scores for:")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)

                Picker("Health Focus", selection: $selectedFocus) {
                    ForEach(allFocuses, id: \.self) { focus in
                        Text(focus.displayName).tag(focus)
                    }
                }
                .pickerStyle(.segmented)

                // Score for selected focus
                HStack(spacing: Spacing.lg) {
                    VStack(spacing: Spacing.xs) {
                        Text(selectedFocus.icon)
                            .font(.title)
                        Text(selectedFocus.displayName)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    ScoreGauge(
                        score: comparisonScores[selectedFocus] ?? userScore.overall,
                        size: 100,
                        style: .standard,
                        showAnimation: true
                    )
                }
                .padding(Spacing.md)
                .background(Color.backgroundSecondary)
                .cornerRadius(CornerRadius.card)
            }
            .padding(.horizontal, Spacing.lg)

            // Explanation
            VStack(spacing: Spacing.xs) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.title3)
                    .foregroundColor(.green)

                Text("The same product can score differently based on what nutrients matter most for each health goal")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()
        }
    }

    // MARK: - Page 3: Why It Matters

    private var page3_WhyItMatters: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Icon
            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)

            // Title
            Text("Why Personalization Matters")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)

            // Benefits list
            VStack(alignment: .leading, spacing: Spacing.md) {
                benefitRow(
                    icon: "target",
                    title: "Aligned with Your Goals",
                    description: "Get scores that actually match what you're trying to achieve"
                )

                benefitRow(
                    icon: "brain.head.profile",
                    title: "Smarter Choices",
                    description: "Know which nutrients to prioritize for your specific health focus"
                )

                benefitRow(
                    icon: "heart.fill",
                    title: "No More Confusion",
                    description: "Unlike generic apps, Mira knows that one size doesn't fit all"
                )
            }
            .padding(.horizontal, Spacing.lg)

            // Call to action
            VStack(spacing: Spacing.xs) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.green)

                Text("You're all set! Start scanning to make healthier choices for **your** goals")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()
        }
    }

    // MARK: - Helper Views

    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.primaryBlue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Score Calculation

    private func calculateComparisonScores() {
        let dietaryRestrictions = UserDefaults.standard
            .stringArray(forKey: Constants.UserDefaults.dietaryRestrictions)?
            .compactMap { DietaryRestriction(from: $0) } ?? []

        for focus in allFocuses {
            let score = ScoringEngine.shared.calculateHealthScore(
                for: product,
                healthFocus: focus,
                dietaryRestrictions: dietaryRestrictions
            )
            comparisonScores[focus] = score.overall
        }

        // Set initial selected focus to something different from user's focus
        if let differentFocus = allFocuses.first(where: { $0 != userFocus }) {
            selectedFocus = differentFocus
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

    let sampleScore = ScoringEngine.shared.calculateHealthScore(
        for: sampleProduct,
        healthFocus: .gutHealth,
        dietaryRestrictions: []
    )

    return FirstScanEducationSheet(
        product: sampleProduct,
        userScore: sampleScore,
        userFocus: .gutHealth
    )
}
