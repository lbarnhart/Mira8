import SwiftUI

struct ProductDetailHeroView: View {
    let product: ProductModel
    let healthScore: HealthScore?
    let isFavorite: Bool
    let dietaryRestrictions: Set<String>
    let onToggleFavorite: () -> Void
    let onScanToCompare: () -> Void
    let onSelectFromHistory: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Product Info Row
            HStack(alignment: .top, spacing: Spacing.md) {
                // Product Image
                productImageView

                // Name and Brand
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    if let brand = product.brand, !brand.isEmpty {
                        Text(brand)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)
                    }

                    Text(product.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Favorite Heart
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 22))
                        .foregroundColor(isFavorite ? .error : .textSecondary)
                }
            }
            .padding(.horizontal, Spacing.lg)

            // Health Score Card
            if let score = healthScore {
                HealthScoreCard(score: score)
                    .padding(.horizontal, Spacing.lg)
            }

            // Dietary Restrictions Card (only if user has restrictions)
            if !dietaryRestrictions.isEmpty {
                DietaryRestrictionsCard(product: product, restrictions: dietaryRestrictions)
                    .padding(.horizontal, Spacing.lg)
            }

            // Quick Stats Row
            QuickStatsRow(nutrition: product.nutrition)
                .padding(.horizontal, Spacing.lg)

            // Secondary Stats Row
            SecondaryStatsRow(
                nutrition: product.nutrition,
                ingredientCount: product.ingredients.count
            )
            .padding(.horizontal, Spacing.lg)

            // Compare Section
            CompareSection(onScanToCompare: onScanToCompare, onSelectFromHistory: onSelectFromHistory)
                .padding(.horizontal, Spacing.lg)
        }
        .padding(.vertical, Spacing.lg)
        .background(Color.warmCream)
    }

    private var productImageView: some View {
        Group {
            if let imageURL = product.imageURL ?? product.thumbnailURL {
                AsyncProductImage(
                    url: imageURL,
                    size: .medium,
                    cornerRadius: CornerRadius.md
                )
            } else {
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.backgroundSecondary)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "photo.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.textTertiary)
                    )
            }
        }
    }
}

// MARK: - Health Score Card
struct HealthScoreCard: View {
    let score: HealthScore

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Leaf Icon with background
            ZStack {
                Circle()
                    .fill(verdictColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "leaf.fill")
                    .font(.system(size: 20))
                    .foregroundColor(verdictColor)
            }

            // Label
            VStack(alignment: .leading, spacing: 2) {
                Text("Health Score")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                Text(score.simplifiedDisplay.verdict.label)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(verdictColor)
            }

            Spacer()

            // Score Number
            Text("\(Int(score.overall))")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(verdictColor)
        }
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.lg)
    }

    private var verdictColor: Color {
        switch score.verdict {
        case .excellent: return .scoreExcellent
        case .good: return .scoreGood
        case .okay: return .scoreFair
        case .fair: return .scoreFair
        case .avoid: return .scorePoor
        }
    }
}

// MARK: - Quick Stats Row
struct QuickStatsRow: View {
    let nutrition: ProductNutrition

    var body: some View {
        HStack(spacing: Spacing.sm) {
            StatCard(
                value: "\(Int(nutrition.calories))",
                label: "Calories",
                icon: "flame.fill",
                color: .nutrientCarbs
            )

            StatCard(
                value: "\(Int(nutrition.protein))g",
                label: "Protein",
                icon: "figure.strengthtraining.traditional",
                color: .nutrientProtein
            )

            StatCard(
                value: "\(Int(nutrition.fiber))g",
                label: "Fiber",
                icon: "leaf.fill",
                color: .nutrientFiber
            )
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)

            Text(label)
                .font(.caption2)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Secondary Stats Row
struct SecondaryStatsRow: View {
    let nutrition: ProductNutrition
    let ingredientCount: Int

    var body: some View {
        HStack(spacing: Spacing.xl) {
            SecondaryStatItem(label: "Sugar", value: "\(Int(nutrition.sugar))g")
            SecondaryStatItem(label: "Sodium", value: "\(Int(nutrition.sodium * 1000))mg")
            SecondaryStatItem(label: "Ingredients", value: "\(max(ingredientCount, 1))")
        }
        .padding(.vertical, Spacing.sm)
    }
}

struct SecondaryStatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)

            Text(label)
                .font(.caption2)
                .foregroundColor(.textSecondary)
        }
    }
}

// MARK: - Compare Section
struct CompareSection: View {
    let onScanToCompare: () -> Void
    let onSelectFromHistory: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            Text("Compare with another product")
                .font(.subheadline)
                .foregroundColor(.textSecondary)

            HStack(spacing: Spacing.md) {
                // Scan New Product Button
                Button(action: onScanToCompare) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 14, weight: .semibold))

                        Text("Scan")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.forestGreen)
                    .cornerRadius(CornerRadius.pill)
                }

                // Select from History Button
                Button(action: onSelectFromHistory) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 14, weight: .semibold))

                        Text("History")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.forestGreen)
                    .cornerRadius(CornerRadius.pill)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.lg)
    }
}

// MARK: - Dietary Restrictions Card
struct DietaryRestrictionsCard: View {
    let product: ProductModel
    let restrictions: Set<String>

    private var compatibilityResults: [(restriction: String, isCompatible: Bool)] {
        restrictions.sorted().map { restriction in
            (restriction, DietUtils.productMeetsDietaryRestriction(product, restriction: restriction))
        }
    }

    private var allCompatible: Bool {
        compatibilityResults.allSatisfy { $0.isCompatible }
    }

    private var statusColor: Color {
        allCompatible ? .scoreGood : .scorePoor
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: allCompatible ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(statusColor)
            }

            // Status and restrictions
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Diet")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                Text(allCompatible ? "Compatible" : "Has Conflicts")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor)
            }

            Spacer()

            // Restriction pills
            VStack(alignment: .trailing, spacing: 4) {
                ForEach(compatibilityResults, id: \.restriction) { result in
                    HStack(spacing: 4) {
                        Image(systemName: result.isCompatible ? "checkmark" : "xmark")
                            .font(.system(size: 10, weight: .bold))

                        Text(DietUtils.formatRestrictionName(result.restriction))
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(result.isCompatible ? .scoreGood : .scorePoor)
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.lg)
    }
}
