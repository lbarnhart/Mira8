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
