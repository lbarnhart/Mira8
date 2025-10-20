import Foundation

// MARK: - USDA Service
actor USDAService {
    static let shared = USDAService()

    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }

    // MARK: - Public Methods
    func searchProductByBarcode(_ barcode: String) async throws -> APIProduct {
        let endpoint = USDAEndpoint.searchByBarcode(barcode: barcode)
        let response: USDASearchResponse = try await apiClient.request(endpoint)

        guard let foodItem = response.foods.first else {
            throw NetworkError.productNotFound
        }

        return try mapToProduct(foodItem)
    }

    func fetchProductDetails(fdcId: String) async throws -> ProductDetails {
        let endpoint = USDAEndpoint.foodDetails(fdcId: fdcId)
        let response: USDAFoodDetailsResponse = try await apiClient.request(endpoint)

        return try mapToProductDetails(response)
    }
}

// MARK: - USDA Endpoints
private enum USDAEndpoint: APIEndpoint {
    case searchByBarcode(barcode: String)
    case foodDetails(fdcId: String)

    var baseURL: String {
        return Constants.API.usdaBaseURL
    }

    var path: String {
        switch self {
        case .searchByBarcode:
            return "/fdc/v1/foods/search"
        case .foodDetails(let fdcId):
            return "/fdc/v1/food/\(fdcId)"
        }
    }

    var queryItems: [URLQueryItem]? {
        var items = [URLQueryItem(name: "api_key", value: Constants.API.usdaAPIKey)]

        switch self {
        case .searchByBarcode(let barcode):
            items.append(contentsOf: [
                URLQueryItem(name: "query", value: barcode),
                URLQueryItem(name: "dataType", value: "Branded"),
                URLQueryItem(name: "pageSize", value: "25"),
                URLQueryItem(name: "pageNumber", value: "1"),
                URLQueryItem(name: "sortBy", value: "dataType.keyword"),
                URLQueryItem(name: "sortOrder", value: "asc")
            ])
        case .foodDetails:
            items.append(contentsOf: [
                URLQueryItem(name: "nutrients", value: "203,204,205,291,269,307,208")
            ])
        }

        return items
    }
}

// MARK: - USDA Response Models
private struct USDASearchResponse: Codable {
    let totalHits: Int
    let currentPage: Int
    let totalPages: Int
    let foods: [USDAFood]
}

private struct USDAFoodDetailsResponse: Codable {
    let fdcId: Int
    let description: String
    let brandOwner: String?
    let brandName: String?
    let ingredients: String?
    let servingSize: Double?
    let servingSizeUnit: String?
    let householdServingFullText: String?
    let foodNutrients: [USDANutrient]
    let labelNutrients: USDALabelNutrients?
    let foodCategory: USDAFoodCategory?
    let gtinUpc: String?
}

private struct USDAFood: Codable {
    let fdcId: Int
    let description: String
    let brandOwner: String?
    let brandName: String?
    let ingredients: String?
    let foodNutrients: [USDANutrient]?
    let labelNutrients: USDALabelNutrients?
    let servingSize: Double?
    let servingSizeUnit: String?
    let householdServingFullText: String?
    let foodCategory: String?
    let gtinUpc: String?
}

private struct USDANutrient: Codable {
    let nutrientId: Int
    let nutrientName: String
    let nutrientNumber: String
    let unitName: String
    let value: Double?
    let rank: Int?
}

private struct USDAFoodCategory: Codable {
    let id: Int
    let code: String
    let description: String
}

private struct USDALabelNutrients: Codable {
    let calories: USDALabelNutrientValue?
    let protein: USDALabelNutrientValue?
    let fat: USDALabelNutrientValue?
    let carbohydrates: USDALabelNutrientValue?
    let fiber: USDALabelNutrientValue?
    let sugars: USDALabelNutrientValue?
    let sodium: USDALabelNutrientValue?
    let cholesterol: USDALabelNutrientValue?
}

private struct USDALabelNutrientValue: Codable {
    let value: Double?
}

