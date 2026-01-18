import Foundation

/// Result of comparing two products side-by-side
/// Designed for grocery store aisle decision-making
struct ComparisonResult {
    let productA: ProductModel
    let productB: ProductModel
    let scoreA: HealthScore
    let scoreB: HealthScore
    
    /// The winning product (higher score)
    var winner: ProductModel {
        scoreA.overall >= scoreB.overall ? productA : productB
    }
    
    /// The losing product (lower score)
    var loser: ProductModel {
        scoreA.overall < scoreB.overall ? productA : productB
    }
    
    /// Score difference (absolute value)
    var scoreDelta: Double {
        abs(scoreA.overall - scoreB.overall)
    }

    /// Whether products are essentially equal (within 1 point)
    var areEssentiallyEqual: Bool {
        scoreDelta < 1.0
    }

    /// Whether the difference is significant (≥10 points)
    var isSignificantDifference: Bool {
        scoreDelta >= 10
    }
    
    /// Key differences between products (max 5)
    let keyDifferences: [ComparisonFactor]
    
    /// Simple recommendation message
    var recommendation: String {
        if areEssentiallyEqual {
            // Products are identical or nearly identical
            return "Both products are essentially the same"
        } else if scoreDelta < 5 {
            return "Both options are similar in quality"
        } else if scoreDelta < 15 {
            return "\(winner.name) is slightly better"
        } else {
            return "\(winner.name) is significantly better"
        }
    }
    
    /// Detailed recommendation with reasoning
    var detailedRecommendation: String {
        if keyDifferences.isEmpty {
            return recommendation
        }
        
        let topReason = keyDifferences.first!
        return "\(recommendation): \(topReason.description)"
    }
    
    init(productA: ProductModel, productB: ProductModel, scoreA: HealthScore, scoreB: HealthScore) {
        self.productA = productA
        self.productB = productB
        self.scoreA = scoreA
        self.scoreB = scoreB
        
        // Calculate key differences
        self.keyDifferences = ComparisonResult.calculateDifferences(
            productA: productA,
            productB: productB,
            scoreA: scoreA,
            scoreB: scoreB
        )
    }
    
    /// Calculate the most important differences between two products
    private static func calculateDifferences(
        productA: ProductModel,
        productB: ProductModel,
        scoreA: HealthScore,
        scoreB: HealthScore
    ) -> [ComparisonFactor] {
        var factors: [ComparisonFactor] = []
        
        let nutritionA = productA.nutrition
        let nutritionB = productB.nutrition
        
        // Compare sugar
        let sugarA = nutritionA.sugar
        let sugarB = nutritionB.sugar
        let sugarDiff = abs(sugarA - sugarB)
        if sugarDiff > 2.0 {
            let winner = sugarA < sugarB ? "A" : "B"
            factors.append(ComparisonFactor(
                category: .sugar,
                winner: winner,
                description: winner == "A" ? "Less sugar" : "More sugar",
                magnitude: sugarDiff
            ))
        }
        
        // Compare sodium
        let sodiumA = nutritionA.sodium
        let sodiumB = nutritionB.sodium
        let sodiumDiff = abs(sodiumA - sodiumB) * 1000 // Convert to mg
        if sodiumDiff > 50.0 {
            let winner = sodiumA < sodiumB ? "A" : "B"
            factors.append(ComparisonFactor(
                category: .sodium,
                winner: winner,
                description: winner == "A" ? "Less sodium" : "More sodium",
                magnitude: sodiumDiff
            ))
        }
        
        // Compare protein
        let proteinA = nutritionA.protein
        let proteinB = nutritionB.protein
        let proteinDiff = abs(proteinA - proteinB)
        if proteinDiff > 2.0 {
            let winner = proteinA > proteinB ? "A" : "B"
            factors.append(ComparisonFactor(
                category: .protein,
                winner: winner,
                description: winner == "A" ? "More protein" : "Less protein",
                magnitude: proteinDiff
            ))
        }
        
        // Compare fiber
        let fiberA = nutritionA.fiber
        let fiberB = nutritionB.fiber
        let fiberDiff = abs(fiberA - fiberB)
        if fiberDiff > 1.0 {
            let winner = fiberA > fiberB ? "A" : "B"
            factors.append(ComparisonFactor(
                category: .fiber,
                winner: winner,
                description: winner == "A" ? "More fiber" : "Less fiber",
                magnitude: fiberDiff
            ))
        }
        
        // Compare saturated fat
        let satFatA = nutritionA.saturatedFat
        let satFatB = nutritionB.saturatedFat
        let satFatDiff = abs(satFatA - satFatB)
        if satFatDiff > 1.0 {
            let winner = satFatA < satFatB ? "A" : "B"
            factors.append(ComparisonFactor(
                category: .saturatedFat,
                winner: winner,
                description: winner == "A" ? "Less saturated fat" : "More saturated fat",
                magnitude: satFatDiff
            ))
        }
        
        // Compare calories
        let calA = nutritionA.calories
        let calB = nutritionB.calories
        let calDiff = abs(calA - calB)
        if calDiff > 20.0 {
            let winner = calA < calB ? "A" : "B"
            factors.append(ComparisonFactor(
                category: .calories,
                winner: winner,
                description: winner == "A" ? "Lower calories" : "Higher calories",
                magnitude: calDiff
            ))
        }
        
        // Compare ingredient quality (based on guardrails)
        if let resultA = scoreA.scoringResult, let resultB = scoreB.scoringResult {
            if resultA.capsApplied.count < resultB.capsApplied.count {
                factors.append(ComparisonFactor(
                    category: .ingredientQuality,
                    winner: "A",
                    description: "Better ingredient quality",
                    magnitude: Double(resultB.capsApplied.count - resultA.capsApplied.count)
                ))
            } else if resultB.capsApplied.count < resultA.capsApplied.count {
                factors.append(ComparisonFactor(
                    category: .ingredientQuality,
                    winner: "B",
                    description: "Better ingredient quality",
                    magnitude: Double(resultA.capsApplied.count - resultB.capsApplied.count)
                ))
            }
        }
        
        // Sort by magnitude and return top 5
        return factors.sorted { $0.magnitude > $1.magnitude }.prefix(5).map { $0 }
    }
}

/// A single factor in a product comparison
struct ComparisonFactor {
    enum Category: String, Codable {
        case sugar
        case sodium
        case protein
        case fiber
        case saturatedFat
        case calories
        case ingredientQuality
    }
    
    let category: Category
    let winner: String // "A" or "B"
    let description: String
    let magnitude: Double // Size of difference
    
    var isPositive: Bool {
        switch category {
        case .protein, .fiber, .ingredientQuality:
            return winner == "A"
        case .sugar, .sodium, .saturatedFat, .calories:
            return winner == "A"
        }
    }
    
    var icon: String {
        isPositive ? "✓" : "✗"
    }
}

