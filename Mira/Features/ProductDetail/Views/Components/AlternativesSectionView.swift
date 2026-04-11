import SwiftUI

/// Displays the better alternatives section
struct AlternativesSectionView: View {
    let alternatives: [AlternativeProduct]
    let isLoading: Bool
    let message: String?
    let healthFocusName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Better Alternatives")
                    .font(.title3)
                    .fontWeight(.semibold)

                if !alternatives.isEmpty {
                    Text("\(alternatives.count) stronger matches for \(healthFocusName.lowercased())")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
            }

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
                alternativeSummary

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

    @ViewBuilder
    private var alternativeSummary: some View {
        if !alternatives.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    summaryBadge(
                        title: "Avg lift",
                        value: "+\(Int(averageImprovement.rounded()))"
                    )

                    summaryBadge(
                        title: "Best pick",
                        value: "#1"
                    )
                }

                if !topReasons.isEmpty {
                    Text(topReasons.joined(separator: " • "))
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(Spacing.md)
            .background(Color.primaryBlue.opacity(0.08))
            .cornerRadius(CornerRadius.card)
        }
    }

    private var averageImprovement: Double {
        guard !alternatives.isEmpty else { return 0 }
        return alternatives.reduce(0) { $0 + $1.improvement } / Double(alternatives.count)
    }

    private var topReasons: [String] {
        Array(
            Set(
                alternatives
                    .flatMap(\.improvementReasons)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
        )
        .sorted()
        .prefix(3)
        .map { $0 }
    }

    private func summaryBadge(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundColor(.textTertiary)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primaryBlue)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color.backgroundPrimary)
        .cornerRadius(CornerRadius.button)
    }
}
