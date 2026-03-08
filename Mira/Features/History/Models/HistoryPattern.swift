import Foundation

/// Represents a pattern detected in the user's scan history
struct HistoryPattern: Identifiable {
    let id = UUID()
    let type: PatternType
    let title: String
    let message: String
    let recommendation: String?
    let severity: Severity
    let iconName: String

    enum PatternType {
        case categoryDominance
        case scoreTrend
        case dietaryCompliance
        case nutritionGap
        case varietyIssue
    }

    enum Severity {
        case positive
        case neutral
        case attention

        var color: String {
            switch self {
            case .positive: return "green"
            case .neutral: return "blue"
            case .attention: return "orange"
            }
        }
    }
}

/// Service for analyzing scan history and detecting patterns
struct HistoryPatternAnalyzer {

    /// Analyze scan history and return detected patterns
    static func analyzePatterns(
        items: [HistoryItem],
        timeframe: TimeframeFilter = .week
    ) -> [HistoryPattern] {
        guard !items.isEmpty else { return [] }

        let filteredItems = filterByTimeframe(items, timeframe: timeframe)
        guard !filteredItems.isEmpty else { return [] }

        var patterns: [HistoryPattern] = []

        // Analyze category dominance
        if let categoryPattern = analyzeCategoryDominance(filteredItems) {
            patterns.append(categoryPattern)
        }

        // Analyze score trends
        if let trendPattern = analyzeScoreTrend(filteredItems) {
            patterns.append(trendPattern)
        }

        // Analyze variety
        if let varietyPattern = analyzeVariety(filteredItems) {
            patterns.append(varietyPattern)
        }

        return patterns
    }

    // MARK: - Category Dominance Analysis

    private static func analyzeCategoryDominance(_ items: [HistoryItem]) -> HistoryPattern? {
        // Filter out nil, empty, and "undefined" categories
        let categories = items.compactMap { $0.product.category }
            .filter { category in
                let trimmed = category.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                return !trimmed.isEmpty && trimmed != "undefined" && trimmed != "unknown"
            }
        guard !categories.isEmpty else { return nil }

        let categoryCounts = Dictionary(grouping: categories) { $0 }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }

        guard let topCategory = categoryCounts.first else { return nil }

        let percentage = Double(topCategory.value) / Double(categories.count) * 100

        // Only report if one category is >40% of scans
        guard percentage >= 40 else { return nil }

        let categoryName = formatCategoryName(topCategory.key)
        let severity: HistoryPattern.Severity = percentage >= 60 ? .attention : .neutral

        return HistoryPattern(
            type: .categoryDominance,
            title: "\(Int(percentage))% \(categoryName)",
            message: "You've been scanning mostly \(categoryName.lowercased()) products",
            recommendation: "Try adding more variety to balance your micronutrient intake",
            severity: severity,
            iconName: "chart.pie.fill"
        )
    }

    // MARK: - Score Trend Analysis

    private static func analyzeScoreTrend(_ items: [HistoryItem]) -> HistoryPattern? {
        guard items.count >= 5 else { return nil }

        let sortedItems = items.sorted { $0.scanDate < $1.scanDate }
        let firstHalf = sortedItems.prefix(sortedItems.count / 2)
        let secondHalf = sortedItems.suffix(sortedItems.count / 2)

        let firstAvg = firstHalf.reduce(0.0) { $0 + Double($1.currentScore) } / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0.0) { $0 + Double($1.currentScore) } / Double(secondHalf.count)

        let change = secondAvg - firstAvg

        // Only report if change is significant (>5 points)
        guard abs(change) >= 5 else { return nil }

        if change > 0 {
            return HistoryPattern(
                type: .scoreTrend,
                title: "Scores Improving",
                message: "Your average score improved by \(Int(change)) points",
                recommendation: "Keep up the great work choosing healthier options!",
                severity: .positive,
                iconName: "chart.line.uptrend.xyaxis"
            )
        } else {
            return HistoryPattern(
                type: .scoreTrend,
                title: "Scores Declining",
                message: "Your average score dropped by \(Int(abs(change))) points",
                recommendation: "Consider focusing on products with higher scores",
                severity: .attention,
                iconName: "chart.line.downtrend.xyaxis"
            )
        }
    }

    // MARK: - Variety Analysis

    private static func analyzeVariety(_ items: [HistoryItem]) -> HistoryPattern? {
        guard items.count >= 10 else { return nil }

        let uniqueProducts = Set(items.map { $0.product.barcode }).count
        let varietyRatio = Double(uniqueProducts) / Double(items.count)

        // Low variety: Same products scanned repeatedly
        if varietyRatio < 0.4 {
            return HistoryPattern(
                type: .varietyIssue,
                title: "Low Product Variety",
                message: "You're scanning many of the same products",
                recommendation: "Exploring new products can help ensure balanced nutrition",
                severity: .neutral,
                iconName: "arrow.triangle.2.circlepath"
            )
        }

        // High variety: Exploring lots of different products
        if varietyRatio > 0.7 {
            return HistoryPattern(
                type: .varietyIssue,
                title: "Great Product Variety",
                message: "You're exploring many different products",
                recommendation: nil,
                severity: .positive,
                iconName: "sparkles"
            )
        }

        return nil
    }

    // MARK: - Helpers

    private static func filterByTimeframe(_ items: [HistoryItem], timeframe: TimeframeFilter) -> [HistoryItem] {
        let calendar = Calendar.current
        let now = Date()

        let cutoffDate: Date
        switch timeframe {
        case .week:
            cutoffDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            cutoffDate = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        case .all:
            return items
        }

        return items.filter { $0.scanDate >= cutoffDate }
    }

    private static func formatCategoryName(_ category: String) -> String {
        // Convert slug to display name
        category
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

enum TimeframeFilter: String, CaseIterable {
    case week = "This Week"
    case month = "This Month"
    case all = "All Time"
}
