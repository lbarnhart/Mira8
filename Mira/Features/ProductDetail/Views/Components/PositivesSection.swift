import SwiftUI

/// Highlights positive attributes of a product, even for low-scoring items
/// Reduces food anxiety by showing balanced perspective
struct PositivesSection: View {
    let product: ProductModel
    let healthScore: HealthScore

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // What's Good
            if !positives.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Label("What's Good", systemImage: "sparkles")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    ForEach(positives, id: \.self) { positive in
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text(positive)
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            // Watch Out For
            if !concerns.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Label("Watch Out For", systemImage: "exclamationmark.triangle")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    ForEach(concerns.prefix(2), id: \.self) { concern in
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Image(systemName: "info.circle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text(concern)
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.card)
    }

    // MARK: - Positives Detection

    private var positives: [String] {
        var items: [String] = []
        let nutrition = product.nutrition

        // High protein
        if nutrition.protein >= 10 {
            items.append("High in protein (\(String(format: "%.1f", nutrition.protein))g)")
        } else if nutrition.protein >= 5 {
            items.append("Good protein content (\(String(format: "%.1f", nutrition.protein))g)")
        }

        // High fiber
        if nutrition.fiber >= 5 {
            items.append("Excellent fiber source (\(String(format: "%.1f", nutrition.fiber))g)")
        } else if nutrition.fiber >= 3 {
            items.append("Good fiber content (\(String(format: "%.1f", nutrition.fiber))g)")
        }

        // Low sugar
        if nutrition.sugar < 5 {
            items.append("Low in sugar (\(String(format: "%.1f", nutrition.sugar))g)")
        }

        // Low sodium
        if nutrition.sodium < 200 {
            items.append("Low in sodium (\(String(format: "%.0f", nutrition.sodium))mg)")
        } else if nutrition.sodium < 400 {
            items.append("Moderate sodium (\(String(format: "%.0f", nutrition.sodium))mg)")
        }

        // Minimal processing (check score components)
        let processingScore = healthScore.components.processingLevel.score
        if processingScore >= 70 {
            items.append("Minimally processed")
        }

        // No harmful additives
        let additivesScore = healthScore.components.additives.score
        if additivesScore >= 80 {
            items.append("No concerning additives")
        }

        // Good ingredient quality
        let ingredientScore = healthScore.components.ingredientQuality.score
        if ingredientScore >= 70 {
            items.append("Clean ingredient list")
        }

        // Always show at least one positive, even if we have to be generous
        if items.isEmpty {
            // Find any positive aspect
            if nutrition.calories < 200 {
                items.append("Moderate calories (\(String(format: "%.0f", nutrition.calories)) per serving)")
            } else if nutrition.protein > 0 {
                items.append("Contains protein (\(String(format: "%.1f", nutrition.protein))g)")
            } else if nutrition.fiber > 0 {
                items.append("Contains fiber (\(String(format: "%.1f", nutrition.fiber))g)")
            } else {
                // Last resort: something neutral but true
                items.append("Provides energy and nutrients")
            }
        }

        return Array(items.prefix(3)) // Limit to top 3
    }

    // MARK: - Concerns Detection

    private var concerns: [String] {
        var items: [String] = []
        let nutrition = product.nutrition

        // High sugar
        if nutrition.sugar >= 15 {
            items.append("High in sugar (\(String(format: "%.1f", nutrition.sugar))g)")
        } else if nutrition.sugar >= 10 {
            items.append("Moderate sugar content (\(String(format: "%.1f", nutrition.sugar))g)")
        }

        // High sodium
        if nutrition.sodium >= 600 {
            items.append("High in sodium (\(String(format: "%.0f", nutrition.sodium))mg)")
        } else if nutrition.sodium >= 400 {
            items.append("Moderate-high sodium (\(String(format: "%.0f", nutrition.sodium))mg)")
        }

        // High saturated fat
        if nutrition.saturatedFat >= 5 {
            items.append("High in saturated fat (\(String(format: "%.1f", nutrition.saturatedFat))g)")
        }

        // Low fiber
        if nutrition.fiber < 2 && nutrition.carbohydrates > 10 {
            items.append("Low in fiber (\(String(format: "%.1f", nutrition.fiber))g)")
        }

        // Ultra-processed (check score)
        let processingScore = healthScore.components.processingLevel.score
        if processingScore < 40 {
            items.append("Highly processed")
        }

        // Concerning additives
        let additivesScore = healthScore.components.additives.score
        if additivesScore < 50 {
            items.append("Contains concerning additives")
        }

        return Array(items.prefix(2)) // Limit to top 2 concerns
    }
}

#Preview {
    let sampleProduct = ProductModel(
        id: UUID(),
        name: "Sample Snack Bar",
        brand: "Brand",
        category: "Snacks",
        categorySlug: "snacks",
        barcode: "12345",
        nutrition: ProductNutrition(
            calories: 200,
            protein: 8,
            carbohydrates: 25,
            fat: 7,
            fiber: 4,
            sugar: 12,
            sodium: 0.15,
            cholesterol: 0,
            servingSize: "1 bar (40g)"
        ),
        ingredients: ["Oats", "honey", "almonds", "chocolate chips"],
        additives: ["Natural flavor"],
        processingLevel: .processed,
        dietaryFlags: [],
        imageURL: nil,
        thumbnailURL: nil,
        healthScore: 58,
        createdAt: Date(),
        updatedAt: Date(),
        isCached: false,
        rawIngredientsText: "Oats, honey, almonds, chocolate chips, natural flavor"
    )

    let sampleScore = ScoringEngine.shared.calculateHealthScore(
        for: sampleProduct,
        healthFocus: .generalWellness,
        dietaryRestrictions: []
    )

    PositivesSection(product: sampleProduct, healthScore: sampleScore)
        .padding()
}
