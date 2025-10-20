import Foundation

// Bridge CoreData Product to ScoringEngine via ProductModel
extension Product {
    func calculateScore(for healthFocus: String, dietaryRestrictions: [DietaryRestriction] = []) -> HealthScore {
        let ingredientList = (ingredients ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        let processingLevel = ProcessingLevel.determine(for: ingredientList)

        let model = ProductModel(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            brand: brand,
            category: category,
            categorySlug: nil,
            barcode: barcode,
            nutrition: ProductNutrition(
                calories: nutritionalData.calories,
                protein: nutritionalData.protein,
                carbohydrates: nutritionalData.carbohydrates,
                fat: nutritionalData.fat,
                fiber: nutritionalData.fiber,
                sugar: nutritionalData.sugar,
                sodium: nutritionalData.sodium,
                cholesterol: nutritionalData.cholesterol,
                servingSize: "100g"
            ),
            ingredients: ingredientList,
            additives: [],
            processingLevel: processingLevel,
            dietaryFlags: [],
            imageURL: imageURL,
            thumbnailURL: thumbnailURL,
            healthScore: 0,
            createdAt: lastScanned ?? Date(),
            updatedAt: lastScanned ?? Date(),
            isCached: true,
            rawIngredientsText: ingredients
        )

        let focus = mapHealthFocus(from: healthFocus)
        return ScoringEngine.shared.calculateHealthScore(
            for: model,
            healthFocus: focus,
            dietaryRestrictions: dietaryRestrictions
        )
    }
}

fileprivate func mapHealthFocus(from string: String) -> HealthFocus {
    switch string {
    case "gutHealth", "gut_health": return .gutHealth
    case "weightLoss", "weight_loss": return .weightLoss
    case "proteinFocus", "protein_focus": return .proteinFocus
    case "heartHealth", "heart_health": return .heartHealth
    case "generalWellness", "general_wellness": return .generalWellness
    default: return .generalWellness
    }
}
