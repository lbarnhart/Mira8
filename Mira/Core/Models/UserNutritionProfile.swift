import Foundation

/// User's nutrition profile built from scan history analysis.
/// Used for generating personalized recommendations and identifying gaps.
struct UserNutritionProfile: Equatable {
    let period: AnalysisPeriod
    let healthFocus: HealthFocus
    let scanCount: Int
    let averages: NutritionAverages
    let gaps: [NutritionGap]
    let patterns: [ConsumptionPattern]
    let generatedAt: Date

    /// Whether there's enough data for meaningful analysis
    var hasEnoughData: Bool {
        scanCount >= 5
    }

    /// Overall profile health percentage (0-100)
    var overallHealth: Double {
        guard !gaps.isEmpty else { return 100 }
        let totalGapPercentage = gaps.reduce(0.0) { $0 + max(0, $1.gapPercentage) }
        let averageGap = totalGapPercentage / Double(gaps.count)
        return max(0, min(100, 100 - averageGap))
    }
}

/// Time period for analysis
enum AnalysisPeriod: String, CaseIterable {
    case week = "7_days"
    case twoWeeks = "14_days"
    case month = "30_days"

    var days: Int {
        switch self {
        case .week: return 7
        case .twoWeeks: return 14
        case .month: return 30
        }
    }

    var displayName: String {
        switch self {
        case .week: return "Past Week"
        case .twoWeeks: return "Past 2 Weeks"
        case .month: return "Past Month"
        }
    }
}

/// Average nutritional values from scanned products
struct NutritionAverages: Equatable {
    let calories: Double
    let protein: Double
    let carbohydrates: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let saturatedFat: Double

    static let zero = NutritionAverages(
        calories: 0, protein: 0, carbohydrates: 0, fat: 0,
        fiber: 0, sugar: 0, sodium: 0, saturatedFat: 0
    )
}

/// Identified gap between current intake and recommended targets
struct NutritionGap: Identifiable, Equatable {
    let id = UUID()
    let nutrient: InsightNutrientType
    let currentAverage: Double
    let recommendedTarget: Double
    let gapPercentage: Double
    let severity: GapSeverity
    var aiRecommendation: String?

    var description: String {
        let direction = currentAverage < recommendedTarget ? "below" : "above"
        return "\(nutrient.displayName) is \(Int(abs(gapPercentage)))% \(direction) target"
    }

    var isDeficiency: Bool {
        currentAverage < recommendedTarget
    }
}

/// Type of nutrient being tracked for insights
/// Note: Different from NutrientType in NutrientBar.swift - includes additional fields
enum InsightNutrientType: String, CaseIterable {
    case protein
    case fiber
    case sugar
    case sodium
    case calories
    case saturatedFat = "saturated_fat"
    case carbohydrates

    var displayName: String {
        switch self {
        case .protein: return "Protein"
        case .fiber: return "Fiber"
        case .sugar: return "Sugar"
        case .sodium: return "Sodium"
        case .calories: return "Calories"
        case .saturatedFat: return "Saturated Fat"
        case .carbohydrates: return "Carbs"
        }
    }

    var unit: String {
        switch self {
        case .calories: return "kcal"
        case .sodium: return "mg"
        default: return "g"
        }
    }

    var iconName: String {
        switch self {
        case .protein: return "figure.strengthtraining.traditional"
        case .fiber: return "leaf.fill"
        case .sugar: return "cube.fill"
        case .sodium: return "drop.fill"
        case .calories: return "flame.fill"
        case .saturatedFat: return "drop.triangle.fill"
        case .carbohydrates: return "chart.bar.fill"
        }
    }
}

/// Severity of a nutrition gap
enum GapSeverity: String, CaseIterable, Comparable {
    case mild
    case moderate
    case significant

    var color: String {
        switch self {
        case .mild: return "yellow"
        case .moderate: return "orange"
        case .significant: return "red"
        }
    }

