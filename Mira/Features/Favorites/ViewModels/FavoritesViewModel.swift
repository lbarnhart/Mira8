import Foundation
import CoreData

@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published var favorites: [Product] = []
    @Published var errorMessage: String?

    private let coreDataManager: CoreDataManager
    private let persistenceController: PersistenceController

    init(coreDataManager: CoreDataManager = .shared, persistenceController: PersistenceController = .shared) {
        self.coreDataManager = coreDataManager
        self.persistenceController = persistenceController
        fetchFavorites()
    }

    func fetchFavorites() {
        let context = persistenceController.container.viewContext

        context.perform { [weak self] in
            guard let self else { return }
            let request: NSFetchRequest<ProductEntity> = ProductEntity.fetchRequest()
            request.predicate = NSPredicate(format: "isFavorite == YES")
            request.sortDescriptors = [NSSortDescriptor(key: "lastScanned", ascending: false)]

            do {
                let entities = try context.fetch(request)
                let products = entities.compactMap { $0.toProduct() }

                DispatchQueue.main.async { [weak self] in
                    self?.favorites = products
                    self?.errorMessage = nil
                }
            } catch {
                let errorMsg = error.localizedDescription
                DispatchQueue.main.async { [weak self] in
                    self?.errorMessage = errorMsg
                    AppLog.error("Failed to fetch favorites: \(errorMsg)", category: .persistence)
                }
            }
        }
    }

    func toggleFavorite(barcode: String) {
        let context = persistenceController.container.viewContext

        context.perform { [weak self] in
            guard let self else { return }
            let request: NSFetchRequest<ProductEntity> = ProductEntity.fetchRequest()
            request.predicate = NSPredicate(format: "barcode == %@", barcode)
            request.fetchLimit = 1

            do {
                guard let entity = try context.fetch(request).first else {
                    AppLog.warning("Product not found for barcode: \(barcode)", category: .persistence)
                    return
                }

                entity.isFavorite.toggle()

                do {
                    try context.save()
                    let name = entity.name ?? "Unknown"
                    AppLog.debug("Toggled favorite for \(name) to \(entity.isFavorite)", category: .persistence)

                    DispatchQueue.main.async { [weak self] in
                        self?.fetchFavorites()
                    }
                } catch {
                    let errorMsg = error.localizedDescription
                    DispatchQueue.main.async { [weak self] in
                        self?.errorMessage = "Failed to update favorite: \(errorMsg)"
                        AppLog.error("Failed to save favorite: \(errorMsg)", category: .persistence)
                    }
                }
            } catch {
                let errorMsg = error.localizedDescription
                DispatchQueue.main.async { [weak self] in
                    self?.errorMessage = "Failed to find product: \(errorMsg)"
                    AppLog.error("Failed to fetch product: \(errorMsg)", category: .persistence)
                }
            }
        }
    }

    func removeFavorite(_ product: Product) {
        toggleFavorite(barcode: product.barcode)
    }
}
