import Foundation
import SwiftUI

/// Progressive disclosure for people who want to audit Mira's judgment.
/// The sheet starts with a short explanation and keeps the calculation ledger,
/// data caveats, and methodology behind explicit disclosure controls.
struct WhyThisScoreView: View {
    let healthScore: HealthScore
    let productName: String
    let healthFocus: HealthFocus
    let dataSource: ProductSource?

    @Environment(\.dismiss) private var dismiss
    @State private var showPointDetails = false
    @State private var showDataDetails = false
    @State private var showMethodology = false

    private var positiveContributions: [NutrientContribution] {
        healthScore.contributions
            .filter { $0.kind == .positive && $0.weightedPoints > 0 }
            .sorted { $0.weightedPoints > $1.weightedPoints }
    }

    private var negativeContributions: [NutrientContribution] {
        healthScore.contributions
            .filter { $0.kind == .negative && $0.weightedPoints > 0 }
            .sorted { $0.weightedPoints > $1.weightedPoints }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    scoreSummary

                    if !healthScore.topReasons.isEmpty {
                        keyReasons
                    }

                    componentSummary
                    calculationDisclosure
                    dataDisclosure
                    methodologyDisclosure
                }
                .padding()
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("How Mira Scored This")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .accessibilityIdentifier("scoreExplanation.sheet")
    }

    private var scoreSummary: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(scoreColor.opacity(0.14))
                    .frame(width: 76, height: 76)

                VStack(spacing: 0) {
                    Text("\(Int(healthScore.overall.rounded()))")
                        .font(.system(size: 27, weight: .bold, design: .rounded))
                        .foregroundColor(scoreColor)
                    Text("/ 100")
                        .font(.caption2)
                        .foregroundColor(.textTertiary)
                }
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(healthScore.verdict.label)
                    .font(.title3.weight(.bold))
                    .foregroundColor(scoreColor)

                Text(productName)
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)

                Text("Using your \(healthFocus.displayName.lowercased()) lens")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(Spacing.md)
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.card)
    }

    private var keyReasons: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("The short answer")
                .font(.headline)

            ForEach(Array(healthScore.topReasons.prefix(2)), id: \.self) { reason in
                HStack(alignment: .top, spacing: Spacing.xs) {
                    Circle()
                        .fill(scoreColor)
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)
                    Text(plainReason(reason))
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var componentSummary: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Score at a glance")
                .font(.headline)

            VStack(spacing: Spacing.sm) {
                scoreRow(
                    label: "Nutrient balance",
                    value: "\(Int(healthScore.rawScore.rounded()))"
                )

                let ruleImpact = healthScore.overall - healthScore.rawScore
                if abs(ruleImpact) >= 0.5 {
                    scoreRow(
                        label: "Rules and data limits",
                        value: ruleImpact > 0
                            ? "+\(Int(ruleImpact.rounded()))"
                            : "\(Int(ruleImpact.rounded()))"
                    )
                }

                Divider()

                scoreRow(
                    label: "Final Mira score",
                    value: "\(Int(healthScore.overall.rounded()))",
                    emphasized: true
                )
            }
            .padding(Spacing.md)
            .background(Color.backgroundSecondary)
            .cornerRadius(CornerRadius.card)
        }
        .accessibilityIdentifier("scoreExplanation.componentSummary")
    }

    private func scoreRow(label: String, value: String, emphasized: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(emphasized ? .subheadline.weight(.semibold) : .subheadline)
                .foregroundColor(.textPrimary)
            Spacer()
            Text(value)
                .font(emphasized ? .headline : .subheadline.weight(.semibold))
                .foregroundColor(emphasized ? scoreColor : .textSecondary)
        }
    }

    private var calculationDisclosure: some View {
        DisclosureGroup(isExpanded: $showPointDetails) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                if !positiveContributions.isEmpty {
                    contributionSection(
                        title: "Added points",
                        contributions: positiveContributions,
                        color: .scoreExcellent
                    )
                }

                if !negativeContributions.isEmpty {
                    contributionSection(
                        title: "Removed points",
                        contributions: negativeContributions,
                        color: .scorePoor
                    )
                }

                if !healthScore.adjustments.isEmpty {
                    adjustmentSection
                }
            }
            .padding(.top, Spacing.md)
        } label: {
            disclosureLabel(
                title: "Point-by-point calculation",
                subtitle: "See every factor that changed the score",
                icon: "function"
            )
        }
        .padding(Spacing.md)
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.card)
        .accessibilityIdentifier("scoreExplanation.calculation")
    }

    private func contributionSection(
        title: String,
        contributions: [NutrientContribution],
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(color)

            ForEach(contributions) { contribution in
                HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(contribution.label)
                            .font(.subheadline)
                            .foregroundColor(.textPrimary)

                        if let value = contribution.value {
                            Text("\(formatValue(value, unit: contribution.unit)) · \(contribution.guideline)")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Spacer(minLength: Spacing.sm)

                    Text(pointText(for: contribution))
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(color)
                }
            }
        }
    }

    private var adjustmentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Other rules")
                .font(.subheadline.weight(.semibold))

            ForEach(healthScore.adjustments, id: \.label) { adjustment in
                HStack(alignment: .top, spacing: Spacing.sm) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(adjustment.label)
                            .font(.subheadline)
                        Text(adjustment.reason)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: Spacing.sm)

                    if adjustment.delta != 0 {
                        Text(adjustment.delta > 0
                             ? "+\(adjustment.delta, specifier: "%.0f")"
                             : "\(adjustment.delta, specifier: "%.0f")")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(adjustment.delta > 0 ? .scoreExcellent : .scorePoor)
                    }
                }
            }
        }
    }

    private var dataDisclosure: some View {
        DisclosureGroup(isExpanded: $showDataDetails) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                detailRow(label: "Product data", value: dataSource?.displayName ?? "Source unavailable")
                detailRow(label: "Data confidence", value: healthScore.confidence.displayName)

                if let scoring = healthScore.scoringResult {
                    detailRow(label: "Category", value: scoring.categoryLabel)

                    if !scoring.missingFields.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Missing from this record")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.scoreFair)
                            Text(scoring.missingFields.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }

                Text("Product records can be incomplete or out of date. Verify important values against the current package label.")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, Spacing.md)
        } label: {
            disclosureLabel(
                title: "Data source and confidence",
                subtitle: sourceDisclosureSummary,
                icon: healthScore.confidence == .low ? "exclamationmark.triangle" : "checkmark.shield"
            )
        }
        .padding(Spacing.md)
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.card)
        .accessibilityIdentifier("scoreExplanation.data")
    }

    private var methodologyDisclosure: some View {
        DisclosureGroup(isExpanded: $showMethodology) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Mira evaluates nutrients, ingredient quality, processing, and additives. Your selected health focus changes their relative weights; it does not change the underlying product facts.")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let scoring = healthScore.scoringResult {
                    detailRow(label: "Scoring version", value: scoring.algorithmVersion)
                    detailRow(label: "Weight profile", value: scoring.weightsProfileID)
                    detailRow(label: "Threshold set", value: scoring.thresholdSetID)
                }

                Text("The score is a decision aid, not medical advice. Different priorities can reasonably produce a different judgment.")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let methodologyURL = AppConfiguration.shared.methodologyURL {
                    Link(destination: methodologyURL) {
                        Label("Read the full methodology", systemImage: "arrow.up.right.square")
                            .font(.subheadline.weight(.semibold))
                    }
                    .accessibilityIdentifier("scoreExplanation.methodologyLink")
                }
            }
            .padding(.top, Spacing.md)
        } label: {
            disclosureLabel(
                title: "Methodology",
                subtitle: "What Mira values and why",
                icon: "book.closed"
            )
        }
        .padding(Spacing.md)
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.card)
        .accessibilityIdentifier("scoreExplanation.methodology")
    }

    private func disclosureLabel(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(.primaryBlue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
            Spacer()
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }

    private var scoreColor: Color {
        Color.scoreColor(for: healthScore.overall)
    }

    private var sourceDisclosureSummary: String {
        let source = dataSource?.displayName ?? "Source unavailable"
        return "\(source) · \(healthScore.confidence.displayName)"
    }

    private func pointText(for contribution: NutrientContribution) -> String {
        let points = Int(contribution.weightedPoints.rounded())
        return contribution.kind == .positive ? "+\(points)" : "−\(points)"
    }

    private func formatValue(_ value: Double, unit: String) -> String {
        if value.rounded() == value {
            return "\(Int(value))\(unit)"
        }
        return String(format: "%.1f%@", value, unit)
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
}