    static func from(gapPercentage: Double) -> GapSeverity {
        let absGap = abs(gapPercentage)
        if absGap < 20 { return .mild }
        if absGap < 40 { return .moderate }
        return .significant
    }

    static func < (lhs: GapSeverity, rhs: GapSeverity) -> Bool {
        let order: [GapSeverity] = [.mild, .moderate, .significant]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}

/// Pattern detected in user's consumption
struct ConsumptionPattern: Identifiable, Equatable {
    let id = UUID()
    let type: PatternType
    let description: String
    let confidence: Double
    var aiInsight: String?
}

/// Types of consumption patterns
enum PatternType: String, CaseIterable {
    case highCategory = "high_category"
    case lowCategory = "low_category"
    case consistent
    case improving
    case declining
    case variable

    var displayName: String {
        switch self {
        case .highCategory: return "High Consumption"
        case .lowCategory: return "Low Consumption"
        case .consistent: return "Consistent"
        case .improving: return "Improving"
        case .declining: return "Declining"
        case .variable: return "Variable"
        }
    }

    var iconName: String {
        switch self {
        case .highCategory: return "arrow.up.circle.fill"
        case .lowCategory: return "arrow.down.circle.fill"
        case .consistent: return "equal.circle.fill"
        case .improving: return "chart.line.uptrend.xyaxis"
        case .declining: return "chart.line.downtrend.xyaxis"
        case .variable: return "waveform.path.ecg"
        }
    }
}

// MARK: - Health Focus Targets

/// Recommended nutritional targets based on health focus
struct HealthFocusTargets {
    let healthFocus: HealthFocus
    let proteinMin: Double?
    let proteinMax: Double?
    let fiberMin: Double?
    let sugarMax: Double?
    let sodiumMax: Double?
    let caloriesMax: Double?
    let saturatedFatMax: Double?

    /// Get targets for a specific health focus (per-product averages)
    static func targets(for focus: HealthFocus) -> HealthFocusTargets {
        switch focus {
        case .proteinFocus:
            return HealthFocusTargets(
                healthFocus: focus,
                proteinMin: 15,      // Minimum 15g protein per product
                proteinMax: nil,
                fiberMin: 3,         // Decent fiber
                sugarMax: 10,        // Moderate sugar
                sodiumMax: 600,
                caloriesMax: nil,
                saturatedFatMax: nil
            )

        case .gutHealth:
            return HealthFocusTargets(
                healthFocus: focus,
                proteinMin: nil,
                proteinMax: nil,
                fiberMin: 5,         // High fiber focus
                sugarMax: 8,         // Low sugar for gut health
                sodiumMax: 500,
                caloriesMax: nil,
                saturatedFatMax: nil
            )

        case .weightLoss:
            return HealthFocusTargets(
                healthFocus: focus,
                proteinMin: 8,       // Moderate protein for satiety
                proteinMax: nil,
                fiberMin: 4,         // Good fiber for satiety
                sugarMax: 6,         // Low sugar
                sodiumMax: 500,
                caloriesMax: 250,    // Calorie-conscious
                saturatedFatMax: 3
            )

        case .heartHealth:
            return HealthFocusTargets(
                healthFocus: focus,
                proteinMin: nil,
                proteinMax: nil,
                fiberMin: 5,         // Heart-healthy fiber
                sugarMax: 8,
                sodiumMax: 400,      // Low sodium priority
                caloriesMax: nil,
                saturatedFatMax: 2   // Very low sat fat
            )

        case .generalWellness:
            return HealthFocusTargets(
                healthFocus: focus,
                proteinMin: 5,
                proteinMax: nil,
                fiberMin: 3,
                sugarMax: 12,
                sodiumMax: 600,
                caloriesMax: nil,
                saturatedFatMax: 5
            )
        }
    }

