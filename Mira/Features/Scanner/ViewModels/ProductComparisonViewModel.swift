import Foundation
import Combine

/// ViewModel for managing product comparison state
/// Supports grocery store use case: scan product A, scan product B, see comparison
@MainActor
class ProductComparisonViewModel: ObservableObject {
    @Published var comparisonMode: Bool = false
    @Published var firstProduct: (product: ProductModel, score: HealthScore)?
    @Published var secondProduct: (product: ProductModel, score: HealthScore)?
    @Published var comparisonResult: ComparisonResult?
    @Published var showComparisonSheet: Bool = false
    
    private let comparisonService = ProductComparisonService.shared
    
    init() {
    }
    
    /// Start comparison mode - saves the first product
    func startComparison(product: ProductModel, score: HealthScore) {
        firstProduct = (product, score)
        comparisonMode = true
        AppLog.info("Started comparison mode with \(product.name)", category: .general)
    }
    
    /// Add second product and generate comparison
    func addSecondProduct(product: ProductModel, score: HealthScore) {
        guard let first = firstProduct else {
            AppLog.warning("Attempted to add second product without first product", category: .general)
            return
        }
        
        secondProduct = (product, score)
        
        // Generate comparison
        let result = ComparisonResult(
            productA: first.product,
            productB: product,
            scoreA: first.score,
            scoreB: score
        )
        
        comparisonResult = result
        showComparisonSheet = true
        
        AppLog.info("Generated comparison: \(result.recommendation)", category: .general)
    }
    
    /// Use the current scanned product as second product for comparison
    func compareWithCurrent(product: ProductModel, score: HealthScore) {
        if firstProduct == nil {
            // No first product, make this the first
            startComparison(product: product, score: score)
        } else {
            // We have a first product, compare with it
            addSecondProduct(product: product, score: score)
        }
    }
    
    /// Clear comparison state
    func clearComparison() {
        firstProduct = nil
        secondProduct = nil
        comparisonResult = nil
        comparisonMode = false
        showComparisonSheet = false
    }
    
    /// Use current product as first product for next comparison
    func useAsFirstProduct(product: ProductModel, score: HealthScore) {
        firstProduct = (product, score)
        secondProduct = nil
        comparisonResult = nil
        comparisonMode = true
    }
    
    /// Quick comparison verdict without full UI
    func quickCompare(product: ProductModel, score: HealthScore) -> String? {
        guard let first = firstProduct else { return nil }
        return comparisonService.quickCompare(scoreA: first.score.overall, scoreB: score.overall)
    }
    
    /// Check if a product is better than the stored first product
    func isBetterThanFirst(score: Double) -> Bool? {
        guard let first = firstProduct else { return nil }
        return score > first.score.overall
    }
}

