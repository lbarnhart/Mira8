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
            nutriScore: nutriScore
        )
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
