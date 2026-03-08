import SwiftUI

/// Displays dietary restriction evaluation results with detailed violations and warnings.
/// Supports both legacy DietaryRestrictionResult and new DietaryAnalysisResult.
struct DietaryRestrictionsSectionView: View {
    // Support both old and new result types
    let legacyResults: [DietaryRestrictionResult]
    let analysisResults: [DietaryAnalysisResult]
    let isLoading: Bool
    let isAIEnhanced: Bool

    @State private var expandedRestriction: DietaryRestriction?

    init(
        results: [DietaryRestrictionResult] = [],
        analysisResults: [DietaryAnalysisResult] = [],
        isLoading: Bool = false,
        isAIEnhanced: Bool = false
    ) {
        self.legacyResults = results
        self.analysisResults = analysisResults
        self.isLoading = isLoading
        self.isAIEnhanced = isAIEnhanced
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            headerView

            if isLoading {
                loadingView
            } else if !analysisResults.isEmpty {
                enhancedResultsView
            } else if !legacyResults.isEmpty {
                legacyResultsView
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text("Dietary Restrictions")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)

            Spacer()

            if isAIEnhanced {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                    Text("AI Enhanced")
                        .font(.caption2)
                }
                .foregroundColor(.primaryBlue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.primaryBlue.opacity(0.12))
                .cornerRadius(CornerRadius.sm)
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        HStack(spacing: Spacing.sm) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Analyzing dietary compliance...")
                .font(.callout)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Enhanced Results (New Model)

    private var enhancedResultsView: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(analysisResults) { result in
                EnhancedDietaryBadge(
                    result: result,
                    isExpanded: expandedRestriction == result.restriction,
                    onToggle: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if expandedRestriction == result.restriction {
                                expandedRestriction = nil
                            } else {
                                expandedRestriction = result.restriction
                            }
                        }
                    }
                )
            }
        }
    }

    // MARK: - Legacy Results (Old Model)

    private var legacyResultsView: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(legacyResults) { result in
                DietaryRestrictionBadge(result: result)
            }
        }
    }
}

// MARK: - Enhanced Dietary Badge

/// New badge component that shows detailed violations and warnings
struct EnhancedDietaryBadge: View {
    let result: DietaryAnalysisResult
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main badge row
            Button(action: onToggle) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: result.status.iconName)
                        .font(.title3)
                        .foregroundColor(statusColor)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(statusText)
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(statusColor)

                            if result.analysisMethod == .aiEnhanced {
                                Image(systemName: "sparkles")
                                    .font(.caption2)
                                    .foregroundColor(.primaryBlue)
                            }
                        }

                        Text(result.reason)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .lineLimit(isExpanded ? nil : 1)
                    }

                    Spacer()

                    if hasDetails {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.textTertiary)
                    }

                    confidenceBadge
                }
                .padding(Spacing.md)
            }
            .buttonStyle(.plain)

            // Expanded details
            if isExpanded && hasDetails {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Divider()
                        .padding(.horizontal, Spacing.md)

                    // Violations
                    if !result.violations.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Label("Violations", systemImage: "xmark.circle")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.scorePoor)

                            ForEach(result.violations) { violation in
                                ViolationRow(violation: violation)
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                    }

                    // Warnings
                    if !result.warnings.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Label("Warnings", systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)

                            ForEach(result.warnings) { warning in
                                WarningRow(warning: warning)
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                }
                .padding(.bottom, Spacing.md)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(backgroundColor)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private var hasDetails: Bool {
        !result.violations.isEmpty || !result.warnings.isEmpty
    }

    private var statusText: String {
        switch result.status {
        case .compliant:
            return "✓ \(result.restriction.displayName)"
        case .violation:
            return "✗ \(result.restriction.displayName)"
        case .uncertain:
            return "⚠️ \(result.restriction.displayName) - Uncertain"
        case .mayContain:
            return "⚠️ \(result.restriction.displayName) - May Contain"
        }
    }

    private var statusColor: Color {
        switch result.status {
        case .compliant: return .scoreExcellent
        case .violation: return .scorePoor
        case .uncertain, .mayContain: return .orange
        }
    }

    private var backgroundColor: Color {
        statusColor.opacity(0.12)
    }

    private var borderColor: Color {
        statusColor.opacity(0.35)
    }

    private var confidenceBadge: some View {
        Text(confidenceText)
            .font(.caption2)
            .foregroundColor(confidenceColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(confidenceColor.opacity(0.12))
            .cornerRadius(4)
    }

    private var confidenceText: String {
        switch result.confidence {
        case .high: return "High"
        case .medium: return "Med"
        case .low: return "Low"
        }
    }

    private var confidenceColor: Color {
        switch result.confidence {
        case .high: return .green
        case .medium: return .orange
        case .low: return .gray
        }
    }
}

// MARK: - Violation Row

struct ViolationRow: View {
    let violation: DietaryViolation

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            Circle()
                .fill(Color.scorePoor)
                .frame(width: 6, height: 6)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(violation.description)
                    .font(.caption)
                    .foregroundColor(.textPrimary)

                if let explanation = violation.aiExplanation {
                    Text(explanation)
                        .font(.caption2)
                        .foregroundColor(.textTertiary)
                        .italic()
                }
            }
        }
        .padding(.leading, Spacing.sm)
    }
}

// MARK: - Warning Row

struct WarningRow: View {
    let warning: DietaryWarning

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            Image(systemName: warning.iconName)
                .font(.caption2)
                .foregroundColor(.orange)
                .frame(width: 12)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(warning.description)
                    .font(.caption)
                    .foregroundColor(.textPrimary)

                if let explanation = warning.aiExplanation {
                    Text(explanation)
                        .font(.caption2)
                        .foregroundColor(.textTertiary)
                        .italic()
                }
            }
        }
        .padding(.leading, Spacing.sm)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: Spacing.md) {
            // AI Enhanced Results
            DietaryRestrictionsSectionView(
                analysisResults: [
                    .violation(
                        restriction: .vegan,
                        violations: [
                            DietaryViolation(
                                ingredient: "Casein",
                                violationType: .derivativeMatch,
                                isDerivative: true,
                                derivedFrom: "milk",
                                aiExplanation: "Casein is a protein derived from cow's milk"
                            )
                        ],
                        confidence: .high,
                        method: .aiEnhanced
                    ),
                    .mayContain(
                        restriction: .nutFree,
                        warnings: [
                            DietaryWarning(
                                warningType: .crossContamination,
                                detail: "tree nuts",
                                aiExplanation: "Product label indicates cross-contamination risk"
                            )
                        ],
                        confidence: .medium,
                        method: .aiEnhanced
                    ),
                    .compliant(
                        restriction: .glutenFree,
                        confidence: .high,
                        method: .regexOnly
                    )
                ],
                isAIEnhanced: true
            )

            // Legacy Results
            DietaryRestrictionsSectionView(
                results: [
                    DietaryRestrictionResult(
                        restriction: "Vegan",
                        passes: true,
                        reason: "No animal-derived ingredients detected"
                    ),
                    DietaryRestrictionResult(
                        restriction: "Gluten-Free",
                        passes: false,
                        reason: "Contains Wheat"
                    )
                ]
            )

            // Loading State
            DietaryRestrictionsSectionView(
                isLoading: true
            )
        }
        .padding()
    }
    .background(Color.backgroundPrimary)
}
