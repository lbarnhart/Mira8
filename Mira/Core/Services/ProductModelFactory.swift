import Foundation

/// Shared service for creating ProductModel instances from API products
/// Eliminates duplicate code across ViewModels
final class ProductModelFactory {
    static let shared = ProductModelFactory()

    private init() {}

    /// Convert APIProduct to ProductModel
    func makeProductModel(
        from apiProduct: APIProduct,
        dietaryRestrictions: [DietaryRestriction] = []
    ) -> ProductModel {
        var product = ProductModel(
            id: UUID(uuidString: apiProduct.id) ?? UUID(),
            name: apiProduct.name,
            brand: apiProduct.brand,
            category: apiProduct.category,
            categorySlug: apiProduct.categorySlug,
            barcode: apiProduct.barcode,
            nutrition: ProductNutrition(from: apiProduct.nutritionalData, servingSize: apiProduct.servingSizeDisplay ?? "100g"),
            ingredients: apiProduct.ingredients,
            additives: [],
            processingLevel: apiProduct.processingLevel ?? .unknown,
            dietaryFlags: [],
            imageURL: apiProduct.imageURL,
            thumbnailURL: apiProduct.thumbnailURL,
            healthScore: 0,
            createdAt: Date(),
            updatedAt: Date(),
            isCached: false,
            rawIngredientsText: apiProduct.rawIngredientsText,
            nutriScore: apiProduct.nutriScore
        )

        // Add fruit/veg estimation
        product.fruitVegEstimate = FruitVegLegumeNutEstimator.shared.estimate(
            ingredients: apiProduct.ingredients,
            rawText: apiProduct.rawIngredientsText,
            categorySlug: apiProduct.categorySlug
        )

        return product
    }

    /// Normalize serving size display text
    func normalizedServingBasis(_ servingSizeDisplay: String?) -> String {
        guard let display = servingSizeDisplay else { return "per 100g" }
        let trimmed = display.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "per 100g" : "per serving (\(trimmed))"
    }
}

// MARK: - ProductNutrition Extension

extension ProductNutrition {
    /// Convenience initializer from NutritionalData
    init(from nutritionalData: NutritionalData, servingSize: String) {
        self.init(
            calories: nutritionalData.calories,
            protein: nutritionalData.protein,
            carbohydrates: nutritionalData.carbohydrates,
            fat: nutritionalData.fat,
            saturatedFat: nutritionalData.saturatedFat,
            fiber: nutritionalData.fiber,
            sugar: nutritionalData.sugar,
            sodium: nutritionalData.sodium,
            cholesterol: nutritionalData.cholesterol,
            servingSize: servingSize,
            labelServingSize: servingSize,
            vitaminA: nutritionalData.vitaminA,
            vitaminC: nutritionalData.vitaminC,
            vitaminD: nutritionalData.vitaminD,
            vitaminE: nutritionalData.vitaminE,
            vitaminK: nutritionalData.vitaminK,
            thiamin: nutritionalData.thiamin,
            riboflavin: nutritionalData.riboflavin,
            niacin: nutritionalData.niacin,
            vitaminB6: nutritionalData.vitaminB6,
            folate: nutritionalData.folate,
            vitaminB12: nutritionalData.vitaminB12,
            calcium: nutritionalData.calcium,
            iron: nutritionalData.iron,
            magnesium: nutritionalData.magnesium,
            phosphorus: nutritionalData.phosphorus,
            potassium: nutritionalData.potassium,
            zinc: nutritionalData.zinc,
            availability: nutritionalData.availability
        )
    }
}
