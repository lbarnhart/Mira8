import Foundation

/// Provides category-specific context messages that explain why certain nutrients
/// are naturally higher in specific food types, reducing unfair scoring penalties
struct CategoryContextProvider {

    // MARK: - Public API

    /// Get context message for a product based on its category and nutritional profile
    static func context(for product: ProductModel, healthScore: HealthScore) -> CategoryContext? {
        let category = product.category?.lowercased() ?? ""
        let name = product.name.lowercased()

        // Check for specific food categories
        if isCheese(category: category, name: name) {
            return cheeseContext(product: product, healthScore: healthScore)
        } else if isMeat(category: category, name: name) {
            return meatContext(product: product, healthScore: healthScore)
        } else if isNuts(category: category, name: name) {
            return nutsContext(product: product, healthScore: healthScore)
        } else if isDarkChocolate(category: category, name: name) {
            return darkChocolateContext(product: product, healthScore: healthScore)
        } else if isFermented(category: category, name: name) {
            return fermentedContext(product: product, healthScore: healthScore)
        } else if isFullFatDairy(category: category, name: name) {
            return fullFatDairyContext(product: product, healthScore: healthScore)
        }

        return nil
    }

    // MARK: - Category Detection

    private static func isCheese(category: String, name: String) -> Bool {
        category.contains("cheese") ||
        category.contains("fromage") ||
        name.contains("cheese") ||
        name.contains("cheddar") ||
        name.contains("mozzarella") ||
        name.contains("parmesan") ||
        name.contains("feta") ||
        name.contains("gouda") ||
        name.contains("brie")
    }

    private static func isMeat(category: String, name: String) -> Bool {
        category.contains("meat") ||
        category.contains("beef") ||
        category.contains("chicken") ||
        category.contains("pork") ||
        category.contains("turkey") ||
        category.contains("jerky") ||
        category.contains("bacon") ||
        name.contains("jerky") ||
        name.contains("bacon") ||
        name.contains("sausage")
    }

    private static func isNuts(category: String, name: String) -> Bool {
        category.contains("nut") ||
        category.contains("almond") ||
        category.contains("walnut") ||
        category.contains("cashew") ||
        category.contains("peanut") ||
        category.contains("trail mix") ||
        name.contains("almonds") ||
        name.contains("walnuts") ||
        name.contains("cashews") ||
        name.contains("peanuts") ||
        name.contains("pistachios")
    }

    private static func isDarkChocolate(category: String, name: String) -> Bool {
        (category.contains("chocolate") || name.contains("chocolate")) &&
        (name.contains("dark") || name.contains("70%") || name.contains("85%") || name.contains("cacao"))
    }

    private static func isFermented(category: String, name: String) -> Bool {
        category.contains("yogurt") ||
        category.contains("kefir") ||
        category.contains("kimchi") ||
        category.contains("sauerkraut") ||
        category.contains("kombucha") ||
        category.contains("miso") ||
        category.contains("tempeh") ||
        name.contains("yogurt") ||
        name.contains("kefir") ||
        name.contains("probiotic")
    }

    private static func isFullFatDairy(category: String, name: String) -> Bool {
        (category.contains("milk") || category.contains("dairy") || category.contains("yogurt")) &&
        (name.contains("whole") || name.contains("full fat") || name.contains("4%"))
    }

    // MARK: - Context Generators

    private static func cheeseContext(product: ProductModel, healthScore: HealthScore) -> CategoryContext {
        let satFat = product.nutrition.saturatedFat
        let protein = product.nutrition.protein

        var message = "For cheese: "
        var positives: [String] = []

        if satFat > 0 {
            message += "Naturally higher in saturated fat, which is expected. "
        }

        if protein >= 6 {
            positives.append("excellent protein source (\(String(format: "%.1f", protein))g)")
        }

        // Check for calcium (if available in micronutrients)
        positives.append("rich in calcium")

        if !positives.isEmpty {
            message += "This cheese is an " + positives.joined(separator: " and ") + "."
        }

        return CategoryContext(
            icon: "🧀",
            message: message,
            type: .neutral
        )
    }

    private static func meatContext(product: ProductModel, healthScore: HealthScore) -> CategoryContext {
        let protein = product.nutrition.protein
        let calories = product.nutrition.calories
        let proteinToCalorieRatio = calories > 0 ? (protein * 4) / calories : 0

        var message = "For protein snacks: "

        if proteinToCalorieRatio > 0.4 {
            message += "Excellent protein-to-calorie ratio (\(String(format: "%.0f", proteinToCalorieRatio * 100))%). "
        }

        if protein >= 10 {
            message += "High protein content (\(String(format: "%.1f", protein))g). "
        }

        message += "We focus on protein quality and minimal additives for this category."

        return CategoryContext(
            icon: "🥩",
            message: message,
            type: .positive
        )
    }

    private static func nutsContext(product: ProductModel, healthScore: HealthScore) -> CategoryContext {
        let fat = product.nutrition.fat
        let calories = product.nutrition.calories

        var message = "For nuts: "

        if calories > 150 {
            message += "Higher calories are expected and come from healthy fats. "
        }

        if fat > 10 {
            message += "The fats in nuts are mostly unsaturated (heart-healthy). "
        }

        message += "Nuts provide essential nutrients, fiber, and sustained energy."

        return CategoryContext(
            icon: "🥜",
            message: message,
            type: .positive
        )
    }

    private static func darkChocolateContext(product: ProductModel, healthScore: HealthScore) -> CategoryContext {
        let fat = product.nutrition.fat
        let sugar = product.nutrition.sugar

        var message = "For dark chocolate: "

        if fat > 8 {
            message += "Higher fat content is natural—cocoa butter is heart-healthy. "
        }

        if sugar < 10 {
            message += "Low sugar for chocolate (\(String(format: "%.1f", sugar))g). "
        }

        message += "Dark chocolate is rich in antioxidants and minerals."

        return CategoryContext(
            icon: "🍫",
            message: message,
            type: .positive
        )
    }

    private static func fermentedContext(product: ProductModel, healthScore: HealthScore) -> CategoryContext {
        var message = "For fermented foods: "

        message += "Contains beneficial bacteria (probiotics) that support gut health. "
        message += "Fermentation improves nutrient bioavailability and digestive benefits."

        return CategoryContext(
            icon: "🦠",
            message: message,
            type: .positive
        )
    }

    private static func fullFatDairyContext(product: ProductModel, healthScore: HealthScore) -> CategoryContext {
        let satFat = product.nutrition.saturatedFat

        var message = "For full-fat dairy: "

        if satFat > 3 {
            message += "Naturally higher in saturated fat. "
        }

        message += "Full-fat dairy provides vitamins A, D, E, K and may improve satiety. "
        message += "Recent research suggests full-fat dairy can be part of a healthy diet."

        return CategoryContext(
            icon: "🥛",
            message: message,
            type: .neutral
        )
    }
}

// MARK: - Models

struct CategoryContext {
    let icon: String
    let message: String
    let type: ContextType

    enum ContextType {
        case positive
        case neutral
        case informational
    }
}
