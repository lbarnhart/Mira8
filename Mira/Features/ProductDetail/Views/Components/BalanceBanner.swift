import SwiftUI

/// Banner that reminds users about nutritional balance, shown for low-scoring products
/// Reduces food anxiety by providing context and perspective
struct BalanceBanner: View {
    @AppStorage("hasSeenBalanceBanner") private var hasSeenBalanceBanner = false
    @State private var isDismissed = false

    let onNavigateToInsights: () -> Void

    var body: some View {
        if !hasSeenBalanceBanner && !isDismissed {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: "heart.circle.fill")
                        .font(.title3)
                        .foregroundColor(.primaryBlue)

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Remember: Balance matters most")
                            .font(.headline)
                            .foregroundColor(.textPrimary)

                        Text("No single food makes or breaks your health. Focus on overall patterns, not individual products.")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Button {
                        withAnimation {
                            isDismissed = true
                            hasSeenBalanceBanner = true
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.textTertiary)
                    }
                }

                Button {
                    onNavigateToInsights()
                } label: {
                    HStack {
                        Text("See Your Weekly Patterns")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Image(systemName: "arrow.right")
                            .font(.caption)
                    }
                    .foregroundColor(.primaryBlue)
                }
                .padding(.top, Spacing.xxs)
            }
            .padding(Spacing.md)
            .background(Color.primaryBlue.opacity(0.08))
            .cornerRadius(CornerRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .strokeBorder(Color.primaryBlue.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

#Preview {
    VStack {
        BalanceBanner {
            print("Navigate to insights")
        }
        .padding()

        Spacer()
    }
}
