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
            nutrition: ProductNutrition(
                from: apiProduct.nutritionalDataForDisplayedServing,
                servingSize: apiProduct.servingSizeLabelForDisplay
            ),
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
            nutriScore: apiProduct.nutriScore,
            dataSource: apiProduct.source
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
