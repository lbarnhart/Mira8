import SwiftUI

/// Sheet shown when user scans a product they've scanned recently
struct DuplicateScanSheet: View {
    let product: ProductModel
    let previousScanDate: Date
    let healthFocus: HealthFocus
    let onViewDetails: () -> Void
    let onScanNew: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var previousScore: Double = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                Spacer()

                // Icon
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 60))
                    .foregroundColor(.primaryBlue)

                // Title
                VStack(spacing: Spacing.xs) {
                    Text("You scanned this \(timeSince)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("on \(formattedDate)")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
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

                    // Previous score
                    HStack(spacing: Spacing.md) {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("Previous score")
                                .font(.caption)
                                .foregroundColor(.textSecondary)

                            Text("For \(healthFocus.displayName)")
                                .font(.caption2)
                                .foregroundColor(.textTertiary)
                        }

                        Spacer()

                        ScoreGauge(
                            score: previousScore,
                            size: 60,
                            style: .minimal,
                            showAnimation: false
                        )
                    }
                }
                .padding(Spacing.lg)
                .background(Color.backgroundSecondary)
                .cornerRadius(CornerRadius.card)
                .padding(.horizontal, Spacing.lg)

                // Info tip
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.primaryBlue)

                    Text("Your health focus hasn't changed, so the score is the same")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, Spacing.lg)

                Spacer()

                // Action buttons
                VStack(spacing: Spacing.md) {
                    Button {
                        dismiss()
                        onViewDetails()
                    } label: {
                        Text("View Full Details")
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
                        Text("Scan a New Product")
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
                        Text("Cancel")
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, Spacing.xs)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
            }
            .navigationTitle("Recently Scanned")
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
            .onAppear {
                // Calculate the score dynamically
                let score = ScoringEngine.shared.calculateHealthScore(
                    for: product,
                    healthFocus: healthFocus,
                    dietaryRestrictions: []
                )
                previousScore = score.overall
            }
        }
    }

    // MARK: - Computed Properties

    private var timeSince: String {
        let components = Calendar.current.dateComponents(
            [.minute, .hour, .day],
            from: previousScanDate,
            to: Date()
        )

        if let days = components.day, days > 0 {
            return days == 1 ? "yesterday" : "\(days) days ago"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        } else {
            return "just now"
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: previousScanDate)
    }
}

// MARK: - Preview

#Preview {
    let sampleProduct = ProductModel(
        id: UUID(),
        name: "Mission Yellow Corn Tortillas",
        brand: "Mission",
        category: "Grains",
        categorySlug: "grains",
        barcode: "1234567890",
        nutrition: ProductNutrition(
            calories: 110,
            protein: 4.3,
            carbohydrates: 21.4,
            fat: 1.1,
            fiber: 4.3,
            sugar: 2.1,
            sodium: 0.14,
            cholesterol: 0,
            servingSize: "47g"
        ),
        ingredients: ["Corn", "Water", "Salt"],
        additives: [],
        processingLevel: .processed,
        dietaryFlags: [],
        imageURL: nil,
        thumbnailURL: nil,
        healthScore: 61,
        createdAt: Date(),
        updatedAt: Date(),
        isCached: false,
        rawIngredientsText: nil
    )

    return DuplicateScanSheet(
        product: sampleProduct,
        previousScanDate: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
        healthFocus: .gutHealth,
        onViewDetails: {},
        onScanNew: {}
    )
}
