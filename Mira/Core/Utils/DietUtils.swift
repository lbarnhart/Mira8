import Foundation

struct DietUtils {
    static func formatRestrictionName(_ restriction: String) -> String {
        return restriction
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
    
    static func productMeetsDietaryRestriction(_ product: ProductModel, restriction: String) -> Bool {
        // Check if the product has this restriction already flagged
        let normalizedRestriction = restriction.lowercased().replacingOccurrences(of: "_", with: "")
        
        for flag in product.dietaryFlags {
            let flagName = flag.rawValue.lowercased().replacingOccurrences(of: "_", with: "")
            if flagName == normalizedRestriction {
                return true
            }
        }
        
        // If not in dietaryFlags, do a heuristic check based on nutrition and ingredients
        switch restriction.lowercased() {
        case "vegan":
            // Check if it contains no animal products (ingredients analysis would catch this)
            return !product.ingredients.isEmpty
        case "vegetarian":
            // Check if it's likely vegetarian based on low/no meat in ingredient names
            let meatKeywords = ["meat", "fish", "poultry", "beef", "chicken", "pork", "turkey"]
            return !product.ingredients.contains { ingredient in
                meatKeywords.contains { keyword in
                    ingredient.lowercased().contains(keyword)
                }
            }
        case "gluten_free", "glutenfree":
            // Check if no gluten-containing ingredients
            let glutenKeywords = ["wheat", "barley", "rye", "gluten"]
            return !product.ingredients.contains { ingredient in
                glutenKeywords.contains { keyword in
                    ingredient.lowercased().contains(keyword)
                }
            }
        case "dairy_free", "dairyfree":
            // Check if no dairy ingredients
            let dairyKeywords = ["milk", "cheese", "butter", "cream", "yogurt", "dairy"]
            return !product.ingredients.contains { ingredient in
                dairyKeywords.contains { keyword in
                    ingredient.lowercased().contains(keyword)
                }
            }
        case "nut_free", "nutfree":
            // Check if no nuts
            let nutKeywords = ["nuts", "peanuts", "almond", "walnut", "cashew", "pecan", "pistachio"]
            return !product.ingredients.contains { ingredient in
                nutKeywords.contains { keyword in
                    ingredient.lowercased().contains(keyword)
                }
            }
        case "low_sodium", "lowsodium":
            return product.nutrition.sodium < 300 // mg per 100g
        case "sugar_free", "sugarfree":
            return product.nutrition.sugar < 1
        default:
            return false
        }
    }
}
