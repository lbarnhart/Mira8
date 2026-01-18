import Foundation

/// Level 1 display: Instant decision-making (2-5 seconds)
/// Shows only the most critical information for in-store scanning
struct SimplifiedScoreDisplay: Codable {
    /// Rounded score 0-100 for easy comprehension
    let score: Int
    
    /// Simple verdict for quick decision
    let verdict: ScoreVerdict
    
    /// Visual emoji indicator
    let emoji: String
    
    /// Short, actionable message
    let message: String
    
    /// Top 2-3 key factors (positive or negative)
    let topFactors: [String]
    
    /// Category context (e.g., "Top 25% of yogurts")
    let categoryContext: String?
    
    /// Star rating (1-5) for visual representation
    let starRating: Int
    
    /// Whether this product is recommended
    var isRecommended: Bool {
        verdict == .excellent || verdict == .good
    }
    
    /// Whether user should avoid this product
    var shouldAvoid: Bool {
        verdict == .avoid
    }
    
    init(score: Double, verdict: ScoreVerdict, topFactors: [String], categoryContext: String? = nil) {
        self.score = Int(round(score))
        self.verdict = verdict
        self.emoji = verdict.emoji
        self.message = verdict.message
        self.topFactors = Array(topFactors.prefix(3)) // Max 3 factors
        self.categoryContext = categoryContext
        
        // Calculate star rating (1-5)
        switch score {
        case 85...100:
            self.starRating = 5
        case 70..<85:
            self.starRating = 4
        case 55..<70:
            self.starRating = 3
        case 40..<55:
            self.starRating = 2
        default:
            self.starRating = 1
        }
    }
}










