import Foundation

// MARK: - Shopping List Item

struct ShoppingListItem: Identifiable, Codable {
    let id: UUID
    let barcode: String
    let productName: String
    let brand: String?
    var healthScore: Double
    var isChecked: Bool
    let addedDate: Date
    var category: String?

    init(
        id: UUID = UUID(),
        barcode: String,
        productName: String,
        brand: String? = nil,
        healthScore: Double,
        isChecked: Bool = false,
        addedDate: Date = Date(),
        category: String? = nil
    ) {
        self.id = id
        self.barcode = barcode
        self.productName = productName
        self.brand = brand
        self.healthScore = healthScore
        self.isChecked = isChecked
        self.addedDate = addedDate
        self.category = category
    }

    // Create from ProductModel
    init(from product: ProductModel) {
        self.id = UUID()
        self.barcode = product.barcode
        self.productName = product.name
        self.brand = product.brand
        self.healthScore = product.healthScore
        self.isChecked = false
        self.addedDate = Date()
        self.category = product.category
    }
}

// MARK: - Shopping List Statistics

struct ShoppingListStats {
    let totalItems: Int
    let checkedItems: Int
    let averageScore: Double
    let scoreDistribution: ScoreDistribution

    struct ScoreDistribution {
        let excellent: Int  // 80-100
        let good: Int      // 60-79
        let fair: Int      // 40-59
        let poor: Int      // 0-39
    }

    var uncheckedItems: Int {
        totalItems - checkedItems
    }

    var completionPercentage: Double {
        guard totalItems > 0 else { return 0 }
        return Double(checkedItems) / Double(totalItems) * 100
    }
}
