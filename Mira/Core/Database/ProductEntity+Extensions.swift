import Foundation
import CoreData

extension ProductEntity {
    func toProduct() -> Product? {
        guard let id = self.id, let barcode = self.barcode, let name = self.name else {
            AppLog.warning("Missing required fields in ProductEntity", category: .persistence)
            return nil
        }

        guard let data = self.nutritionalData else {
            AppLog.warning("No NutritionalData stored for ProductEntity barcode: \(barcode)", category: .persistence)
            return nil
        }

        let nutritionalInfo: NutritionalData
        do {
            nutritionalInfo = try JSONDecoder().decode(NutritionalData.self, from: data)
        } catch {
            AppLog.warning("Failed to decode NutritionalData from ProductEntity for barcode: \(barcode)", category: .persistence)
            return nil
        }

        let product = Product(
            id: id,
            barcode: barcode,
            name: name,
            brand: self.brand,
            category: self.category,
            nutritionalData: nutritionalInfo,
            ingredients: self.ingredients,
            servingSize: self.servingSize,
            imageURL: self.imageURL,
            thumbnailURL: self.thumbnailURL ?? self.imageURL,
            lastScanned: self.lastScanned,
            nutriScore: self.nutriScore,
            dataSource: self.dataSource.flatMap(ProductSource.init(rawValue:))
        )

        AppLog.debug("Converted ProductEntity to Product: \(product.name)", category: .persistence)
        AppLog.debug("   Protein: \(product.nutritionalData.protein)g, Fiber: \(product.nutritionalData.fiber)g", category: .persistence)

        return product
    }

    static func fromProduct(_ product: Product, in context: NSManagedObjectContext) throws -> ProductEntity {
        let request: NSFetchRequest<ProductEntity> = ProductEntity.fetchRequest()
        request.predicate = NSPredicate(format: "barcode == %@", product.barcode)
        request.fetchLimit = 1

        let entity = try context.fetch(request).first ?? ProductEntity(context: context)

        entity.id = product.id
        entity.barcode = product.barcode
        entity.name = product.name
        entity.brand = product.brand
        entity.category = product.category
        entity.ingredients = product.ingredients
        entity.servingSize = product.servingSize
        entity.imageURL = product.imageURL
        entity.thumbnailURL = product.thumbnailURL ?? product.imageURL
        entity.lastScanned = product.lastScanned ?? Date()
        entity.nutriScore = product.nutriScore
        entity.dataSource = product.dataSource?.rawValue

        entity.nutritionalData = try JSONEncoder().encode(product.nutritionalData)

        AppLog.debug("Created/Updated ProductEntity from Product: \(product.name)", category: .persistence)
        AppLog.debug("   Protein: \(product.nutritionalData.protein)g, Fiber: \(product.nutritionalData.fiber)g", category: .persistence)

        return entity
    }
}
