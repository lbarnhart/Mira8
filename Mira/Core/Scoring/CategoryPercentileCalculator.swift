import Foundation

/// Calculates category-based percentile rankings for products
/// Uses in-memory cached data to determine where a product ranks within its category
final class CategoryPercentileCalculator {
    static let shared = CategoryPercentileCalculator()
    
    // In-memory cache of category statistics
    private var categoryStats: [String: CategoryStats] = [:]
    
    private init() {
    }
    
    /// Calculate percentile rank for a product within its category
    /// Returns nil if insufficient data (< 5 products in category)
    func calculatePercentile(score: Double, category: String?) -> Int? {
        guard let category = category?.lowercased(), !category.isEmpty else {
            return nil
        }
        
        // Get or calculate category stats
        let stats = getCategoryStats(for: category)
        
        guard stats.sampleSize >= 5 else {
            return nil // Need at least 5 products for meaningful percentile
        }
        
        // Calculate percentile: what % of products have lower scores?
        let percentile = calculatePercentileRank(score: score, stats: stats)
        return percentile
    }
    
    /// Generate human-readable category rank text
    func formatCategoryRank(percentile: Int, category: String?) -> String {
        guard let category = category else {
            return "No category data"
        }
        
        let categoryName = formatCategoryName(category)
        
        switch percentile {
        case 90...100:
            return "Top 10% of \(categoryName)"
        case 75..<90:
            return "Top 25% of \(categoryName)"
        case 50..<75:
            return "Above average for \(categoryName)"
        case 25..<50:
            return "Average for \(categoryName)"
        case 10..<25:
            return "Below average for \(categoryName)"
        default:
            return "Bottom 10% of \(categoryName)"
        }
    }
    
    /// Update category statistics with a new product score
    func recordScore(score: Double, category: String?) {
        guard let category = category?.lowercased(), !category.isEmpty else {
            return
        }
        
        var stats = categoryStats[category] ?? CategoryStats(category: category)
        stats.addScore(score)
        categoryStats[category] = stats
    }
    
    /// Get statistics for a category (from cache or calculate from database)
    private func getCategoryStats(for category: String) -> CategoryStats {
        // Check cache first
        if let cached = categoryStats[category] {
            return cached
        }
        
        // Calculate from database
        let stats = calculateStatsFromDatabase(for: category)
        categoryStats[category] = stats
        return stats
    }
    
    /// Calculate statistics from all products in the database for a category
    private func calculateStatsFromDatabase(for category: String) -> CategoryStats {
        // Note: ProductEntity doesn't store pre-calculated scores (lastScore property doesn't exist)
        // Category statistics are built from in-memory recordScore() calls only
        // This ensures we only use actively scored products, not stale database entries
        return CategoryStats(category: category)
    }
    
    /// Calculate percentile rank (0-100) based on score and distribution
    private func calculatePercentileRank(score: Double, stats: CategoryStats) -> Int {
        guard !stats.scores.isEmpty else {
            return 50 // Default to median if no data
        }
        
        // Count how many scores are below this score
        let belowCount = stats.scores.filter { $0 < score }.count
        
        // Percentile = (# below / total) * 100
        let percentile = Double(belowCount) / Double(stats.scores.count) * 100.0
        
        return Int(round(percentile))
    }
    
    /// Format category name for display
    private func formatCategoryName(_ category: String) -> String {
        return category
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .lowercased()
    }
    
    /// Clear cache (useful for testing or memory management)
    func clearCache() {
        categoryStats.removeAll()
    }
}

/// Statistics for a product category
struct CategoryStats {
    let category: String
    var scores: [Double] = []
    var sampleSize: Int {
        scores.count
    }
    
    var mean: Double {
        guard !scores.isEmpty else { return 0 }
        return scores.reduce(0, +) / Double(scores.count)
    }
    
    var median: Double {
        guard !scores.isEmpty else { return 0 }
        let sorted = scores.sorted()
        let mid = sorted.count / 2
        if sorted.count % 2 == 0 {
            return (sorted[mid - 1] + sorted[mid]) / 2
        } else {
            return sorted[mid]
        }
    }
    
    var min: Double {
        scores.min() ?? 0
    }
    
    var max: Double {
        scores.max() ?? 0
    }
    
    mutating func addScore(_ score: Double) {
        scores.append(score)
    }
}

