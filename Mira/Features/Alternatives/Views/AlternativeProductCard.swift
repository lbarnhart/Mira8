import SwiftUI

struct AlternativeProductCard: View {
    let alternative: AlternativeProduct
    let rank: Int

    var body: some View {
        HStack(spacing: 12) {
            // Rank indicator
            Text("\(rank)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primaryBlue)
                .frame(width: 30, height: 30)
                .background(Color.primaryBlue.opacity(0.1))
                .clipShape(Circle())

            AsyncProductImage(
                url: alternative.product.thumbnailURL ?? alternative.product.imageURL,
                size: .thumbnail,
                cornerRadius: CornerRadius.sm
            )
            .onAppear {
                AppLog.debug("Alternative card image for \(alternative.product.name)", category: .general)
                let imageURL = alternative.product.imageURL ?? "nil"
                let thumbURL = alternative.product.thumbnailURL ?? "nil"
                AppLog.debug("Image URL: \(imageURL) | thumb: \(thumbURL)", category: .general)
            }

            // Product details
            VStack(alignment: .leading, spacing: 4) {
                Text(alternative.product.name)
                    .font(.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)

                if let brand = alternative.product.brand {
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }

                // Key improvements
                if !alternative.improvementReasons.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(alternative.improvementReasons, id: \.self) { reason in
                            improvementTag(reason, color: tagColor(for: reason))
                        }
                    }
                }
            }

            Spacer()

            // Health score and improvement
            VStack(alignment: .trailing, spacing: 6) {
                if alternative.healthScore.overall > 0 {
                    ScoreGauge(score: alternative.healthScore.overall, size: 48, style: .minimal)
                    Text("+\(Int(alternative.improvement)) pts")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                } else {
                    Text("Score unavailable")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
            }
        }
        .padding(12)
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primaryBlue.opacity(0.2), lineWidth: 1)
        )
    }

    private func improvementTag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(4)
    }

    private func tagColor(for reason: String) -> Color {
        let lower = reason.lowercased()
        if lower.contains("protein") {
            return .green
        }
        if lower.contains("macro") || lower.contains("nutrition") {
            return .blue
        }
        if lower.contains("fiber") {
            return .mint
        }
        if lower.contains("processed") {
            return .orange
        }
        if lower.contains("additive") || lower.contains("clean") {
            return .purple
        }
        return .primaryBlue
    }
}

#Preview {
    VStack(spacing: 12) {
        let base = ProductModel(
                id: UUID(),
                name: "Organic Granola with Almonds",
                brand: "Nature's Best",
                category: "Snacks",
                categorySlug: "snacks",
                barcode: "1234567890",
                nutrition: ProductNutrition(
                    calories: 150,
                    protein: 6,
                    carbohydrates: 20,
                    fat: 8,
                    fiber: 4,
                    sugar: 5,
                    sodium: 0.1,
                    cholesterol: 0,
                    servingSize: "30g"
                ),
                ingredients: ["Organic oats", "Almonds", "Honey"],
                additives: [],
                processingLevel: .minimal,
                dietaryFlags: [],
                imageURL: nil,
                thumbnailURL: nil,
                healthScore: 85,
                createdAt: Date(),
                updatedAt: Date(),
                isCached: false,
                rawIngredientsText: nil
            )

        AlternativeProductCard(
            alternative: AlternativeProduct(
                product: base,
                healthScore: HealthFocusScorer(config: ScoringConfiguration.defaultConfiguration).calculateScore(
                    for: base,
                    focus: .generalWellness,
                    dietaryRestrictions: []
                ),
                improvement: 12,
                improvementReasons: ["More fiber"],
                dietaryViolations: [],
                similarity: 0.9
            ),
            rank: 1
        )

        let base2 = ProductModel(
                id: UUID(),
                name: "Protein Power Granola Bar Super Long Name That Goes Multiple Lines",
                brand: "Healthy Choice",
                category: "Snacks",
                categorySlug: "snacks",
                barcode: "1234567891",
                nutrition: ProductNutrition(
                    calories: 200,
                    protein: 15,
                    carbohydrates: 25,
                    fat: 8,
                    fiber: 5,
                    sugar: 8,
                    sodium: 0.2,
                    cholesterol: 0,
                    servingSize: "40g"
                ),
                ingredients: ["Protein blend", "Oats", "Nuts"],
                additives: ["Natural flavor"],
                processingLevel: .processed,
                dietaryFlags: [],
                imageURL: nil,
                thumbnailURL: nil,
                healthScore: 78,
                createdAt: Date(),
                updatedAt: Date(),
                isCached: false,
                rawIngredientsText: nil
            )

        AlternativeProductCard(
            alternative: AlternativeProduct(
                product: base2,
                healthScore: HealthFocusScorer(config: ScoringConfiguration.defaultConfiguration).calculateScore(
                    for: base2,
                    focus: .generalWellness,
                    dietaryRestrictions: []
                ),
                improvement: 6,
                improvementReasons: ["Less processed"],
                dietaryViolations: [],
                similarity: 0.8
            ),
            rank: 2
        )
    }
    .padding()
}
