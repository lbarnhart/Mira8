import Foundation
import Combine
import os

/// ViewModel for the Insights feature.
/// Manages user nutrition profile, weekly insights, and recommendations.
@MainActor
final class InsightsViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var profile: UserNutritionProfile?
    @Published private(set) var weeklyInsight: WeeklyInsight?
    @Published private(set) var isLoading = false
    @Published private(set) var isRefreshing = false
    @Published private(set) var errorMessage: String?
    @Published var selectedPeriod: AnalysisPeriod = .week

    // MARK: - Dependencies

    private let recommendationService: PersonalizedRecommendationService
    private let profilerService: NutritionProfilerService
    private let logger = Logger(subsystem: "com.mira8.app", category: "InsightsViewModel")

    // Configuration
    private var healthFocus: HealthFocus = .generalWellness
    private var dietaryRestrictions: Set<String> = []

    // MARK: - Initialization

    init(
        recommendationService: PersonalizedRecommendationService? = nil,
        profilerService: NutritionProfilerService? = nil
    ) {
        self.profilerService = profilerService ?? NutritionProfilerService()
        self.recommendationService = recommendationService ?? PersonalizedRecommendationService(
            profilerService: self.profilerService
        )
    }

    // MARK: - Configuration

    func configure(healthFocus: String, restrictions: Set<String>) {
        self.healthFocus = HealthFocus(fromStored: healthFocus)
        self.dietaryRestrictions = restrictions
    }


    // MARK: - Data Loading

    func loadInsights() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            // Load profile and insight in parallel
            async let profileTask = loadProfile()
            async let insightTask = loadWeeklyInsight()

            let (loadedProfile, loadedInsight) = try await (profileTask, insightTask)

            self.profile = loadedProfile
            self.weeklyInsight = loadedInsight

            logger.info("Loaded insights successfully")
        } catch {
            logger.error("Failed to load insights: \(error.localizedDescription)")
            errorMessage = "Unable to load insights. Please try again."
        }

        isLoading = false
    }

    func refresh() async {
        guard !isRefreshing else { return }

        isRefreshing = true

        // Invalidate caches
        await recommendationService.invalidateCache()

        // Reload data
        await loadInsights()

        isRefreshing = false
    }

    // MARK: - Private Loading Methods

    private func loadProfile() async throws -> UserNutritionProfile {
        try await profilerService.buildProfile(
            period: selectedPeriod,
            healthFocus: healthFocus
        )
    }

    private func loadWeeklyInsight() async throws -> WeeklyInsight {
        try await recommendationService.generateWeeklyInsight(
            healthFocus: healthFocus,
            dietaryRestrictions: dietaryRestrictions
        )
    }

    // MARK: - Computed Properties

    var hasEnoughData: Bool {
        profile?.hasEnoughData ?? false
    }

    var overallHealthScore: Int {
        Int(profile?.overallHealth.rounded() ?? 0)
    }

    var scanCount: Int {
        profile?.scanCount ?? 0
    }

    var topGaps: [NutritionGap] {
        weeklyInsight?.topGaps ?? []
    }

    var recommendations: [RecommendedAction] {
        weeklyInsight?.recommendedActions ?? []
    }

    var highlights: [InsightHighlight] {
        weeklyInsight?.highlights ?? []
    }

    var patterns: [ConsumptionPattern] {
        profile?.patterns ?? []
    }

    var averages: NutritionAverages? {
        profile?.averages
    }

    var nextPriorityAction: RecommendedAction? {
        recommendations.sorted { $0.priority < $1.priority }.first
    }

    var primaryGap: NutritionGap? {
        topGaps.first
    }

    // MARK: - Period Selection

    func selectPeriod(_ period: AnalysisPeriod) async {
        guard period != selectedPeriod else { return }

        selectedPeriod = period
        await loadInsights()
    }
}

// MARK: - Preview Helper

extension InsightsViewModel {
    static var preview: InsightsViewModel {
        let vm = InsightsViewModel()

        // Set up preview data
        vm.profile = UserNutritionProfile(
            period: .week,
            healthFocus: .proteinFocus,
            scanCount: 12,
            averages: NutritionAverages(
                calories: 185,
                protein: 8.5,
                carbohydrates: 24,
                fat: 6.2,
                fiber: 2.8,
                sugar: 9.5,
                sodium: 420,
                saturatedFat: 2.1
            ),
            gaps: [
                NutritionGap(
                    nutrient: .protein,
                    currentAverage: 8.5,
                    recommendedTarget: 15,
                    gapPercentage: 43,
                    severity: .moderate
                ),
                NutritionGap(
                    nutrient: .fiber,
                    currentAverage: 2.8,
                    recommendedTarget: 5,
                    gapPercentage: 44,
                    severity: .moderate
                )
            ],
            patterns: [
                ConsumptionPattern(
                    type: .highCategory,
                    description: "Snacks make up 45% of your scans",
                    confidence: 0.85
                )
            ],
            generatedAt: Date()
        )

        vm.weeklyInsight = WeeklyInsight(
            title: "Building Better Habits",
            summary: "You've been scanning consistently this week. Your protein intake is a bit low for your Protein Focus goals, but you're making progress!",
            highlights: [
                InsightHighlight(type: .positive, message: "Consistent scanning habit", value: "12 products"),
                InsightHighlight(type: .needsAttention, message: "Protein intake below target", value: "8.5g avg")
            ],
            topGaps: [
                NutritionGap(
                    nutrient: .protein,
                    currentAverage: 8.5,
                    recommendedTarget: 15,
                    gapPercentage: 43,
                    severity: .moderate
                )
            ],
            recommendedActions: [
                RecommendedAction(
                    priority: 1,
                    action: "Look for snacks with 10g+ protein",
                    rationale: "Higher protein snacks will help you meet your goals",
                    relatedNutrient: .protein
                )
            ],
            generatedAt: Date()
        )

        return vm
    }
}
