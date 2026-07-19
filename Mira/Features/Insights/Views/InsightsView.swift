import SwiftUI

/// Main view for displaying personalized nutrition insights and recommendations.
struct InsightsView: View {
    @StateObject private var viewModel = InsightsViewModel()
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    if viewModel.isLoading && viewModel.profile == nil {
                        loadingView
                    } else if let error = viewModel.errorMessage {
                        errorView(error)
                    } else if !viewModel.hasEnoughData {
                        insufficientDataView
                    } else {
                        insightsContent
                    }
                }
                .padding()
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    periodPicker
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .onAppear {
                viewModel.configure(
                    healthFocus: appState.healthFocus,
                    restrictions: appState.dietaryRestrictions
                )
                Task {
                    await viewModel.loadInsights()
                }
            }
            .onChange(of: appState.healthFocus) { _ in
                reloadInsightsForPreferences()
            }
            .onChange(of: appState.dietaryRestrictions) { _ in
                reloadInsightsForPreferences()
            }
        }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        Menu {
            ForEach(AnalysisPeriod.allCases, id: \.self) { period in
                Button {
                    Task {
                        await viewModel.selectPeriod(period)
                    }
                } label: {
                    HStack {
                        Text(period.displayName)
                        if viewModel.selectedPeriod == period {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.selectedPeriod.displayName)
                    .font(.caption)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundColor(.primaryBlue)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Analyzing your nutrition data...")
                .font(.callout)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text("Unable to Load Insights")
                .font(.headline)

            Text(error)
                .font(.callout)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await viewModel.loadInsights()
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Insufficient Data View

    private var insufficientDataView: some View {
        VStack(spacing: Spacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.primaryBlue.opacity(0.12))
                    .frame(width: 80, height: 80)

                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 36))
                    .foregroundColor(.primaryBlue)
            }

            VStack(spacing: Spacing.sm) {
                Text("Keep Scanning!")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Scan at least 5 products to unlock personalized nutrition insights tailored to your goals.")
                    .font(.callout)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Progress indicator
            VStack(spacing: Spacing.xs) {
                ProgressView(value: Double(viewModel.scanCount), total: 5)
                    .tint(.primaryBlue)

                Text("\(viewModel.scanCount) of 5 products scanned")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
            .padding()
            .background(Color.backgroundSecondary)
            .cornerRadius(CornerRadius.md)
        }
        .padding(.vertical, 40)
    }

    // MARK: - Insights Content

    private var insightsContent: some View {
        VStack(spacing: Spacing.lg) {
            if let profile = viewModel.profile {
                insightSnapshotCard(profile)
            }

            if let nextAction = viewModel.nextPriorityAction {
                nextBestMoveCard(nextAction)
            }

            // Weekly summary card
            if let insight = viewModel.weeklyInsight {
                weeklySummaryCard(insight)
            }

            // Health score overview
            if let profile = viewModel.profile {
                healthScoreCard(profile)
            }

            // Highlights
            if !viewModel.highlights.isEmpty {
                highlightsSection
            }

            // Nutrition gaps
            if !viewModel.topGaps.isEmpty {
                gapsSection
            }

            // Recommendations
            if !viewModel.recommendations.isEmpty {
                recommendationsSection
            }

            // Patterns
            if !viewModel.patterns.isEmpty {
                patternsSection
            }

            // Averages breakdown
            if let averages = viewModel.averages {
                averagesSection(averages)
            }
        }
    }

    private func insightSnapshotCard(_ profile: UserNutritionProfile) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your \(profile.healthFocus.displayName) Snapshot")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Text("\(profile.scanCount) scans across \(viewModel.selectedPeriod.displayName.lowercased())")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Text(lastUpdatedDescription(profile.generatedAt))
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }

            HStack(spacing: Spacing.sm) {
                insightMetric(title: "Alignment", value: "\(Int(profile.overallHealth.rounded()))")
                insightMetric(title: "Top Gap", value: viewModel.primaryGap?.nutrient.displayName ?? "None")
                insightMetric(title: "Patterns", value: "\(viewModel.patterns.count)")
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
    }

    private func nextBestMoveCard(_ action: RecommendedAction) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Next Best Move")
                .font(.headline)
                .foregroundColor(.textPrimary)

            Text(action.action)
                .font(.title3.weight(.semibold))
                .foregroundColor(.primaryBlue)

            Text(action.rationale)
                .font(.callout)
                .foregroundColor(.textSecondary)

            if let nutrient = action.relatedNutrient {
                Label(nutrient.displayName, systemImage: nutrient.iconName)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.textTertiary)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.oceanTeal.opacity(0.14), Color.primaryBlue.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Weekly Summary Card

    private func weeklySummaryCard(_ insight: WeeklyInsight) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.primaryBlue)
                Text(insight.title)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Spacer()
            }

            Text(insight.summary)
                .font(.callout)
                .foregroundColor(.textSecondary)
                .lineSpacing(4)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.primaryBlue.opacity(0.12), Color.primaryBlue.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Health Score Card

    private func healthScoreCard(_ profile: UserNutritionProfile) -> some View {
        HStack(spacing: Spacing.lg) {
            // Score circle
            ZStack {
                Circle()
                    .stroke(Color.backgroundSecondary, lineWidth: 8)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: profile.overallHealth / 100)
                    .stroke(scoreColor(profile.overallHealth), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(Int(profile.overallHealth))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor(profile.overallHealth))
                    Text("score")
                        .font(.caption2)
                        .foregroundColor(.textTertiary)
                }
            }

            // Details
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Goal Alignment")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Text("Based on \(profile.scanCount) products scanned")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                HStack(spacing: 4) {
                    Image(systemName: "target")
                        .font(.caption)
                    Text(profile.healthFocus.displayName)
                        .font(.caption)
                }
                .foregroundColor(.primaryBlue)
            }

            Spacer()
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Highlights Section

    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("This Week")
                .font(.headline)
                .foregroundColor(.textPrimary)

            ForEach(viewModel.highlights) { highlight in
                HighlightRow(highlight: highlight)
            }
        }
    }

    // MARK: - Gaps Section

    private var gapsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Nutrition Gaps")
                .font(.headline)
                .foregroundColor(.textPrimary)

            ForEach(viewModel.topGaps) { gap in
                NutritionGapCard(gap: gap)
            }
        }
    }

    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Recommendations")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                    Text("AI")
                        .font(.caption2)
                }
                .foregroundColor(.primaryBlue)
            }

            ForEach(viewModel.recommendations) { action in
                RecommendationCard(action: action)
            }
        }
    }

    // MARK: - Patterns Section

    private var patternsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Patterns Detected")
                .font(.headline)
                .foregroundColor(.textPrimary)

            ForEach(viewModel.patterns) { pattern in
                PatternCard(pattern: pattern)
            }
        }
    }

    // MARK: - Averages Section

    private func averagesSection(_ averages: NutritionAverages) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Average Per Product")
                .font(.headline)
                .foregroundColor(.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.sm) {
                NutrientAverageCard(nutrient: .calories, value: averages.calories)
                NutrientAverageCard(nutrient: .protein, value: averages.protein)
                NutrientAverageCard(nutrient: .fiber, value: averages.fiber)
                NutrientAverageCard(nutrient: .sugar, value: averages.sugar)
                NutrientAverageCard(nutrient: .sodium, value: averages.sodium)
                NutrientAverageCard(nutrient: .saturatedFat, value: averages.saturatedFat)
            }
        }
    }

    // MARK: - Helpers

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 80...100: return .scoreExcellent
        case 60..<80: return .scoreGood
        case 40..<60: return .scoreFair
        default: return .scorePoor
        }
    }

    private func insightMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundColor(.textTertiary)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.textPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.sm)
        .background(Color.backgroundPrimary)
        .cornerRadius(CornerRadius.button)
    }

    private func lastUpdatedDescription(_ date: Date) -> String {
        RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
    }

    private func reloadInsightsForPreferences() {
        viewModel.configure(
            healthFocus: appState.healthFocus,
            restrictions: appState.dietaryRestrictions
        )

        Task {
            await viewModel.loadInsights()
        }
    }
}

