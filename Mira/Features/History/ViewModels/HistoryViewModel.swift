import Foundation
import CoreData

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var scanHistory: [ScanHistoryEntity] = []
    @Published var errorMessage: String?
    @Published var currentHealthFocus: String = "generalWellness"
    @Published var items: [HistoryItem] = []
    @Published var patterns: [HistoryPattern] = []
    @Published var selectedTimeframe: TimeframeFilter = .week

    private let coreDataManager: CoreDataManager

    var averageRecentScore: Double? {
        guard !items.isEmpty else { return nil }
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentItems = items.filter { $0.scanDate >= thirtyDaysAgo }
        guard !recentItems.isEmpty else { return nil }
        let sum = recentItems.reduce(0.0) { $0 + Double($1.currentScore) }
        return sum / Double(recentItems.count)
    }

    init(coreDataManager: CoreDataManager = .shared) {
        self.coreDataManager = coreDataManager
        fetchHistory()
    }

    func fetchHistory() {
        dprint("📊 === HISTORY VIEW MODEL ===")
        dprint("📊 Current Health Focus: \(currentHealthFocus)")
        do {
            let scans = try coreDataManager.fetchScanHistory(limit: 50)
            dprint("📊 Found \(scans.count) scans")

            // Keep existing binding for UI while providing visibility in logs
            var collected: [ScanHistoryEntity] = []
            for scan in scans {
                dprint("📊 Processing scan - Barcode: \(scan.productBarcode ?? "nil")")

                // Fetch product from CoreData (for logging/verification)
                if let barcode = scan.productBarcode, !barcode.isEmpty {
                    do {
                        let product = try coreDataManager.fetchProduct(byBarcode: barcode)
                        if let product {
                            dprint("📊 History - Product: \(product.name)")
                            dprint("📊 History - Barcode: \(product.barcode)")
                            let nd = product.nutritionalData
                            dprint("📊 History - Protein: \(nd.protein)g, Fiber: \(nd.fiber)g, Sugar: \(nd.sugar)g")

                            // Recompute score for verification in logs
                            let focus = HealthFocus(fromStored: currentHealthFocus)
                            let score = product.calculateScore(for: focus.rawValue)
                            dprint("📊 History - Health Focus Used: \(focus.rawValue)")
                            dprint("📊 History - Calculated Score: \(Int(score.overall.rounded()))")
                            dprint("📊 History - Score Breakdown:")
                            dprint("     macronutrients: \(Int(score.components.macronutrientBalance.score))")
                            dprint("     micronutrients: \(Int(score.components.micronutrientDensity.score))")
                            dprint("     processing: \(Int(score.components.processingLevel.score))")
                            dprint("     ingredients: \(Int(score.components.ingredientQuality.score))")
                            dprint("     additives: \(Int(score.components.additives.score))")
                            dprint("📊 ---")
                        } else {
                            dprint("⚠️ Product not found in CoreData for barcode: \(barcode)")
                        }
                    } catch {
                        dprint("⚠️ Error fetching product for barcode \(barcode): \(error.localizedDescription)")
                    }
                } else {
                    dprint("⚠️ Product not found in CoreData for barcode: nil")
                }

                collected.append(scan)
            }

            dprint("📊 Final history items: \(collected.count)")
            scanHistory = collected
            rebuildItems()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        dprint("📊 === END HISTORY VIEW MODEL ===\n")
    }

    func deleteScan(_ scan: ScanHistoryEntity) {
        do {
            try coreDataManager.deleteScanHistory(scan)
            fetchHistory()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteItem(_ item: HistoryItem) {
        if let scan = scanHistory.first(where: { $0.objectID == item.scanObjectID }) {
            deleteScan(scan)
        }
    }

    func updateCurrentHealthFocus(_ focus: String) {
        currentHealthFocus = focus
        // Update each item's health focus - caching handles score invalidation
        for item in items {
            item.currentHealthFocus = focus
        }
    }

    private func rebuildItems() {
        var built: [HistoryItem] = []
        for scan in scanHistory {
            let barcode = scan.productBarcode ?? ""
            dprint("📊 Processing scan - Barcode: \(barcode)")
            if let product = try? coreDataManager.fetchProduct(byBarcode: barcode) {
                let nd = product.nutritionalData
                dprint("📊 Product data - Protein: \(nd.protein)g, Fiber: \(nd.fiber)g")
                let item = HistoryItem(
                    product: product,
                    scanDate: scan.scanDate ?? Date(),
                    originalHealthFocus: scan.healthFocusUsed ?? "",
                    currentHealthFocus: currentHealthFocus,
                    scanObjectID: scan.objectID
                )
                dprint("📊 Calculated dynamic score: \(item.currentScore) for focus: \(currentHealthFocus)")
                built.append(item)
            } else {
                dprint("⚠️ Product not found in CoreData for barcode: \(barcode)")
            }
        }
        dprint("📊 Final history items: \(built.count)")
        self.items = built
        analyzePatterns()
    }

    func analyzePatterns() {
        patterns = HistoryPatternAnalyzer.analyzePatterns(
            items: items,
            timeframe: selectedTimeframe
        )
    }

    func updateTimeframe(_ timeframe: TimeframeFilter) {
        selectedTimeframe = timeframe
        analyzePatterns()
    }

    // MARK: - Debugging
    func debugLogAllHistory() {
        dprint("=== HISTORY DEBUG ===")
        for item in items {
            dprint("Product: \(item.product.name)")
            dprint("  Barcode: \(item.product.barcode)")
            dprint("  Protein: \(item.product.nutritionalData.protein)g")
            dprint("  Score (current): \(item.currentScore)")
            if item.hasHealthFocusChanged {
                dprint("  Note: Rescored from \(item.originalHealthFocus) to \(item.currentHealthFocus)")
            }
            dprint("---")
        }
        dprint("=== END DEBUG ===")
}

    // DEBUG-only logging helper using AppLog
    private func dprint(_ message: @autoclosure () -> String) {
        #if DEBUG
        AppLog.debug(message(), category: .scoring)
        #endif
    }
}
