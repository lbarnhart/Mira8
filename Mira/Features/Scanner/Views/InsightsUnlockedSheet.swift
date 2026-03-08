import SwiftUI

/// Celebratory sheet shown after 5 scans to promote the Insights tab
struct InsightsUnlockedSheet: View {
    let onViewInsights: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                Spacer()

                // Celebration icon with animation
                ZStack {
                    Circle()
                        .fill(Color.primaryBlue.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 50))
                        .foregroundColor(.primaryBlue)
                }

                // Title
                VStack(spacing: Spacing.xs) {
                    Text("🎉 Insights Unlocked!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)

                    Text("You've scanned 5 products")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }

                // Benefits list
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Your personalized insights are ready:")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    insightBenefit(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Weekly Nutrition Summary",
                        description: "See your average scores and nutrition patterns"
                    )

                    insightBenefit(
                        icon: "exclamationmark.triangle",
                        title: "Nutrition Gaps",
                        description: "Discover which nutrients you might be missing"
                    )

                    insightBenefit(
                        icon: "sparkles",
                        title: "AI Recommendations",
                        description: "Get personalized tips to improve your health"
                    )

                    insightBenefit(
                        icon: "chart.pie",
                        title: "Consumption Patterns",
                        description: "Understand your food choices over time"
                    )
                }
                .padding(.horizontal, Spacing.lg)

                Spacer()

                // Call to action
                VStack(spacing: Spacing.md) {
                    Button {
                        dismiss()
                        onViewInsights()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("View My Insights")
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
                    } label: {
                        Text("Maybe Later")
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, Spacing.xs)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
            }
            .navigationTitle("Insights Ready")
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

    // MARK: - Helper Views

    private func insightBenefit(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.primaryBlue)
                .frame(width: 28)

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
}

// MARK: - Preview

#Preview {
    InsightsUnlockedSheet(onViewInsights: {})
}
