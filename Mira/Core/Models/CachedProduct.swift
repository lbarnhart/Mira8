import Foundation

/// Lightweight product model for Firestore cache
/// Used for saving to/retrieving from Firestore and converting to the full ProductModel.
struct CachedProduct: Codable {
    let barcode: String
    let name: String
    let brand: String?
    let category: String?
    let categorySlug: String?
    let ingredients: [String]
    let rawIngredientsText: String?
    let imageURL: String?
    let thumbnailURL: String?
    let processingLevelRaw: Int?
    let nutriScore: String?
    
    // Nutrition
    let calories: Double
    let protein: Double
    let carbohydrates: Double
    let fat: Double
    let saturatedFat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let cholesterol: Double
    let servingSize: String
    
    /// Convert to ProductModel
    func toProductModel() -> ProductModel {
        let nutrition = ProductNutrition(
            calories: calories,
            protein: protein,
            carbohydrates: carbohydrates,
            fat: fat,
            saturatedFat: saturatedFat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            cholesterol: cholesterol,
            servingSize: servingSize
        )
        
        let processingLevel = ProcessingLevel(rawValue: processingLevelRaw ?? 0) ?? .unknown
        
        return ProductModel(
            id: UUID(),
            name: name,
            brand: brand,
            category: category,
            categorySlug: categorySlug,
            barcode: barcode,
            nutrition: nutrition,
            ingredients: ingredients,
            additives: [],
            processingLevel: processingLevel,
            dietaryFlags: [],
            imageURL: imageURL,
            thumbnailURL: thumbnailURL,
            healthScore: 0,
            createdAt: Date(),
            updatedAt: Date(),
            isCached: true,
            rawIngredientsText: rawIngredientsText,
            nutriScore: nutriScore
        )
    }
}
