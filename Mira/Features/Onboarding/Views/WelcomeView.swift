import SwiftUI
import UIKit

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: Spacing.xl) {
            VStack(spacing: Spacing.md) {
                Group {
                    if let uiImage = UIImage(named: "welcomeIcon") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                    }
                }
                .frame(width: 64, height: 64)
                .padding()
                .background(Color.primaryBlue.opacity(0.08))
                .cornerRadius(CornerRadius.sm)
            }
            .padding(.top, Spacing.lg)

            VStack(spacing: Spacing.md) {
                BenefitRow(icon: "barcode.viewfinder", title: "Instant Product Scans", description: "Quickly capture nutritional details with a single scan.")

                BenefitRow(icon: "heart.text.square.fill", title: "Personalized Scores", description: "See how each item aligns with your health goals.")

                BenefitRow(icon: "leaf.fill", title: "Better Choices", description: "Discover healthier alternatives tailored to you.")
            }
            .padding(.horizontal, Spacing.screenPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.xxl)
    }
}

private struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.primaryBlue)
                .frame(width: 36, height: 36)
                .background(Color.primaryBlue.opacity(0.1))
                .cornerRadius(CornerRadius.button)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(description)
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .cardStyle(.elevated)
    }
}

#Preview {
    WelcomeView()
        .background(Color.backgroundPrimary)
}
