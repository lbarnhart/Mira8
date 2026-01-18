import Foundation

struct TierMappingOutput {
    let breakdown: [ContributionGroupSummary]
    let contributions: [NutrientContribution]
    let explanation: String
    let adjustments: [ScoreAdjustment]
    let topReasons: [String]
}

final class TierMapper {
    func map(evaluation: PillarEvaluation, guardrail: GuardrailOutcome) -> TierMappingOutput {
        let breakdown = buildBreakdown(
            positiveWeighted: evaluation.weightedPositivePoints,
            positiveRaw: evaluation.rawPositivePoints,
            negativeWeighted: evaluation.weightedNegativePoints,
            negativeRaw: evaluation.rawNegativePoints,
            contributions: evaluation.contributions
        )
        let explanation = buildExplanation(contributions: evaluation.contributions, guardrail: guardrail)
        let topReasons = buildTopReasons(from: evaluation.contributions)
        let adjustments = buildAdjustments(from: guardrail)

        return TierMappingOutput(
            breakdown: breakdown,
            contributions: evaluation.contributions,
            explanation: explanation,
            adjustments: adjustments,
            topReasons: topReasons
        )
    }

    private func buildBreakdown(
        positiveWeighted: Double,
        positiveRaw: Int,
        negativeWeighted: Double,
        negativeRaw: Int,
        contributions: [NutrientContribution]
    ) -> [ContributionGroupSummary] {
        let positiveFactors = contributions
            .filter { $0.kind == .positive && ($0.weightedPoints > 0 || $0.dataAvailable) }
            .sorted { $0.weightedPoints > $1.weightedPoints }
            .map { formattedContribution($0) }

        let negativeFactors = contributions
            .filter { $0.kind == .negative && ($0.weightedPoints > 0 || $0.dataAvailable) }
            .sorted { $0.weightedPoints > $1.weightedPoints }
            .map { formattedContribution($0) }

        let positiveMaxWeighted = contributions
            .filter { $0.kind == .positive }
            .reduce(0) { $0 + ($1.maxPoints * $1.weightMultiplier) }

        let negativeMaxWeighted = contributions
            .filter { $0.kind == .negative }
            .reduce(0) { $0 + ($1.maxPoints * $1.weightMultiplier) }

        let positiveSummary = ContributionGroupSummary(
            group: .positive,
            title: "Positive nutrients",
            rawPoints: positiveRaw,
            weightedPoints: positiveWeighted,
            maxPoints: positiveMaxWeighted,
            explanation: positiveFactors.isEmpty ? "No positive bonuses awarded." : "Rewards nutrient density and produce content.",
            keyFactors: positiveFactors
        )

        let negativeSummary = ContributionGroupSummary(
            group: .negative,
            title: "Negative nutrients",
            rawPoints: negativeRaw,
            weightedPoints: negativeWeighted,
            maxPoints: negativeMaxWeighted,
            explanation: negativeFactors.isEmpty ? "No penalties applied." : "Penalizes energy-dense or sodium-heavy items.",
            keyFactors: negativeFactors
        )

        return [positiveSummary, negativeSummary]
    }

    private func formattedContribution(_ contribution: NutrientContribution) -> String {
        if !contribution.dataAvailable {
            return "No data for \(contribution.label)"
        }

        let valueText: String
        if let value = contribution.value {
            switch contribution.unit {
            case "%": valueText = String(format: "%.0f%%", value)
            case "mg": valueText = String(format: "%.0f mg", value)
            default: valueText = String(format: "%.1f %@", value, contribution.unit)
            }
        } else {
            valueText = "n/a"
        }

        return "\(contribution.label): \(valueText) → \(Int(contribution.weightedPoints.rounded())) pts"
    }

    private func buildExplanation(
        contributions: [NutrientContribution],
        guardrail: GuardrailOutcome
    ) -> String {
        let topPositive = contributions
            .filter { $0.kind == .positive && $0.weightedPoints > 0 }
            .sorted { $0.weightedPoints > $1.weightedPoints }
            .prefix(2)
            .map { "\($0.label) (+\(Int($0.weightedPoints.rounded())))" }
            .joined(separator: ", ")

        let topNegative = contributions
            .filter { $0.kind == .negative && $0.weightedPoints > 0 }
            .sorted { $0.weightedPoints > $1.weightedPoints }
            .prefix(2)
            .map { "\($0.label) (-\(Int($0.weightedPoints.rounded())))" }
            .joined(separator: ", ")

        var segments: [String] = []
        segments.append("Score starts at 40, adds weighted positives, and subtracts weighted negatives.")

        if !topPositive.isEmpty {
            segments.append("Top boosts: \(topPositive).")
        }

        if !topNegative.isEmpty {
            segments.append("Major penalties: \(topNegative).")
        }

        if let warning = guardrail.warning {
            segments.append(warning)
        }

        return segments.joined(separator: " ")
    }

    private func buildTopReasons(from contributions: [NutrientContribution]) -> [String] {
        var reasons: [String] = []

        if let topPositive = contributions
            .filter({ $0.kind == .positive && $0.weightedPoints > 0 })
            .sorted(by: { $0.weightedPoints > $1.weightedPoints })
            .first {
            reasons.append("Boost: \(topPositive.label) (+\(Int(topPositive.weightedPoints.rounded())))")
        }

        if let topNegative = contributions
            .filter({ $0.kind == .negative && $0.weightedPoints > 0 })
            .sorted(by: { $0.weightedPoints > $1.weightedPoints })
            .first {
            reasons.append("Penalty: \(topNegative.label) (-\(Int(topNegative.weightedPoints.rounded())))")
        }

        return reasons
    }

    private func buildAdjustments(from guardrail: GuardrailOutcome) -> [ScoreAdjustment] {
        var adjustments: [ScoreAdjustment] = []

        for cap in guardrail.capsApplied {
            adjustments.append(
                ScoreAdjustment(
                    label: "Tier Cap",
                    delta: 0,
                    reason: cap.reason
                )
            )
        }

        for trigger in guardrail.triggers {
            let label = trigger.severity == .hardFail ? "Hard Fail" : "Red Trigger"
            adjustments.append(
                ScoreAdjustment(
                    label: label,
                    delta: 0,
                    reason: trigger.message
                )
            )
        }

        return adjustments
    }
}
