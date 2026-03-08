import SwiftUI

/// Sheet shown when user scans a product that doesn't meet their dietary filter requirements
struct NonCompliantProductSheet: View {
    let product: ProductModel
    let violations: [DietaryAnalysisResult]
    let onViewAlternatives: () -> Void
    let onScanNew: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                Spacer()

                // Warning icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)

                // Title
                VStack(spacing: Spacing.xs) {
                    Text("Not Compatible")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)

                    Text("This product doesn't match your filters")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }

                // Product card
                VStack(spacing: Spacing.md) {
                    // Product image
                    AsyncProductImage(
                        url: product.thumbnailURL ?? product.imageURL,
                        size: .medium,
                        cornerRadius: CornerRadius.card
                    )

                    // Product name and brand
                    VStack(spacing: Spacing.xxs) {
                        Text(product.name)
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)

                        if let brand = product.brand {
                            Text(brand)
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                    }

                    Divider()

                    // Violations list
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Incompatible with:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.textSecondary)
                            .textCase(.uppercase)

                        ForEach(violations, id: \.restriction) { analysisResult in
                            RestrictionViolationRow(analysisResult: analysisResult)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(Spacing.lg)
                .background(Color.backgroundSecondary)
                .cornerRadius(CornerRadius.card)
                .padding(.horizontal, Spacing.lg)

                Spacer()

                // Action buttons
                VStack(spacing: Spacing.md) {
                    Button {
                        dismiss()
                        onViewAlternatives()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("See Compatible Alternatives")
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.primaryBlue)
                        .cornerRadius(CornerRadius.button)
                    }

                    Button {
                        dismiss()
                        onScanNew()
                    } label: {
                        Text("Scan Another Product")
                            .fontWeight(.medium)
                            .foregroundColor(.primaryBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(Color.primaryBlue.opacity(0.1))
                            .cornerRadius(CornerRadius.button)
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("View Details Anyway")
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, Spacing.xs)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
            }
            .navigationTitle("Filter Alert")
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
    }
}

// MARK: - Restriction Violation Row

private struct RestrictionViolationRow: View {
    let analysisResult: DietaryAnalysisResult

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "xmark.circle.fill")
                .font(.caption)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(analysisResult.restriction.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)

                Text(analysisResult.reason)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, Spacing.xxs)
    }
}

// MARK: - Preview

#Preview {
    let sampleProduct = ProductModel(
        id: UUID(),
        name: "Whole Milk",
        brand: "Organic Valley",
        category: "Dairy",
        categorySlug: "dairy",
        barcode: "1234567890",
        nutrition: ProductNutrition(
            calories: 150,
            protein: 8,
            carbohydrates: 12,
            fat: 8,
            fiber: 0,
            sugar: 12,
            sodium: 0.12,
            cholesterol: 35,
            servingSize: "240ml"
        ),
        ingredients: ["Organic whole milk", "Vitamin D3"],
        additives: [],
        processingLevel: .processed,
        dietaryFlags: [],
        imageURL: nil,
        thumbnailURL: nil,
        healthScore: 72,
        createdAt: Date(),
        updatedAt: Date(),
        isCached: false,
        rawIngredientsText: nil
    )

    let sampleViolations = [
        DietaryAnalysisResult.violation(
            restriction: .vegan,
            violations: [
                DietaryViolation(
                    ingredient: "whole milk",
                    violationType: .directMatch,
                    isDerivative: false,
                    derivedFrom: nil,
                    aiExplanation: nil
                ),
                DietaryViolation(
                    ingredient: "vitamin D3",
                    violationType: .derivativeMatch,
                    isDerivative: true,
                    derivedFrom: "animal sources",
                    aiExplanation: nil
                )
            ],
            confidence: .high,
            method: .regexOnly
        ),
        DietaryAnalysisResult.violation(
            restriction: .dairyFree,
            violations: [
                DietaryViolation(
                    ingredient: "whole milk",
                    violationType: .directMatch,
                    isDerivative: false,
                    derivedFrom: nil,
                    aiExplanation: nil
                )
            ],
            confidence: .high,
            method: .regexOnly
        )
    ]

    NonCompliantProductSheet(
        product: sampleProduct,
        violations: sampleViolations,
        onViewAlternatives: {},
        onScanNew: {}
    )
}