// MARK: - Mapping Extensions
private extension USDAService {
    func mapToProduct(_ usdaFood: USDAFood) throws -> APIProduct {
        let nutritionalData = mapNutritionalData(usdaFood.foodNutrients ?? [], labelNutrients: usdaFood.labelNutrients)
        let parsedIngredients = parseIngredients(usdaFood.ingredients)
        let ingredientsRaw = usdaFood.ingredients ?? "nil"
        AppLog.debug("🔍 USDA - Ingredients raw: \(ingredientsRaw)", category: .network)
        AppLog.debug("🔍 USDA - Parsed count: \(parsedIngredients.count)", category: .network)

        // Use householdServingFullText as display string if available
        let servingSizeDisplay = usdaFood.householdServingFullText?.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayStr = servingSizeDisplay ?? "nil"
        AppLog.debug("🥄 USDA serving display: \(displayStr)", category: .network)

        return APIProduct(
            id: "\(usdaFood.fdcId)",
            barcode: usdaFood.gtinUpc ?? "",
            name: usdaFood.description,
            brand: usdaFood.brandOwner ?? usdaFood.brandName ?? "Unknown",
            category: usdaFood.foodCategory ?? "Food",
            categorySlug: nil,
            ingredients: parsedIngredients,
            rawIngredientsText: usdaFood.ingredients,
            nutritionalData: nutritionalData,
            servingSize: usdaFood.servingSize,
            servingSizeUnit: usdaFood.servingSizeUnit ?? "g",
            servingSizeDisplay: servingSizeDisplay,
            imageURL: nil,
            thumbnailURL: nil,
            source: .usda
        )
    }

    func mapToProductDetails(_ response: USDAFoodDetailsResponse) throws -> ProductDetails {
        let nutritionalData = mapNutritionalData(response.foodNutrients, labelNutrients: response.labelNutrients)

        // Use householdServingFullText as display string if available
        let servingSizeDisplay = response.householdServingFullText?.trimmingCharacters(in: .whitespacesAndNewlines)

        let product = APIProduct(
            id: "\(response.fdcId)",
            barcode: response.gtinUpc ?? "",
            name: response.description,
            brand: response.brandOwner ?? response.brandName ?? "Unknown",
            category: response.foodCategory?.description ?? "Food",
            categorySlug: nil,
            ingredients: parseIngredients(response.ingredients),
            rawIngredientsText: response.ingredients,
            nutritionalData: nutritionalData,
            servingSize: response.servingSize,
            servingSizeUnit: response.servingSizeUnit ?? "g",
            servingSizeDisplay: servingSizeDisplay,
            imageURL: nil,
            thumbnailURL: nil,
            source: .usda
        )

        return ProductDetails(
            product: product,
            detailedNutrients: mapDetailedNutrients(response.foodNutrients),
            allergens: extractAllergens(response.ingredients),
            additives: extractAdditives(response.ingredients),
            processingLevel: determineProcessingLevel(response.ingredients),
            healthScore: 0.0 // Will be calculated by scoring service
        )
    }

