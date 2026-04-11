import Foundation
import SwiftUI

@MainActor
final class ComparisonModeViewModel: ObservableObject {
    @Published var comparisonProducts: [ProductModel] = []
    @Published var selectedProduct: ProductModel?
    @Published var showProductDetail = false

    // Maximum number of products that can be compared
    private let maxProducts = 3

    var bestProduct: ProductModel? {
        comparisonProducts.max(by: { $0.healthScore < $1.healthScore })
    }

    var scoreSpread: Int {
        guard comparisonProducts.count > 1 else { return 0 }
        let scores = comparisonProducts.map(\.healthScore)
        return Int((scores.max() ?? 0) - (scores.min() ?? 0))
    }

    var bestProductMetricWins: Int {
        guard let best = bestProduct, comparisonProducts.count > 1 else { return 0 }

        var wins = 0
        if best.healthScore == comparisonProducts.map(\.healthScore).max() { wins += 1 }
        if best.nutrition.protein == comparisonProducts.map({ $0.nutrition.protein }).max() { wins += 1 }
        if best.nutrition.fiber == comparisonProducts.map({ $0.nutrition.fiber }).max() { wins += 1 }
        if best.nutrition.sugar == comparisonProducts.map({ $0.nutrition.sugar }).min() { wins += 1 }
        if best.nutrition.sodium == comparisonProducts.map({ $0.nutrition.sodium }).min() { wins += 1 }
        if best.nutrition.calories == comparisonProducts.map({ $0.nutrition.calories }).min() { wins += 1 }

        return wins
    }

    var bestChoiceHighlights: [String] {
        guard let best = bestProduct,
              comparisonProducts.count > 1 else {
            return []
        }

        var highlights: [String] = []

        if best.healthScore == comparisonProducts.map(\.healthScore).max() {
            highlights.append("Highest overall score")
        }
        if best.nutrition.protein == comparisonProducts.map({ $0.nutrition.protein }).max(),
           best.nutrition.protein > 0 {
            highlights.append("Leads on protein")
        }
        if best.nutrition.fiber == comparisonProducts.map({ $0.nutrition.fiber }).max(),
           best.nutrition.fiber > 0 {
            highlights.append("Leads on fiber")
        }
        if best.nutrition.sugar == comparisonProducts.map({ $0.nutrition.sugar }).min() {
            highlights.append("Lowest sugar")
        }
        if best.nutrition.sodium == comparisonProducts.map({ $0.nutrition.sodium }).min() {
            highlights.append("Lowest sodium")
        }
        if best.nutrition.calories == comparisonProducts.map({ $0.nutrition.calories }).min() {
            highlights.append("Lowest calories")
        }

        return Array(highlights.prefix(3))
    }

    var bestChoiceReason: String {
        guard let best = bestProduct,
              comparisonProducts.count > 1 else {
            return ""
        }

        var reasons: [String] = []

        // Check if it has the highest score
        let highestScore = comparisonProducts.map(\.healthScore).max() ?? 0
        if best.healthScore == highestScore {
            reasons.append("highest score")
        }

        // Check protein
        let maxProtein = comparisonProducts.map { $0.nutrition.protein }.max() ?? 0
        if best.nutrition.protein == maxProtein && maxProtein > 0 {
            reasons.append("highest protein")
        }

        // Check fiber
        let maxFiber = comparisonProducts.map { $0.nutrition.fiber }.max() ?? 0
        if best.nutrition.fiber == maxFiber && maxFiber > 0 {
            reasons.append("highest fiber")
        }

        // Check sugar (lowest is best)
        let minSugar = comparisonProducts.map { $0.nutrition.sugar }.min() ?? 0
        if best.nutrition.sugar == minSugar {
            reasons.append("lowest sugar")
        }

        // Check sodium (lowest is best)
        let minSodium = comparisonProducts.map { $0.nutrition.sodium }.min() ?? 0
        if best.nutrition.sodium == minSodium {
            reasons.append("lowest sodium")
        }

        if reasons.isEmpty {
            return "Best overall nutrition profile"
        }

        return reasons.prefix(2).joined(separator: " and ")
    }

    func comparisonSummary(for healthFocus: String) -> String {
        guard let best = bestProduct,
              comparisonProducts.count > 1 else {
            return "Add another product to compare scores for \(HealthFocus(fromStored: healthFocus).displayName.lowercased())."
        }

        let focusName = HealthFocus(fromStored: healthFocus).displayName.lowercased()
        if scoreSpread < 5 {
            return "These options are close for \(focusName), so ingredient and preference tradeoffs matter more than score alone."
        }

        return "\(best.name) is ahead for \(focusName) with a \(scoreSpread)-point spread and leads in \(bestProductMetricWins) tracked metrics."
    }

    func addProduct(_ product: ProductModel) {
        guard comparisonProducts.count < maxProducts else { return }

        // Check if product already exists
        if !comparisonProducts.contains(where: { $0.barcode == product.barcode }) {
            comparisonProducts.append(product)
        }
    }

    func removeProduct(_ product: ProductModel) {
        comparisonProducts.removeAll { $0.barcode == product.barcode }
    }

    func clearAll() {
        comparisonProducts.removeAll()
        selectedProduct = nil
    }

    func canAddMore() -> Bool {
        comparisonProducts.count < maxProducts
    }
}
