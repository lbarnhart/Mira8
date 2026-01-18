import SwiftUI

/// Vertical comparison view showing the healthier product on top
struct VerticalComparisonView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) var dismiss

    let productA: ProductModel
    let scoreA: HealthScore
    let productB: ProductModel
    let scoreB: HealthScore

    private var winnerProduct: ProductModel {
        scoreA.overall >= scoreB.overall ? productA : productB
    }

    private var winnerScore: HealthScore {
        scoreA.overall >= scoreB.overall ? scoreA : scoreB
    }

    private var loserProduct: ProductModel {
        scoreA.overall >= scoreB.overall ? productB : productA
    }

    private var loserScore: HealthScore {
        scoreA.overall >= scoreB.overall ? scoreB : scoreA
    }

    private var scoreDifference: Int {
        abs(Int(scoreA.overall - scoreB.overall))
    }

    private var isTie: Bool {
        scoreDifference < 3
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            // Main content
            VStack(spacing: Spacing.lg) {
                // Winner card (larger, on top)
                if isTie {
                    tieMessage
                } else {
                    winnerBanner
                }

                winnerCard

                // VS divider
                vsDivider

                // Loser card (smaller, below)
                loserCard
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)

            Spacer()

            // Bottom action
            chooseButton
        }
        .background(Color.backgroundPrimary)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(Color.cardBackground)
                    .clipShape(Circle())
            }

            Spacer()

            Text("Compare")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)

            Spacer()

            // Invisible spacer for alignment
            Color.clear
                .frame(width: 32, height: 32)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color.backgroundPrimary)
    }

    // MARK: - Winner Banner

    private var winnerBanner: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(.scoreExcellent)

            Text("Better Choice")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.scoreExcellent)

            Text("(+\(scoreDifference) points)")
                .font(.caption)
                .foregroundColor(.textSecondary)

            Spacer()
        }
    }

    private var tieMessage: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "equal.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(.scoreFair)

            Text("Similar Health Scores")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.scoreFair)

            Spacer()
        }
    }

    // MARK: - Winner Card

    private var winnerCard: some View {
        HStack(spacing: Spacing.md) {
            // Product image
            productImage(url: winnerProduct.imageURL ?? winnerProduct.thumbnailURL, size: 80)

            // Product info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                if let brand = winnerProduct.brand, !brand.isEmpty {
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                Text(winnerProduct.name)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)

                // Key stats
                HStack(spacing: Spacing.md) {
                    statBadge(value: "\(Int(winnerProduct.nutrition.calories))", label: "cal")
                    statBadge(value: "\(Int(winnerProduct.nutrition.sugar))g", label: "sugar")
                    statBadge(value: "\(Int(winnerProduct.nutrition.protein))g", label: "protein")
                }
            }

            Spacer()

            // Score
            VStack(spacing: 2) {
                Text("\(Int(winnerScore.overall))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(scoreColor(winnerScore.overall))

                Text(winnerScore.simplifiedDisplay.verdict.label)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(scoreColor(winnerScore.overall))
            }
        }
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(isTie ? Color.clear : Color.scoreExcellent.opacity(0.3), lineWidth: 2)
        )
    }

    // MARK: - VS Divider

    private var vsDivider: some View {
        HStack {
            Rectangle()
                .fill(Color.cardBorder)
                .frame(height: 1)

            Text("vs")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.textTertiary)
                .padding(.horizontal, Spacing.sm)

            Rectangle()
                .fill(Color.cardBorder)
                .frame(height: 1)
        }
    }

    // MARK: - Loser Card

    private var loserCard: some View {
        HStack(spacing: Spacing.md) {
            // Product image (smaller)
            productImage(url: loserProduct.imageURL ?? loserProduct.thumbnailURL, size: 56)

            // Product info
            VStack(alignment: .leading, spacing: 2) {
                if let brand = loserProduct.brand, !brand.isEmpty {
                    Text(brand)
                        .font(.caption2)
                        .foregroundColor(.textTertiary)
                }

                Text(loserProduct.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            // Score
            VStack(spacing: 2) {
                Text("\(Int(loserScore.overall))")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(scoreColor(loserScore.overall))

                Text(loserScore.simplifiedDisplay.verdict.label)
                    .font(.caption2)
                    .foregroundColor(.textTertiary)
            }
        }
        .padding(Spacing.md)
        .background(Color.cardBackground.opacity(0.7))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Choose Button

    private var chooseButton: some View {
        VStack(spacing: Spacing.sm) {
            Button(action: {
                // Choose winner and dismiss
                dismiss()
            }) {
                HStack {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                    Text(isTie ? "Got it" : "Choose \(winnerProduct.name)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Color.forestGreen)
                .cornerRadius(CornerRadius.pill)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.xl)
    }

    // MARK: - Helpers

    private func productImage(url: String?, size: CGFloat) -> some View {
        Group {
            if let urlString = url, let imageURL = URL(string: urlString) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        imagePlaceholder
                    default:
                        imagePlaceholder
                    }
                }
            } else {
                imagePlaceholder
            }
        }
        .frame(width: size, height: size)
        .cornerRadius(CornerRadius.md)
        .clipped()
    }

    private var imagePlaceholder: some View {
        Rectangle()
            .fill(Color.backgroundSecondary)
            .overlay(
                Image(systemName: "photo")
                    .foregroundColor(.textTertiary)
            )
    }

    private func statBadge(value: String, label: String) -> some View {
        VStack(spacing: 0) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundColor(.textTertiary)
        }
    }

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 80...100: return .scoreExcellent
        case 60..<80: return .scoreGood
        case 40..<60: return .scoreFair
        default: return .scorePoor
        }
    }
}

#Preview {
    VerticalComparisonView(
        productA: .mockYogurt,
        scoreA: .mock(score: 78),
        productB: .mockIceCream,
        scoreB: .mock(score: 35)
    )
    .environmentObject(AppState())
}
