import Foundation

/// Centralized utility for converting APIProduct to ProductModel
/// This avoids duplicate conversion logic across AlternativesEngine and ProductService
enum ProductModelConverter {

    /// Convert an APIProduct to a ProductModel
    static func convert(_ api: APIProduct) -> ProductModel {
        // Use servingSizeDisplay if available (e.g., "2 tbsp (30 g)"), else fall back to "100g"
        let servingDisplay = api.servingSizeDisplay ?? "100g"
        let servingMultiplier = (api.servingSizeInGrams ?? 100) / 100
        let adjustedNutritionData = api.nutritionalData.scaled(by: servingMultiplier)

        let nutrition = ProductNutrition(
            calories: adjustedNutritionData.calories,
            protein: adjustedNutritionData.protein,
            carbohydrates: adjustedNutritionData.carbohydrates,
            fat: adjustedNutritionData.fat,
            fiber: adjustedNutritionData.fiber,
            sugar: adjustedNutritionData.sugar,
            sodium: adjustedNutritionData.sodium,
            cholesterol: adjustedNutritionData.cholesterol,
            servingSize: servingDisplay
        )

        let normalizedIngredients: [String]
        if !api.ingredients.isEmpty {
            normalizedIngredients = api.ingredients
        } else if let raw = api.rawIngredientsText, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            normalizedIngredients = IngredientAnalyzer.shared.parseIngredientList(raw)
        } else {
            normalizedIngredients = []
        }

        return ProductModel(
            id: UUID(),
            name: api.name,
            brand: api.brand,
            category: api.category,
            categorySlug: api.categorySlug,
            barcode: api.barcode,
            nutrition: nutrition,
            ingredients: normalizedIngredients,
            additives: [],
            processingLevel: api.processingLevel ?? .processed,
            dietaryFlags: [],
            imageURL: api.imageURL,
            thumbnailURL: api.thumbnailURL,
            healthScore: 0,
            createdAt: Date(),
            updatedAt: Date(),
            isCached: false,
            rawIngredientsText: api.rawIngredientsText
        )
    }

    /// Convert and filter products, excluding a specific barcode
    static func convertAndFilter(
        _ products: [APIProduct],
        excluding barcode: String,
        usOnly: Bool = true
    ) -> [ProductModel] {
        products
            .filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .filter { $0.barcode != barcode }
            .filter { product in
                guard usOnly else { return true }
                return isUSProduct(product)
            }
            .map { convert($0) }
            .filter { $0.nutrition.isComplete }
    }

    /// Check if a product is available in the United States
    private static func isUSProduct(_ product: APIProduct) -> Bool {
        guard let countriesTags = product.countriesTags else {
            // If countries data is not available, include the product (backwards compatibility)
            return true
        }

        let usCountryTags = ["en:united-states", "en:us", "united-states", "us"]
        return countriesTags.contains { tag in
            usCountryTags.contains(tag.lowercased())
        }
    }
}
