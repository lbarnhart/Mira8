import Foundation

/// Debug helper to log category detection and scoring adjustments
struct CategoryDetectionDebug {
    
    static func logCategoryInfo(for product: ProductModel, score: HealthScore) {
        #if DEBUG
        AppLog.debug("\n🔍 === CATEGORY DETECTION DEBUG ===", category: .scoring)
        AppLog.debug("Product: \(product.name)", category: .scoring)
        AppLog.debug("Category: \(product.category ?? "nil")", category: .scoring)
        AppLog.debug("Category Slug: \(product.categorySlug ?? "nil")", category: .scoring)
        
        let detectedCategory = product.category ?? product.categorySlug
        if let category = detectedCategory {
            let profile = CategoryAdjustments.adjustedThresholds(for: category)
            AppLog.debug("Detected Profile: \(profile)", category: .scoring)
            AppLog.debug("Sodium Thresholds: \(profile.sodiumThresholds)", category: .scoring)
            AppLog.debug("Sugar Thresholds: \(profile.sugarThresholds)", category: .scoring)
            AppLog.debug("Guardrail Leniency: \(profile.guardrailLeniency)", category: .scoring)
        } else {
            AppLog.warning("⚠️ NO CATEGORY DETECTED - Using standard thresholds", category: .scoring)
        }
        
        AppLog.debug("\nScore Result:", category: .scoring)
        AppLog.debug("Final Score: \(Int(score.overall))", category: .scoring)
        AppLog.debug("Grade: \(score.grade.rawValue)", category: .scoring)
        AppLog.debug("Verdict: \(score.verdict.label)", category: .scoring)
        
        if let scoringResult = score.scoringResult {
            AppLog.debug("\nCaps Applied: \(scoringResult.capsApplied.count)", category: .scoring)
            for cap in scoringResult.capsApplied {
                AppLog.debug("  - \(cap.ruleID): Tier \(cap.tier.rawValue) - \(cap.reason)", category: .scoring)
            }
        }
        
        AppLog.debug("\nContributions:", category: .scoring)
        for contribution in score.contributions.prefix(5) {
            let sign = contribution.kind == .negative ? "-" : "+"
            AppLog.debug("  \(sign) \(contribution.label): \(contribution.rawPoints) raw pts, \(String(format: "%.1f", contribution.weightedPoints)) weighted", category: .scoring)
            if !contribution.modifiers.isEmpty {
                AppLog.debug("     Modifiers: \(contribution.modifiers.joined(separator: ", "))", category: .scoring)
            }
        }
        
        AppLog.debug("=== END DEBUG ===\n", category: .scoring)
        #endif
    }
}