    /// Maps USDA nutritional data, preferring per-serving labelNutrients when available.
    ///
    /// USDA provides two sources of nutritional data:
    /// 1. foodNutrients: per-100g values (always present)
    /// 2. labelNutrients: per-serving values from product labels (optional)
    ///
    /// When labelNutrients are available, they are preferred as they represent
    /// the actual serving size. When not available, we fall back to per-100g values.
    /// Downstream consumers should check servingSizeDisplay to understand the basis.
    func mapNutritionalData(_ nutrients: [USDANutrient], labelNutrients: USDALabelNutrients?) -> NutritionalData {
        var nutritionalData = NutritionalData()

        // First, extract per-100g values from foodNutrients as fallback
        for nutrient in nutrients {
            guard let value = nutrient.value else { continue }

            switch nutrient.nutrientNumber {
            case "208": // Energy (calories)
                nutritionalData.calories = value
            case "203": // Protein
                nutritionalData.protein = value
            case "204": // Total fat
                nutritionalData.fat = value
            case "205": // Carbohydrates
                nutritionalData.carbohydrates = value
            case "291": // Fiber
                nutritionalData.fiber = value
            case "269": // Sugars
                nutritionalData.sugar = value
            case "307": // Sodium
                nutritionalData.sodium = value / 1000 // Convert mg to g
            case "601": // Cholesterol
                nutritionalData.cholesterol = value / 1000 // Convert mg to g
            default:
                break
            }
        }

        // Then, override with per-serving labelNutrients values when available
        if let labelNutrients = labelNutrients {
            if let calories = labelNutrients.calories?.value {
                nutritionalData.calories = calories
            }
            if let protein = labelNutrients.protein?.value {
                nutritionalData.protein = protein
            }
            if let fat = labelNutrients.fat?.value {
                nutritionalData.fat = fat
            }
            if let carbs = labelNutrients.carbohydrates?.value {
                nutritionalData.carbohydrates = carbs
            }
            if let fiber = labelNutrients.fiber?.value {
                nutritionalData.fiber = fiber
            }
            if let sugars = labelNutrients.sugars?.value {
                nutritionalData.sugar = sugars
            }
            if let sodium = labelNutrients.sodium?.value {
                // labelNutrients.sodium is already in mg, convert to g
                nutritionalData.sodium = sodium / 1000
            }
            if let cholesterol = labelNutrients.cholesterol?.value {
                // labelNutrients.cholesterol is already in mg, convert to g
                nutritionalData.cholesterol = cholesterol / 1000
            }
        }

        return nutritionalData
    }

    func mapDetailedNutrients(_ nutrients: [USDANutrient]) -> [DetailedNutrient] {
        return nutrients.compactMap { nutrient in
            guard let value = nutrient.value else { return nil }

            return DetailedNutrient(
                name: nutrient.nutrientName,
                value: value,
                unit: nutrient.unitName,
                dailyValue: calculateDailyValue(nutrientNumber: nutrient.nutrientNumber, value: value)
            )
        }
    }

    func parseIngredients(_ ingredientsString: String?) -> [String] {
        IngredientAnalyzer.shared.parseIngredientList(ingredientsString)
    }

    func extractAllergens(_ ingredientsString: String?) -> [String] {
        guard let ingredients = ingredientsString?.lowercased() else { return [] }

        let commonAllergens = [
            "milk", "eggs", "fish", "shellfish", "tree nuts", "peanuts",
            "wheat", "soybeans", "sesame", "soy", "dairy", "gluten"
        ]

        return commonAllergens.filter { allergen in
            ingredients.contains(allergen)
        }
    }

    func extractAdditives(_ ingredientsString: String?) -> [String] {
        guard let ingredients = ingredientsString?.lowercased() else { return [] }

        let commonAdditives = [
            "sodium benzoate", "potassium sorbate", "citric acid", "natural flavor",
            "artificial flavor", "high fructose corn syrup", "corn syrup",
            "mono- and diglycerides", "sodium nitrite", "bht", "bha"
        ]

        return commonAdditives.filter { additive in
            ingredients.contains(additive)
        }
    }

    func determineProcessingLevel(_ ingredientsString: String?) -> ProcessingLevel {
        guard let ingredients = ingredientsString?.lowercased() else { return .unknown }

        let highlyProcessedIndicators = [
            "high fructose corn syrup", "corn syrup", "artificial", "modified",
            "hydrogenated", "partially hydrogenated", "sodium nitrite", "preservative"
        ]

        let moderatelyProcessedIndicators = [
            "natural flavor", "citric acid", "ascorbic acid", "sodium benzoate"
        ]

        if highlyProcessedIndicators.contains(where: { ingredients.contains($0) }) {
            return .ultraProcessed
        } else if moderatelyProcessedIndicators.contains(where: { ingredients.contains($0) }) {
            return .processed
        } else {
            return .minimal
        }
    }

