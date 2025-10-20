import CoreData
import Foundation
import os

struct Product: Identifiable, Codable, Sendable {
    let id: String
    let barcode: String
    let name: String
    let brand: String?
    let category: String?
    let nutritionalData: NutritionalData
    let ingredients: String?
    let imageURL: String?
    let thumbnailURL: String?
    var lastScanned: Date?
}

enum CoreDataManagerError: LocalizedError {
    case missingNutritionalData
    case encodingFailure
    case decodingFailure
    case invalidProduct

    var errorDescription: String? {
        switch self {
        case .missingNutritionalData:
            return "Missing nutritional data for stored product."
        case .encodingFailure:
            return "Failed to encode nutritional data."
        case .decodingFailure:
            return "Failed to decode nutritional data."
        case .invalidProduct:
            return "Stored product is missing required fields."
        }
    }
}

final class CoreDataManager {
    static let shared = CoreDataManager()

    private let persistenceController: PersistenceController
    private let logger = Logger(subsystem: "com.mira8.app", category: "CoreDataManager")
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    // MARK: - Products

    func saveProduct(_ product: Product) throws {
        let context = persistenceController.newBackgroundContext()
        var capturedError: Error?

        context.performAndWait {
            do {
                AppLog.debug("Saving product: \(product.name), Barcode: \(product.barcode)", category: .persistence)
                AppLog.debug("Nutritional data - Protein: \(product.nutritionalData.protein), Fiber: \(product.nutritionalData.fiber)", category: .persistence)

                // Validate before saving
                guard self.validateProduct(product) else {
                    capturedError = CoreDataManagerError.invalidProduct
                    return
                }

                // Use extension to map Product -> ProductEntity (upsert)
                _ = try ProductEntity.fromProduct(product, in: context)

                try context.save()
            } catch {
                context.rollback()
                capturedError = error
            }
        }

        if let error = capturedError {
            logger.error("Failed to save product \(product.barcode, privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    func fetchProduct(byBarcode barcode: String) throws -> Product? {
        AppLog.debug("Fetching product by barcode: \(barcode)", category: .persistence)
        let context = persistenceController.container.viewContext

        var fetchedEntity: ProductEntity?
        var capturedError: Error?

        context.performAndWait {
            let request: NSFetchRequest<ProductEntity> = ProductEntity.fetchRequest()
            request.predicate = NSPredicate(format: "barcode == %@", barcode)
            request.fetchLimit = 1

            do {
                fetchedEntity = try context.fetch(request).first
            } catch {
                capturedError = error
            }
        }

        if let error = capturedError {
            throw error
        }

        guard let entity = fetchedEntity else {
            AppLog.debug("Product not found for barcode: \(barcode)", category: .persistence)
            return nil
        }

        // Use extension to convert entity -> Product
        guard let product = entity.toProduct() else {
            AppLog.error("Failed to convert ProductEntity to Product for barcode: \(barcode)", category: .persistence)
            return nil
        }
        AppLog.debug("Found product: \(product.name)", category: .persistence)
        return product
    }

    // MARK: - Validation
    func validateProduct(_ product: Product) -> Bool {
        // Only validate required fields - allow products with 0 calories
        let isValid = !product.barcode.isEmpty && !product.name.isEmpty
        if !isValid {
            AppLog.warning("Invalid product data encountered during validation - missing barcode or name", category: .persistence)
        }
        return isValid
    }

    // MARK: - Scan History

    func saveScanHistory(product: Product, healthFocus: String) throws {
        let context = persistenceController.newBackgroundContext()
        var capturedError: Error?

        context.performAndWait {
            do {
                let scanDate = product.lastScanned ?? Date()

                let history = ScanHistoryEntity(context: context)
                history.id = UUID()
                history.scanDate = scanDate
                history.productBarcode = product.barcode
                history.healthFocusUsed = healthFocus

                if let existingProduct = try self.productEntity(for: product.barcode, in: context) {
                    existingProduct.lastScanned = scanDate
                    if let imageURL = product.imageURL {
                        existingProduct.imageURL = imageURL
                    }
                    if let thumbnailURL = product.thumbnailURL ?? product.imageURL {
                        existingProduct.thumbnailURL = thumbnailURL
                    }
                    history.product = existingProduct
                } else {
                    let productEntity = ProductEntity(context: context)
                    productEntity.id = product.id
                    productEntity.barcode = product.barcode
                    productEntity.name = product.name
                    productEntity.brand = product.brand
                    productEntity.category = product.category
                    productEntity.ingredients = product.ingredients
                    productEntity.imageURL = product.imageURL
                    productEntity.thumbnailURL = product.thumbnailURL ?? product.imageURL
                    productEntity.lastScanned = scanDate
                    productEntity.nutritionalData = try self.encodeNutritionalData(product.nutritionalData)
                    history.product = productEntity
                }

                try context.save()
            } catch {
                context.rollback()
                capturedError = error
            }
        }

        if let error = capturedError {
            logger.error("Failed to save scan history for \(product.barcode, privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    func fetchScanHistory(limit: Int) throws -> [ScanHistoryEntity] {
        let context = persistenceController.container.viewContext

        var results: [ScanHistoryEntity] = []
        var capturedError: Error?

        context.performAndWait {
            let request: NSFetchRequest<ScanHistoryEntity> = ScanHistoryEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "scanDate", ascending: false)]
            request.relationshipKeyPathsForPrefetching = ["product"]

            if limit > 0 {
                request.fetchLimit = limit
            }

            do {
                results = try context.fetch(request)
            } catch {
                capturedError = error
            }
        }

        if let error = capturedError {
            throw error
        }

        return results
    }

    func clearScanHistory() throws {
        let context = persistenceController.newBackgroundContext()
        var capturedError: Error?

        context.performAndWait {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ScanHistoryEntity.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            deleteRequest.resultType = .resultTypeObjectIDs

            do {
                if let result = try context.execute(deleteRequest) as? NSBatchDeleteResult,
                   let objectIDs = result.result as? [NSManagedObjectID],
                   !objectIDs.isEmpty {
                    let changes = [NSDeletedObjectsKey: objectIDs]
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
                }
                try context.save()
            } catch {
                context.rollback()
                capturedError = error
            }
        }

        if let error = capturedError {
            logger.error("Failed to clear scan history: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    func deleteScanHistory(_ scan: ScanHistoryEntity) throws {
        let context = persistenceController.container.viewContext
        var capturedError: Error?

        context.performAndWait {
            do {
                if let object = try? context.existingObject(with: scan.objectID) {
                    context.delete(object)
                    try context.save()
                }
            } catch {
                context.rollback()
                capturedError = error
            }
        }

        if let error = capturedError {
            logger.error("Failed to delete scan history: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

// MARK: - User Profile

    func saveUserProfile(healthFocus: String, dietaryRestrictions: [String]) throws {
        let context = persistenceController.newBackgroundContext()
        var capturedError: Error?

        context.performAndWait {
            do {
                let request: NSFetchRequest<UserProfileEntity> = UserProfileEntity.fetchRequest()
                request.fetchLimit = 1
                let profile = try context.fetch(request).first ?? UserProfileEntity(context: context)

                if profile.id == nil {
                    profile.id = UUID()
                }

                profile.healthFocus = healthFocus
                profile.dietaryRestrictions = dietaryRestrictions.joined(separator: ",")

                try context.save()
            } catch {
                context.rollback()
                capturedError = error
            }
        }

        if let error = capturedError {
            logger.error("Failed to save user profile: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    func fetchUserProfile() throws -> UserProfileEntity? {
        let context = persistenceController.container.viewContext

        var profile: UserProfileEntity?
        var capturedError: Error?

        context.performAndWait {
            let request: NSFetchRequest<UserProfileEntity> = UserProfileEntity.fetchRequest()
            request.fetchLimit = 1

            do {
                profile = try context.fetch(request).first
            } catch {
                capturedError = error
            }
        }

        if let error = capturedError {
            throw error
        }

        return profile
    }

    // MARK: - Helpers

    private func encodeNutritionalData(_ data: NutritionalData) throws -> Data {
        do {
            return try encoder.encode(data)
        } catch {
            throw CoreDataManagerError.encodingFailure
        }
    }

    private func decodeNutritionalData(_ data: Data) throws -> NutritionalData {
        do {
            return try decoder.decode(NutritionalData.self, from: data)
        } catch {
            throw CoreDataManagerError.decodingFailure
        }
    }

    private func makeProduct(from entity: ProductEntity) throws -> Product {
        guard
            let id = entity.id,
            let barcode = entity.barcode,
            let name = entity.name
        else {
            throw CoreDataManagerError.invalidProduct
        }

        guard let data = entity.nutritionalData else {
            throw CoreDataManagerError.missingNutritionalData
        }

        let nutritionalData = try decodeNutritionalData(data)

        return Product(
            id: id,
            barcode: barcode,
            name: name,
            brand: entity.brand,
            category: entity.category,
            nutritionalData: nutritionalData,
            ingredients: entity.ingredients,
            imageURL: entity.imageURL,
            thumbnailURL: entity.thumbnailURL ?? entity.imageURL,
            lastScanned: entity.lastScanned
        )
    }

    private func productEntity(for barcode: String, in context: NSManagedObjectContext) throws -> ProductEntity? {
        let request: NSFetchRequest<ProductEntity> = ProductEntity.fetchRequest()
        request.predicate = NSPredicate(format: "barcode == %@", barcode)
        request.fetchLimit = 1

        return try context.fetch(request).first
    }
}
