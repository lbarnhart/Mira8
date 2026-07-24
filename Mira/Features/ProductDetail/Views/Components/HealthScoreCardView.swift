import Foundation
import SwiftUI

/// A calm, decision-first score summary. Detailed evidence remains available
/// through the explanation sheet without competing with the shopping decision.
struct HealthScoreCardView: View {
    let healthScore: HealthScore
    let productName: String
    let dataSource: ProductSource?
    var healthFocus: HealthFocus = .generalWellness
    let onShowExplanation: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top, spacing: Spacing.md) {
                ScoreGauge(
                    score: healthScore.overall,
                    size: 96,
                    confidence: nil
                )

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(healthScore.verdict.label)
                        .font(.title3.weight(.bold))
                        .foregroundColor(scoreColor)

                    Text(healthScore.verdict.message)
                        .font(.subheadline)
                        .foregroundColor(.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(healthFocus.displayName)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.primaryBlue)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.primaryBlue.opacity(0.1))
                        .cornerRadius(CornerRadius.pill)
                }

                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("productDetail.focusSnapshot")

            if !healthScore.topReasons.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(Array(healthScore.topReasons.prefix(2)), id: \.self) { reason in
                        HStack(alignment: .top, spacing: Spacing.xs) {
                            Image(systemName: reasonIcon(for: reason))
                                .font(.caption)
                                .foregroundColor(reasonColor(for: reason))
                                .frame(width: 16)
                                .padding(.top, 2)

                            Text(plainReason(reason))
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            if healthScore.confidence != .high {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: sourceIcon)
                        .accessibilityHidden(true)

                    Text(sourceSummary)
                    Text("·")
                    Text(healthScore.confidence.displayName)
                }
                .font(.caption)
                .foregroundColor(healthScore.confidence == .low ? .scoreFair : .textSecondary)
                .accessibilityElement(children: .combine)
            }

            Button {
                onShowExplanation()
            } label: {
                HStack {
                    Text("Why this score?")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primaryBlue)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("productDetail.scoreExplanation")
        }
        .padding(Spacing.md)
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.card)
    }

    private var scoreColor: Color {
        Color.scoreColor(for: healthScore.overall)
    }

    private var sourceIcon: String {
        healthScore.confidence == .low ? "exclamationmark.triangle" : "checkmark.shield"
    }

    private var sourceSummary: String {
        guard let dataSource else {
            return "Source details unavailable"
        }
        return "Data from \(dataSource.displayName)"
    }

    private func plainReason(_ reason: String) -> String {
        let withoutPoints = reason.replacingOccurrences(
            of: #"\s*\([+\-−]\d+(?:\.\d+)?\)\s*$"#,
            with: "",
            options: .regularExpression
        )

        if withoutPoints.hasPrefix("Boost: ") {
            return String(withoutPoints.dropFirst("Boost: ".count)) + " helps"
        }
        if withoutPoints.hasPrefix("Penalty: ") {
            return String(withoutPoints.dropFirst("Penalty: ".count)) + " lowers the score"
        }
        return withoutPoints
    }

    private func reasonIcon(for reason: String) -> String {
        reason.hasPrefix("Penalty: ") ? "minus.circle.fill" : "plus.circle.fill"
    }

    private func reasonColor(for reason: String) -> Color {
        reason.hasPrefix("Penalty: ") ? .scorePoor : .scoreExcellent
    }
}
