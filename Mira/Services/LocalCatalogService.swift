import Foundation

struct LocalProduceCatalog: Codable {
    let products: [LocalProduceItem]
}

struct LocalProduceItem: Codable {
    let barcode: String
    let name: String
    let brand: String
    let category: String
    let nutritionalData: NutritionalData
    let ingredients: [String]
}

actor LocalCatalogService {
    static let shared = LocalCatalogService()

    private var catalog: [String: LocalProduceItem] = [:]
    private var isLoaded = false

    init() {
        Task {
            await loadCatalog()
        }
    }

    func loadCatalog() {
        guard !isLoaded else { return }

        guard let url = Bundle.main.url(forResource: "LocalProduceCatalog", withExtension: "json") else {
            AppLog.warning("LocalProduceCatalog.json not found in bundle", category: .scanner)
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(LocalProduceCatalog.self, from: data)

            var dict: [String: LocalProduceItem] = [:]
            for item in decoded.products {
                dict[item.barcode] = item
            }

            catalog = dict
            isLoaded = true
            AppLog.debug("Loaded \(catalog.count) items from local produce catalog", category: .scanner)
        } catch {
            AppLog.error("Failed to load LocalProduceCatalog: \(error.localizedDescription)", category: .scanner)
        }
    }

    func product(for barcode: String) -> LocalProduceItem? {
        return catalog[barcode]
    }

    func makeAPIProduct(from item: LocalProduceItem) -> APIProduct {
        // IMPORTANT: Local catalog nutritional data is per-100g
        // servingSize is set to 100 to indicate this is per-100g data
        return APIProduct(
            id: item.barcode,
            barcode: item.barcode,
            name: item.name,
            brand: item.brand,
            category: item.category,
            categorySlug: item.category.lowercased().replacingOccurrences(of: " ", with: "-"),
            ingredients: item.ingredients,
            rawIngredientsText: item.ingredients.joined(separator: ", "),
            nutritionalData: item.nutritionalData,
            servingSize: 100,
            servingSizeUnit: "g",
            servingSizeDisplay: nil,  // Local catalog doesn't have display strings
            imageURL: nil,
            thumbnailURL: nil,
            source: .manual
        )
    }
}