    /// Calculate gaps for given averages
    func calculateGaps(from averages: NutritionAverages) -> [NutritionGap] {
        var gaps: [NutritionGap] = []

        // Protein (deficiency check)
        if let minProtein = proteinMin, averages.protein < minProtein {
            let gapPct = ((minProtein - averages.protein) / minProtein) * 100
            gaps.append(NutritionGap(
                nutrient: .protein,
                currentAverage: averages.protein,
                recommendedTarget: minProtein,
                gapPercentage: gapPct,
                severity: .from(gapPercentage: gapPct)
            ))
        }

        // Fiber (deficiency check)
        if let minFiber = fiberMin, averages.fiber < minFiber {
            let gapPct = ((minFiber - averages.fiber) / minFiber) * 100
            gaps.append(NutritionGap(
                nutrient: .fiber,
                currentAverage: averages.fiber,
                recommendedTarget: minFiber,
                gapPercentage: gapPct,
                severity: .from(gapPercentage: gapPct)
            ))
        }

        // Sugar (excess check)
        if let maxSugar = sugarMax, averages.sugar > maxSugar {
            let gapPct = ((averages.sugar - maxSugar) / maxSugar) * 100
            gaps.append(NutritionGap(
                nutrient: .sugar,
                currentAverage: averages.sugar,
                recommendedTarget: maxSugar,
                gapPercentage: -gapPct, // Negative indicates excess
                severity: .from(gapPercentage: gapPct)
            ))
        }

        // Sodium (excess check)
        if let maxSodium = sodiumMax, averages.sodium > maxSodium {
            let gapPct = ((averages.sodium - maxSodium) / maxSodium) * 100
            gaps.append(NutritionGap(
                nutrient: .sodium,
                currentAverage: averages.sodium,
                recommendedTarget: maxSodium,
                gapPercentage: -gapPct,
                severity: .from(gapPercentage: gapPct)
            ))
        }

        // Calories (excess check)
        if let maxCalories = caloriesMax, averages.calories > maxCalories {
            let gapPct = ((averages.calories - maxCalories) / maxCalories) * 100
            gaps.append(NutritionGap(
                nutrient: .calories,
                currentAverage: averages.calories,
                recommendedTarget: maxCalories,
                gapPercentage: -gapPct,
                severity: .from(gapPercentage: gapPct)
            ))
        }

        // Saturated Fat (excess check)
        if let maxSatFat = saturatedFatMax, averages.saturatedFat > maxSatFat {
            let gapPct = ((averages.saturatedFat - maxSatFat) / maxSatFat) * 100
            gaps.append(NutritionGap(
                nutrient: .saturatedFat,
                currentAverage: averages.saturatedFat,
                recommendedTarget: maxSatFat,
                gapPercentage: -gapPct,
                severity: .from(gapPercentage: gapPct)
            ))
        }

        // Sort by severity (most significant first)
        return gaps.sorted { $0.severity > $1.severity }
    }
}

// MARK: - Weekly Insight

/// Structured insight for the user's weekly summary
struct WeeklyInsight: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let summary: String
    let highlights: [InsightHighlight]
    let topGaps: [NutritionGap]
    let recommendedActions: [RecommendedAction]
    let generatedAt: Date
}

struct InsightHighlight: Identifiable, Equatable {
    let id = UUID()
    let type: HighlightType
    let message: String
    let value: String?
}

enum HighlightType: String {
    case positive
    case neutral
    case needsAttention = "needs_attention"

    var iconName: String {
        switch self {
        case .positive: return "checkmark.circle.fill"
        case .neutral: return "info.circle.fill"
        case .needsAttention: return "exclamationmark.triangle.fill"
        }
    }

    var color: String {
        switch self {
        case .positive: return "green"
        case .neutral: return "blue"
        case .needsAttention: return "orange"
        }
    }
}

struct RecommendedAction: Identifiable, Equatable {
    let id = UUID()
    let priority: Int
    let action: String
    let rationale: String
    let relatedNutrient: InsightNutrientType?
}
