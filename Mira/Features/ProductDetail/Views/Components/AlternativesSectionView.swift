import SwiftUI

/// Displays the better alternatives section
struct AlternativesSectionView: View {
    let alternatives: [AlternativeProduct]
    let isLoading: Bool
    let message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Better Alternatives")
                .font(.title3)
                .fontWeight(.semibold)

            if isLoading {
                LoadingView()
            } else if let message = message {
                EmptyStateView(
                    title: "No Alternatives Yet",
                    subtitle: message,
                    systemImage: "lightbulb"
                )
                .padding(.vertical, Spacing.sm)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(alternatives.enumerated()), id: \.offset) { index, alt in
                        AlternativeProductCard(alternative: alt, rank: index + 1)
                    }
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
}
