import Foundation
import SwiftUI

@MainActor
final class ShoppingListViewModel: ObservableObject {
    @Published var items: [ShoppingListItem] = []
    @Published var showAddProductSheet = false
    @Published var sortOption: SortOption = .dateAdded
    @Published var filterOption: FilterOption = .all

    private let storageKey = Constants.UserDefaults.shoppingListItems

    enum SortOption: String, CaseIterable {
        case dateAdded = "Date Added"
        case score = "Score"
        case name = "Name"
        case category = "Category"
    }

    enum FilterOption: String, CaseIterable {
        case all = "All"
        case unchecked = "Active"
        case checked = "Completed"
    }

    init() {
        loadItems()
    }

    // MARK: - Computed Properties

    var filteredItems: [ShoppingListItem] {
        let filtered: [ShoppingListItem]

        switch filterOption {
        case .all:
            filtered = items
        case .unchecked:
            filtered = items.filter { !$0.isChecked }
        case .checked:
            filtered = items.filter { $0.isChecked }
        }

        return sortItems(filtered)
    }

    var stats: ShoppingListStats {
        let excellent = items.filter { $0.healthScore >= 80 }.count
        let good = items.filter { $0.healthScore >= 60 && $0.healthScore < 80 }.count
        let fair = items.filter { $0.healthScore >= 40 && $0.healthScore < 60 }.count
        let poor = items.filter { $0.healthScore < 40 }.count

        let totalScore = items.map(\.healthScore).reduce(0, +)
        let averageScore = items.isEmpty ? 0 : totalScore / Double(items.count)

        return ShoppingListStats(
            totalItems: items.count,
            checkedItems: items.filter(\.isChecked).count,
            averageScore: averageScore,
            scoreDistribution: .init(
                excellent: excellent,
                good: good,
                fair: fair,
                poor: poor
            )
        )
    }

    // MARK: - Item Management

    func addItem(_ product: ProductModel) {
        // Check if product already exists
        if items.contains(where: { $0.barcode == product.barcode }) {
            return
        }

        let newItem = ShoppingListItem(from: product)
        items.append(newItem)
        saveItems()
    }

    func toggleItemChecked(_ item: ShoppingListItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isChecked.toggle()
            saveItems()
        }
    }

    func removeItem(_ item: ShoppingListItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
    }

    func clearCheckedItems() {
        items.removeAll { $0.isChecked }
        saveItems()
    }

    func clearAllItems() {
        items.removeAll()
        saveItems()
    }

    func shareList() -> String {
        var text = "My Shopping List from Mira\n\n"

        if items.isEmpty {
            text += "No items yet!\n"
        } else {
            for item in filteredItems {
                let checkmark = item.isChecked ? "✓" : "○"
                text += "\(checkmark) \(item.productName)"

                if let brand = item.brand {
                    text += " (\(brand))"
                }

                text += " - Score: \(Int(item.healthScore.rounded()))\n"
            }

            text += "\nAverage Score: \(Int(stats.averageScore.rounded()))"
        }

        return text
    }

    // MARK: - Sorting

    private func sortItems(_ items: [ShoppingListItem]) -> [ShoppingListItem] {
        switch sortOption {
        case .dateAdded:
            return items.sorted { $0.addedDate > $1.addedDate }
        case .score:
            return items.sorted { $0.healthScore > $1.healthScore }
        case .name:
            return items.sorted { $0.productName < $1.productName }
        case .category:
            return items.sorted { ($0.category ?? "") < ($1.category ?? "") }
        }
    }

    // MARK: - Persistence

    private func saveItems() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(items)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            AppLog.error("Failed to save shopping list: \(error.localizedDescription)", category: .general)
        }
    }

    private func loadItems() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            items = []
            return
        }

        do {
            let decoder = JSONDecoder()
            items = try decoder.decode([ShoppingListItem].self, from: data)
        } catch {
            AppLog.error("Failed to load shopping list: \(error.localizedDescription)", category: .general)
            items = []
        }
    }
}
