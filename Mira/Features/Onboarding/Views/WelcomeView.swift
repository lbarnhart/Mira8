import SwiftUI
import UIKit

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: Spacing.xl) {
            VStack(spacing: Spacing.md) {
                Group {
                    if let uiImage = UIImage(named: "MiraLogo") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Image(systemName: "leaf.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.primaryBlue)
                    }
                }
                .frame(width: 72, height: 72)
                .padding()
                .background(Color.primaryBlue.opacity(0.08))
                .cornerRadius(CornerRadius.sm)

                VStack(spacing: Spacing.xs) {
                    Text("Welcome to Mira")
                        .font(.largeTitle.bold())
                        .foregroundColor(.textPrimary)

                    Text("Scan food products, understand the tradeoffs fast, and make better choices for your health focus.")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, Spacing.screenPadding)
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