// MARK: - Supporting Views

struct HighlightRow: View {
    let highlight: InsightHighlight

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: highlight.type.iconName)
                .font(.title3)
                .foregroundColor(highlightColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(highlight.message)
                    .font(.callout)
                    .foregroundColor(.textPrimary)

                if let value = highlight.value {
                    Text(value)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(highlightColor.opacity(0.12))
        .cornerRadius(CornerRadius.md)
    }

    private var highlightColor: Color {
        switch highlight.type {
        case .positive: return .scoreExcellent
        case .neutral: return .primaryBlue
        case .needsAttention: return .orange
        }
    }
}

struct NutritionGapCard: View {
    let gap: NutritionGap

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: gap.nutrient.iconName)
                    .foregroundColor(severityColor)

                Text(gap.nutrient.displayName)
                    .font(.callout)
                    .fontWeight(.medium)

                Spacer()

                Text(gap.severity.rawValue.capitalized)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(severityColor.opacity(0.12))
                    .foregroundColor(severityColor)
                    .cornerRadius(4)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.backgroundSecondary)
                        .frame(height: 8)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(severityColor)
                        .frame(width: progressWidth(geometry.size.width), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)

            HStack {
                Text("Current: \(String(format: "%.1f", gap.currentAverage))\(gap.nutrient.unit)")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                Spacer()

                Text("Target: \(String(format: "%.1f", gap.recommendedTarget))\(gap.nutrient.unit)")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
    }

    private var severityColor: Color {
        switch gap.severity {
        case .mild: return .scoreFair
        case .moderate: return .orange
        case .significant: return .scorePoor
        }
    }

    private func progressWidth(_ totalWidth: CGFloat) -> CGFloat {
        let ratio = gap.isDeficiency
            ? gap.currentAverage / gap.recommendedTarget
            : gap.recommendedTarget / gap.currentAverage
        return min(totalWidth, totalWidth * CGFloat(ratio))
    }
}