    func calculateDailyValue(nutrientNumber: String, value: Double) -> Double? {
        // Daily Value percentages based on 2000-calorie diet
        switch nutrientNumber {
        case "203": // Protein (50g)
            return (value / 50.0) * 100
        case "204": // Total fat (78g)
            return (value / 78.0) * 100
        case "205": // Carbohydrates (300g)
            return (value / 300.0) * 100
        case "291": // Fiber (25g)
            return (value / 25.0) * 100
        case "307": // Sodium (2300mg)
            return (value / 2300.0) * 100
        default:
            return nil
        }
    }
}

// MARK: - Supporting Models
struct ProductDetails {
    let product: APIProduct
    let detailedNutrients: [DetailedNutrient]
    let allergens: [String]
    let additives: [String]
    let processingLevel: ProcessingLevel
    let healthScore: Double
}

struct DetailedNutrient {
    let name: String
    let value: Double
    let unit: String
    let dailyValue: Double?
}

enum ProcessingLevel: Int, CaseIterable, Codable {
    case minimal = 1
    case processed = 2
    case ultraProcessed = 3
    case unknown = 4

    var displayName: String {
        switch self {
        case .minimal: return "Minimal Processing"
        case .processed: return "Processed"
        case .ultraProcessed: return "Ultra-Processed"
        case .unknown: return "Unknown"
        }
    }

    static func determine(for ingredients: [String]) -> ProcessingLevel {
        let nonBlank = ingredients.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard nonBlank.count == 1, let singleIngredient = nonBlank.first else {
            return .processed
        }

        let normalized = singleIngredient.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        let disqualifiers = [
            "natural flavor", "natural flavoring", "concentrate", "modified", "hydrogenated",
            "artificial", "preservative", "sodium benzoate", "potassium sorbate"
        ]
        for disqualifier in disqualifiers {
            if normalized.contains(disqualifier) {
                return .processed
            }
        }

        let wholeFoodKeywords = [
            "spinach", "kale", "lettuce", "arugula", "broccoli", "cauliflower", "carrot",
            "celery", "cucumber", "tomato", "pepper", "onion", "garlic", "potato",
            "sweet potato", "beet", "cabbage", "brussels sprout", "asparagus", "zucchini",
            "apple", "banana", "orange", "strawberry", "blueberry", "raspberry", "blackberry",
            "grape", "peach", "pear", "plum", "cherry", "watermelon", "cantaloupe", "mango",
            "pineapple", "kiwi", "avocado", "lemon", "lime",
            "chicken breast", "chicken thigh", "turkey breast", "beef", "pork", "lamb",
            "salmon", "tuna", "cod", "shrimp", "tilapia", "trout",
            "egg", "eggs",
            "rice", "quinoa", "oat", "barley", "bulgur", "millet",
            "almond", "walnut", "cashew", "pecan", "peanut", "hazelnut",
            "black bean", "kidney bean", "chickpea", "lentil", "pinto bean"
        ]

        for keyword in wholeFoodKeywords {
            if normalized.contains(keyword) {
                return .minimal
            }
        }

        return .processed
    }

    /// Map NOVA group (1-4) to ProcessingLevel enum
    /// NOVA 1 = Unprocessed or minimally processed → .minimal
    /// NOVA 2 = Processed culinary ingredients → .processed
    /// NOVA 3 = Processed foods → .processed
    /// NOVA 4 = Ultra-processed foods → .ultraProcessed
    static func fromNOVA(_ novaGroup: Int?) -> ProcessingLevel? {
        guard let nova = novaGroup else { return nil }

        switch nova {
        case 1:
            return .minimal
        case 2, 3:
            return .processed
        case 4:
            return .ultraProcessed
        default:
            return nil
        }
    }
}

enum ProductSource: String, CaseIterable, Codable {
    case usda = "USDA"
    case openFoodFacts = "Open Food Facts"
    case manual = "Manual Entry"
}
