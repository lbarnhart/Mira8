import Foundation
import CoreData

final class HistoryItem: Identifiable, ObservableObject {
    let id = UUID()
    let product: Product
    let scanDate: Date
    let originalHealthFocus: String
    let scanObjectID: NSManagedObjectID?

    private var _currentHealthFocus: String
    private var _cachedScore: Int?
    private var _cachedHealthScore: HealthScore?

    var currentHealthFocus: String {
        get { _currentHealthFocus }
        set {
            if _currentHealthFocus != newValue {
                _currentHealthFocus = newValue
                // Invalidate cache when health focus changes
                _cachedScore = nil
                _cachedHealthScore = nil
            }
        }
    }

    var currentScore: Int {
        if let cached = _cachedScore {
            return cached
        }
        let score = Int(product.calculateScore(for: _currentHealthFocus).overall.rounded())
        _cachedScore = score
        return score
    }

    var currentHealthScore: HealthScore {
        if let cached = _cachedHealthScore {
            return cached
        }
        let healthScore = product.calculateScore(for: _currentHealthFocus)
        _cachedHealthScore = healthScore
        _cachedScore = Int(healthScore.overall.rounded())
        return healthScore
    }

    var hasHealthFocusChanged: Bool {
        originalHealthFocus != _currentHealthFocus
    }

    init(product: Product, scanDate: Date, originalHealthFocus: String, currentHealthFocus: String, scanObjectID: NSManagedObjectID?) {
        self.product = product
        self.scanDate = scanDate
        self.originalHealthFocus = originalHealthFocus
        self._currentHealthFocus = currentHealthFocus
        self.scanObjectID = scanObjectID
    }
}