struct RecommendationCard: View {
    let action: RecommendedAction

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.primaryBlue.opacity(0.12))
                    .frame(width: 28, height: 28)

                Text("\(action.priority)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryBlue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(action.action)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)

                Text(action.rationale)
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                if let nutrient = action.relatedNutrient {
                    HStack(spacing: 4) {
                        Image(systemName: nutrient.iconName)
                            .font(.caption2)
                        Text(nutrient.displayName)
                            .font(.caption2)
                    }
                    .foregroundColor(.textTertiary)
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
    }
}

struct PatternCard: View {
    let pattern: ConsumptionPattern

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: pattern.type.iconName)
                .font(.title3)
                .foregroundColor(.primaryBlue)

            VStack(alignment: .leading, spacing: 2) {
                Text(pattern.type.displayName)
                    .font(.caption)
                    .foregroundColor(.textTertiary)

                Text(pattern.description)
                    .font(.callout)
                    .foregroundColor(.textPrimary)
            }

            Spacer()
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
    }
}

struct NutrientAverageCard: View {
    let nutrient: InsightNutrientType
    let value: Double

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: nutrient.iconName)
                .font(.title3)
                .foregroundColor(.primaryBlue)

            Text(formattedValue)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)

            Text(nutrient.displayName)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
    }

    private var formattedValue: String {
        switch nutrient {
        case .calories, .sodium:
            return "\(Int(value.rounded()))\(nutrient.unit)"
        default:
            return "\(String(format: "%.1f", value))\(nutrient.unit)"
        }
    }
}

// MARK: - Preview

#Preview {
    InsightsView()
        .environmentObject(AppState.shared)
}
