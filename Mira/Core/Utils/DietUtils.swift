import Foundation

struct DietUtils {
    static func formatRestrictionName(_ restriction: String) -> String {
        return restriction
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
    
    static func productMeetsDietaryRestriction(_ product: ProductModel, restriction: String) -> Bool {
        guard let parsedRestriction = DietaryRestriction(from: restriction) else { return false }

        // Check if the product has this restriction already flagged
        if product.dietaryFlags.contains(parsedRestriction) {
            return true
        }

        switch parsedRestriction {
        case .lowSodium:
            return product.nutrition.sodiumMilligrams < 300
        case .sugarFree:
            return product.nutrition.sugar < 1

        case .vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree:
            let result = DietaryQuickChecker.quickCheck(
                restriction: parsedRestriction,
                ingredients: product.ingredients,
                rawIngredientsText: product.rawIngredientsText
            )
            if case .definitePass = result { return true }
            return false
        }
    }
}
