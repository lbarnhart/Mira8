import Foundation

extension ProductModel {
    /// Convert ProductModel to CoreData-compatible Product struct
    func toCoreDataProduct() -> Product {
        // Convert [String] ingredients to String?
        let ingredientsString = ingredients.isEmpty ? nil : ingredients.joined(separator: ", ")
        
        return Product(
            id: id.uuidString,
            barcode: barcode,
            name: name,
            brand: brand,
            category: category,
            nutritionalData: nutrition.nutritionData, // Need to map this too
            ingredients: ingredientsString,
            servingSize: nutrition.servingSize,
            imageURL: imageURL,
            thumbnailURL: thumbnailURL,
            lastScanned: Date(),
            nutriScore: nutriScore,
            dataSource: dataSource
        )
    }
}

extension Product {
    /// Convert a persisted product back to the UI model without dropping nutrient fields.
    func toProductModel(
        nutritionalData overrideNutrition: NutritionalData? = nil,
        servingSize overrideServingSize: String? = nil
    ) -> ProductModel {
        let ingredientList = (ingredients ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let resolvedServingSize = overrideServingSize
            ?? self.servingSize?.trimmingCharacters(in: .whitespacesAndNewlines)
        let servingText: String
        if let resolvedServingSize, !resolvedServingSize.isEmpty {
            servingText = resolvedServingSize
        } else {
            servingText = "100g"
        }
        let resolvedNutrition = overrideNutrition ?? nutritionalData

        var model = ProductModel(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            brand: brand,
            category: category,
            categorySlug: category?.lowercased().replacingOccurrences(of: " ", with: "-"),
            barcode: barcode,
            nutrition: ProductNutrition(from: resolvedNutrition, servingSize: servingText),
            ingredients: ingredientList,
            additives: [],
            processingLevel: ProcessingLevel.determine(for: ingredientList),
            dietaryFlags: [],
            imageURL: imageURL,
            thumbnailURL: thumbnailURL,
            healthScore: 0,
            createdAt: lastScanned ?? Date(),
            updatedAt: lastScanned ?? Date(),
            isCached: true,
            rawIngredientsText: ingredients,
            nutriScore: nutriScore,
            dataSource: dataSource
        )
        model.fruitVegEstimate = FruitVegLegumeNutEstimator.shared.estimate(
            ingredients: ingredientList,
            rawText: ingredients,
            categorySlug: model.categorySlug
        )
        return model
    }
}

extension ProductNutrition {
    /// Convert ProductNutrition to NutritionalData used by CoreData
    var nutritionData: NutritionalData {
        NutritionalData(
            calories: calories,
            protein: protein,
            carbohydrates: carbohydrates,
            fat: fat,
            saturatedFat: saturatedFat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            cholesterol: cholesterol,
            vitaminA: vitaminA,
            vitaminC: vitaminC,
            vitaminD: vitaminD,
            vitaminE: vitaminE,
            vitaminK: vitaminK,
            thiamin: thiamin,
            riboflavin: riboflavin,
            niacin: niacin,
            vitaminB6: vitaminB6,
            folate: folate,
            vitaminB12: vitaminB12,
            calcium: calcium,
            iron: iron,
            magnesium: magnesium,
            phosphorus: phosphorus,
            potassium: potassium,
            zinc: zinc,
            availability: availability
        )
    }
}
