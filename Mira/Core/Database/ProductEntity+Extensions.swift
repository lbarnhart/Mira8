import Foundation
import CoreData

extension ProductEntity {
    func toProduct() -> Product? {
        guard let barcode = self.barcode, let name = self.name else {
            AppLog.warning("Missing required fields in ProductEntity", category: .persistence)
            return nil
        }

        var nutritionalInfo = NutritionalData()
        if let data = self.nutritionalData {
            if let decoded = try? JSONDecoder().decode(NutritionalData.self, from: data) {
                nutritionalInfo = decoded
            } else {
                AppLog.warning("Failed to decode NutritionalData from ProductEntity for barcode: \(barcode)", category: .persistence)
            }
        } else {
            AppLog.warning("No NutritionalData stored for ProductEntity barcode: \(barcode)", category: .persistence)
        }

        let product = Product(
            id: self.id ?? UUID().uuidString,
            barcode: barcode,
            name: name,
            brand: self.brand,
            category: self.category,
            nutritionalData: nutritionalInfo,
            ingredients: self.ingredients,
            imageURL: self.imageURL,
            thumbnailURL: self.thumbnailURL ?? self.imageURL,
            lastScanned: self.lastScanned
        )

        AppLog.debug("Converted ProductEntity to Product: \(product.name)", category: .persistence)
        AppLog.debug("   Protein: \(product.nutritionalData.protein)g, Fiber: \(product.nutritionalData.fiber)g", category: .persistence)

        return product
    }

    static func fromProduct(_ product: Product, in context: NSManagedObjectContext) throws -> ProductEntity {
        let request: NSFetchRequest<ProductEntity> = ProductEntity.fetchRequest()
        request.predicate = NSPredicate(format: "barcode == %@", product.barcode)
        request.fetchLimit = 1

        let entity = (try? context.fetch(request).first) ?? ProductEntity(context: context)

        entity.id = product.id
        entity.barcode = product.barcode
        entity.name = product.name
        entity.brand = product.brand
        entity.category = product.category
        entity.ingredients = product.ingredients
        entity.imageURL = product.imageURL
        entity.thumbnailURL = product.thumbnailURL ?? product.imageURL
        entity.lastScanned = product.lastScanned ?? Date()

        // Encode nutritional data
        if let data = try? JSONEncoder().encode(product.nutritionalData) {
            entity.nutritionalData = data
        } else {
            AppLog.warning("Failed to encode NutritionalData for product barcode: \(product.barcode)", category: .persistence)
        }

        AppLog.debug("Created/Updated ProductEntity from Product: \(product.name)", category: .persistence)
        AppLog.debug("   Protein: \(product.nutritionalData.protein)g, Fiber: \(product.nutritionalData.fiber)g", category: .persistence)

        return entity
    }
}
