import Foundation
import CoreData

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var scanHistory: [ScanHistoryEntity] = []
    @Published var errorMessage: String?
    @Published var currentHealthFocus: String = "generalWellness"
    @Published var items: [HistoryItem] = []

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
                            let focus = mapHealthFocus(from: currentHealthFocus)
                            let model = makeProductModel(from: product)
                            let score = ScoringEngine.shared.calculateHealthScore(
                                for: model,
                                healthFocus: focus,
                                dietaryRestrictions: []
                            )
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
        items = items.map { old in
            var updated = old
            updated.currentHealthFocus = focus
            return updated
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

// Helpers to bridge CoreData product into scoring model for logging
    private func makeProductModel(from product: Product) -> ProductModel {
        let nutrition = ProductNutrition(
            calories: product.nutritionalData.calories,
            protein: product.nutritionalData.protein,
            carbohydrates: product.nutritionalData.carbohydrates,
            fat: product.nutritionalData.fat,
            fiber: product.nutritionalData.fiber,
            sugar: product.nutritionalData.sugar,
            sodium: product.nutritionalData.sodium,
            cholesterol: product.nutritionalData.cholesterol,
            servingSize: "100g"
        )

        let uuid = UUID(uuidString: product.id) ?? UUID()
        let ingredientsArray: [String] = product.ingredients?
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            ?? []

        return ProductModel(
            id: uuid,
            name: product.name,
            brand: product.brand,
            category: product.category,
            categorySlug: nil,
            barcode: product.barcode,
            nutrition: nutrition,
            ingredients: ingredientsArray,
            additives: [],
            processingLevel: .processed,
            dietaryFlags: [],
            imageURL: product.imageURL,
            thumbnailURL: product.thumbnailURL,
            healthScore: 0,
            createdAt: product.lastScanned ?? Date(),
            updatedAt: product.lastScanned ?? Date(),
            isCached: true,
            rawIngredientsText: product.ingredients
        )
    }

    private func mapHealthFocus(from string: String) -> HealthFocus {
        switch string {
        case "gutHealth", "gut_health": return .gutHealth
        case "weightLoss", "weight_loss": return .weightLoss
        case "proteinFocus", "protein_focus": return .proteinFocus
        case "heartHealth", "heart_health": return .heartHealth
        case "generalWellness", "general_wellness": return .generalWellness
        default: return .generalWellness
        }
    }

    // DEBUG-only print helper
    private func dprint(_ message: @autoclosure () -> String) {
        #if DEBUG
        print(message())
        #endif
    }
}
