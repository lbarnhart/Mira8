import Foundation
import CoreData

struct HistoryItem: Identifiable {
    let id = UUID()
    let product: Product
    let scanDate: Date
    let originalHealthFocus: String
    var currentHealthFocus: String
    let scanObjectID: NSManagedObjectID?

    var currentScore: Int {
        Int(product.calculateScore(for: currentHealthFocus).overall.rounded())
    }

    var hasHealthFocusChanged: Bool {
        originalHealthFocus != currentHealthFocus
    }
}
