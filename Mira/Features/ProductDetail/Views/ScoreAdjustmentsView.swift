import SwiftUI

/// Displays detailed adjustments that impacted the overall score
struct ScoreAdjustmentsView: View {
    let adjustments: [ScoreAdjustment]
    @State private var showAllDetails = false

    private var positiveAdjustments: [ScoreAdjustment] {
        adjustments.filter { $0.delta > 0 }
    }

    private var negativeAdjustments: [ScoreAdjustment] {
        adjustments.filter { $0.delta < 0 }
    }

    private var neutralAdjustments: [ScoreAdjustment] {
        adjustments.filter { $0.delta == 0 }
    }

    private var netImpact: Double {
        adjustments.reduce(0) { $0 + $1.delta }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                Text("Score Adjustments")
                    .font(.title3)
                    .fontWeight(.bold)

                Spacer()

                if !adjustments.isEmpty {
                    netImpactBadge
                }
            }
            .padding(.horizontal, Spacing.md)

            if adjustments.isEmpty {
                emptyState
            } else {
                VStack(spacing: Spacing.md) {
                    // Summary section
                    adjustmentSummary

                    // Show More/Less button
                    if !adjustments.isEmpty {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showAllDetails.toggle()
                            }
                        } label: {
                            HStack {
                                Text(showAllDetails ? "Hide details" : "Show detailed adjustments")
                                    .font(.bodyMedium)
                                    .fontWeight(.medium)

                                Image(systemName: showAllDetails ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                    .font(.body)
                            }
                            .foregroundColor(.primaryBlue)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, Spacing.md)
                    }

                    // Detailed adjustments (expandable)
                    if showAllDetails {
                        detailedAdjustments
                    }
                }
            }
        }
    }

    private var netImpactBadge: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: netImpact >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .foregroundColor(netImpact >= 0 ? .green : .red)
                .font(.caption)

            Text(netImpact >= 0 ? "+\(netImpact, specifier: "%.1f")" : "\(netImpact, specifier: "%.1f")")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(netImpact >= 0 ? .green : .red)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs)
        .background((netImpact >= 0 ? Color.green : Color.red).opacity(0.12))
        .cornerRadius(CornerRadius.pill)
    }

    private var emptyState: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "equal.circle")
                .foregroundColor(.textSecondary)
            Text("No adjustments applied to this product's score")
                .font(.bodyMedium)
                .foregroundColor(.textSecondary)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.card)
        .padding(.horizontal, Spacing.md)
    }

    private var adjustmentSummary: some View {
        VStack(spacing: Spacing.sm) {
            if !positiveAdjustments.isEmpty {
                summaryCard(
                    title: "Positive Factors",
                    count: positiveAdjustments.count,
                    totalImpact: positiveAdjustments.reduce(0) { $0 + $1.delta },
                    color: .green,
                    icon: "arrow.up.circle.fill"
                )
            }

            if !negativeAdjustments.isEmpty {
                summaryCard(
                    title: "Negative Factors",
                    count: negativeAdjustments.count,
                    totalImpact: negativeAdjustments.reduce(0) { $0 + $1.delta },
                    color: .red,
                    icon: "arrow.down.circle.fill"
                )
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    private func summaryCard(title: String, count: Int, totalImpact: Double, color: Color, icon: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)

                Text("\(count) adjustment\(count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .foregroundColor(color)

                Text(totalImpact >= 0 ? "+\(totalImpact, specifier: "%.1f")" : "\(totalImpact, specifier: "%.1f")")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
        }
        .padding(Spacing.md)
        .background(color.opacity(0.08))
        .cornerRadius(CornerRadius.card)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }

    private var detailedAdjustments: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if !positiveAdjustments.isEmpty {
                adjustmentSection(
                    title: "Score Boosts",
                    adjustments: positiveAdjustments,
                    color: .green
                )
            }

            if !negativeAdjustments.isEmpty {
                adjustmentSection(
                    title: "Score Reductions",
                    adjustments: negativeAdjustments,
                    color: .red
                )
            }

            if !neutralAdjustments.isEmpty {
                adjustmentSection(
                    title: "Informational",
                    adjustments: neutralAdjustments,
                    color: .gray
                )
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    private func adjustmentSection(title: String, adjustments: [ScoreAdjustment], color: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .padding(.horizontal, Spacing.xs)

            VStack(spacing: Spacing.xs) {
                ForEach(adjustments, id: \.label) { adjustment in
                    adjustmentRow(adjustment: adjustment, color: color)
                }
            }
        }
    }

    private func adjustmentRow(adjustment: ScoreAdjustment, color: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(alignment: .top) {
                Image(systemName: adjustment.delta > 0 ? "plus.circle.fill" : adjustment.delta < 0 ? "minus.circle.fill" : "info.circle.fill")
                    .foregroundColor(color)
                    .font(.caption)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack {
                        Text(adjustment.label)
                            .font(.bodyMedium)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)

                        Spacer()

                        if adjustment.delta != 0 {
                            Text(adjustment.delta > 0 ? "+\(adjustment.delta, specifier: "%.1f")" : "\(adjustment.delta, specifier: "%.1f")")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(color)
                        }
                    }

                    Text(adjustment.reason)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(Spacing.sm)
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
    }
}

#Preview {
    let sampleAdjustments = [
        ScoreAdjustment(
            label: "Low Cholesterol Bonus",
            delta: 5.0,
            reason: "Heart-friendly cholesterol amount (30mg <50mg)"
        ),
        ScoreAdjustment(
            label: "Heart-Friendly Ingredients",
            delta: 3.0,
            reason: "Contains ingredients associated with cardiovascular benefits"
        ),
        ScoreAdjustment(
            label: "High Cholesterol Penalty",
            delta: -15.0,
            reason: "Cholesterol 150mg exceeds 100mg threshold; AHA recommends limiting cholesterol intake; ideally <100mg per serving"
        ),
        ScoreAdjustment(
            label: "Harmful Additives Penalty",
            delta: -20.0,
            reason: "Contains 1 concerning additive(s)"
        ),
        ScoreAdjustment(
            label: "Long Ingredient List",
            delta: -8.0,
            reason: "Product has 14 ingredients (penalty for >10 ingredients)"
        ),
        ScoreAdjustment(
            label: "Micronutrient Estimation",
            delta: 0,
            reason: "Limited micronutrient data—using fiber/protein proxy for density estimation"
        )
    ]

    ScrollView {
        ScoreAdjustmentsView(adjustments: sampleAdjustments)
            .padding()
    }
    .background(Color.backgroundPrimary)
}
