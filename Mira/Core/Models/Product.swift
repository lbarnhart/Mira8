import Foundation

// MARK: - External/API Product Model
// This model is used by network services (USDA/OpenFoodFacts) to represent
// fetched products before they are converted to the app's internal models.
struct APIProduct: Codable, Identifiable {
    let id: String
    let barcode: String
    let name: String
    let brand: String
    let category: String
    let categorySlug: String?
    let ingredients: [String]
    let rawIngredientsText: String?
    let nutritionalData: NutritionalData
    let servingSize: Double?
    let servingSizeUnit: String
    let servingSizeDisplay: String?  // Raw serving size text from data source (e.g., "2 tbsp (30 g)")
    let imageURL: String?
    let thumbnailURL: String?
    let source: ProductSource
    let countriesTags: [String]?
    let processingLevel: ProcessingLevel?
    let nutriScore: String?

    init(
        id: String,
        barcode: String,
        name: String,
        brand: String,
        category: String,
        categorySlug: String? = nil,
        ingredients: [String],
        rawIngredientsText: String? = nil,
        nutritionalData: NutritionalData,
        servingSize: Double? = nil,
        servingSizeUnit: String = "g",
        servingSizeDisplay: String? = nil,
        imageURL: String? = nil,
        thumbnailURL: String? = nil,
        source: ProductSource,
        countriesTags: [String]? = nil,
        processingLevel: ProcessingLevel? = nil,
        nutriScore: String? = nil
    ) {
        self.id = id
        self.barcode = barcode
        self.name = name
        self.brand = brand
        self.category = category
        self.categorySlug = categorySlug
        self.ingredients = ingredients
        self.rawIngredientsText = rawIngredientsText
        self.nutritionalData = nutritionalData
        self.servingSize = servingSize
        self.servingSizeUnit = servingSizeUnit
        self.servingSizeDisplay = servingSizeDisplay
        self.imageURL = imageURL
        self.thumbnailURL = thumbnailURL
        self.source = source
        self.countriesTags = countriesTags
        self.processingLevel = processingLevel
        self.nutriScore = nutriScore
    }
}

// MARK: - Nutritional Data
struct NutritionalData: Codable {
    var calories: Double
    var protein: Double
    var carbohydrates: Double
    var fat: Double
    var saturatedFat: Double
    var fiber: Double
    var sugar: Double
    var sodium: Double
    var cholesterol: Double

    // Micronutrients (optional)
    var vitaminA: Double?
    var vitaminC: Double?
    var vitaminD: Double?
    var vitaminE: Double?
    var vitaminK: Double?
    var thiamin: Double?
    var riboflavin: Double?
    var niacin: Double?
    var vitaminB6: Double?
    var folate: Double?
    var vitaminB12: Double?
    var calcium: Double?
    var iron: Double?
    var magnesium: Double?
    var phosphorus: Double?
    var potassium: Double?
    var zinc: Double?
    var availability: DataAvailability?

    init(
        calories: Double = 0,
        protein: Double = 0,
        carbohydrates: Double = 0,
        fat: Double = 0,
        saturatedFat: Double = 0,
        fiber: Double = 0,
        sugar: Double = 0,
        sodium: Double = 0,
        cholesterol: Double = 0,
        vitaminA: Double? = nil,
        vitaminC: Double? = nil,
        vitaminD: Double? = nil,
        vitaminE: Double? = nil,
        vitaminK: Double? = nil,
        thiamin: Double? = nil,
        riboflavin: Double? = nil,
        niacin: Double? = nil,
        vitaminB6: Double? = nil,
        folate: Double? = nil,
        vitaminB12: Double? = nil,
        calcium: Double? = nil,
        iron: Double? = nil,
        magnesium: Double? = nil,
        phosphorus: Double? = nil,
        potassium: Double? = nil,
        zinc: Double? = nil,
        availability: DataAvailability? = nil
    ) {
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.saturatedFat = saturatedFat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.cholesterol = cholesterol
        self.vitaminA = vitaminA
        self.vitaminC = vitaminC
        self.vitaminD = vitaminD
        self.vitaminE = vitaminE
        self.vitaminK = vitaminK
        self.thiamin = thiamin
        self.riboflavin = riboflavin
        self.niacin = niacin
        self.vitaminB6 = vitaminB6
        self.folate = folate
        self.vitaminB12 = vitaminB12
        self.calcium = calcium
        self.iron = iron
        self.magnesium = magnesium
        self.phosphorus = phosphorus
        self.potassium = potassium
        self.zinc = zinc
        self.availability = availability
    }
}

// MARK: - App Product Model
struct ProductModel: Identifiable, Codable {
    let id: UUID
    let name: String
    let brand: String?
    var category: String?
    var categorySlug: String?
    let barcode: String
    var nutrition: ProductNutrition
    var ingredients: [String]
    var additives: [String]
    var processingLevel: ProcessingLevel
    var dietaryFlags: [DietaryRestriction]
    var imageURL: String?
    var thumbnailURL: String?
    var healthScore: Double
    var createdAt: Date
    var updatedAt: Date
    var isCached: Bool
    var rawIngredientsText: String?
    var nutriScore: String?
    var fruitVegEstimate: FruitVegEstimate = .unknown

    /// Determine if product is likely a beverage based on category
    var isLikelyBeverage: Bool {
        guard let categorySlug = categorySlug?.lowercased() else { return false }
        let beverageKeywords = ["beverage", "drink", "juice", "soda", "water", "tea", "coffee", "milk", "smoothie"]
        return beverageKeywords.contains { categorySlug.contains($0) }
    }
}

struct ProductNutrition: Codable {
    var calories: Double
    var protein: Double
    var carbohydrates: Double
    var fat: Double
    var saturatedFat: Double
    var fiber: Double
    var sugar: Double
    var sodium: Double
    var cholesterol: Double
    var servingSize: String
    var labelServingSize: String?
    var availability: DataAvailability?

    // Micronutrients (optional, may not be available for all products)
    var vitaminA: Double?      // mcg
    var vitaminC: Double?      // mg
    var vitaminD: Double?      // mcg
    var vitaminE: Double?      // mg
    var vitaminK: Double?      // mcg
    var thiamin: Double?       // mg (Vitamin B1)
    var riboflavin: Double?    // mg (Vitamin B2)
    var niacin: Double?        // mg (Vitamin B3)
    var vitaminB6: Double?     // mg
    var folate: Double?        // mcg (Vitamin B9)
    var vitaminB12: Double?    // mcg
    var calcium: Double?       // mg
    var iron: Double?          // mg
    var magnesium: Double?     // mg
    var phosphorus: Double?    // mg
    var potassium: Double?     // mg
    var zinc: Double?          // mg

    init(
        calories: Double = 0,
        protein: Double = 0,
        carbohydrates: Double = 0,
        fat: Double = 0,
        saturatedFat: Double = 0,
        fiber: Double = 0,
        sugar: Double = 0,
        sodium: Double = 0,
        cholesterol: Double = 0,
        servingSize: String = "100g",
        labelServingSize: String? = nil,
        vitaminA: Double? = nil,
        vitaminC: Double? = nil,
        vitaminD: Double? = nil,
        vitaminE: Double? = nil,
        vitaminK: Double? = nil,
        thiamin: Double? = nil,
        riboflavin: Double? = nil,
        niacin: Double? = nil,
        vitaminB6: Double? = nil,
        folate: Double? = nil,
        vitaminB12: Double? = nil,
        calcium: Double? = nil,
        iron: Double? = nil,
        magnesium: Double? = nil,
        phosphorus: Double? = nil,
        potassium: Double? = nil,
        zinc: Double? = nil,
        availability: DataAvailability? = nil
    ) {
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.saturatedFat = saturatedFat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.cholesterol = cholesterol
        self.servingSize = servingSize
        self.labelServingSize = labelServingSize
        self.vitaminA = vitaminA
        self.vitaminC = vitaminC
        self.vitaminD = vitaminD
        self.vitaminE = vitaminE
        self.vitaminK = vitaminK
        self.thiamin = thiamin
        self.riboflavin = riboflavin
        self.niacin = niacin
        self.vitaminB6 = vitaminB6
        self.folate = folate
        self.vitaminB12 = vitaminB12
        self.calcium = calcium
        self.iron = iron
        self.magnesium = magnesium
        self.phosphorus = phosphorus
        self.potassium = potassium
        self.zinc = zinc
        self.availability = availability
    }

    enum CodingKeys: String, CodingKey {
        case calories
        case protein
        case carbohydrates
        case fat
        case saturatedFat
        case fiber
        case sugar
        case sodium
        case cholesterol
        case servingSize
        case labelServingSize
        case availability
        case vitaminA
        case vitaminC
        case vitaminD
        case vitaminE
        case vitaminK
        case thiamin
        case riboflavin
        case niacin
        case vitaminB6
        case folate
        case vitaminB12
        case calcium
        case iron
        case magnesium
        case phosphorus
        case potassium
        case zinc
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        calories = try container.decodeIfPresent(Double.self, forKey: .calories) ?? 0
        protein = try container.decodeIfPresent(Double.self, forKey: .protein) ?? 0
        carbohydrates = try container.decodeIfPresent(Double.self, forKey: .carbohydrates) ?? 0
        fat = try container.decodeIfPresent(Double.self, forKey: .fat) ?? 0
        saturatedFat = try container.decodeIfPresent(Double.self, forKey: .saturatedFat) ?? 0
        fiber = try container.decodeIfPresent(Double.self, forKey: .fiber) ?? 0
        sugar = try container.decodeIfPresent(Double.self, forKey: .sugar) ?? 0
        sodium = try container.decodeIfPresent(Double.self, forKey: .sodium) ?? 0
        cholesterol = try container.decodeIfPresent(Double.self, forKey: .cholesterol) ?? 0
        servingSize = try container.decodeIfPresent(String.self, forKey: .servingSize) ?? "100g"
        labelServingSize = try container.decodeIfPresent(String.self, forKey: .labelServingSize)
        availability = try container.decodeIfPresent(DataAvailability.self, forKey: .availability)
        vitaminA = try container.decodeIfPresent(Double.self, forKey: .vitaminA)
        vitaminC = try container.decodeIfPresent(Double.self, forKey: .vitaminC)
        vitaminD = try container.decodeIfPresent(Double.self, forKey: .vitaminD)
        vitaminE = try container.decodeIfPresent(Double.self, forKey: .vitaminE)
        vitaminK = try container.decodeIfPresent(Double.self, forKey: .vitaminK)
        thiamin = try container.decodeIfPresent(Double.self, forKey: .thiamin)
        riboflavin = try container.decodeIfPresent(Double.self, forKey: .riboflavin)
        niacin = try container.decodeIfPresent(Double.self, forKey: .niacin)
        vitaminB6 = try container.decodeIfPresent(Double.self, forKey: .vitaminB6)
        folate = try container.decodeIfPresent(Double.self, forKey: .folate)
        vitaminB12 = try container.decodeIfPresent(Double.self, forKey: .vitaminB12)
        calcium = try container.decodeIfPresent(Double.self, forKey: .calcium)
        iron = try container.decodeIfPresent(Double.self, forKey: .iron)
        magnesium = try container.decodeIfPresent(Double.self, forKey: .magnesium)
        phosphorus = try container.decodeIfPresent(Double.self, forKey: .phosphorus)
        potassium = try container.decodeIfPresent(Double.self, forKey: .potassium)
        zinc = try container.decodeIfPresent(Double.self, forKey: .zinc)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(calories, forKey: .calories)
        try container.encode(protein, forKey: .protein)
        try container.encode(carbohydrates, forKey: .carbohydrates)
        try container.encode(fat, forKey: .fat)
        try container.encode(saturatedFat, forKey: .saturatedFat)
        try container.encode(fiber, forKey: .fiber)
        try container.encode(sugar, forKey: .sugar)
        try container.encode(sodium, forKey: .sodium)
        try container.encode(cholesterol, forKey: .cholesterol)
        try container.encode(servingSize, forKey: .servingSize)
        try container.encodeIfPresent(labelServingSize, forKey: .labelServingSize)
        try container.encodeIfPresent(availability, forKey: .availability)
        try container.encodeIfPresent(vitaminA, forKey: .vitaminA)
        try container.encodeIfPresent(vitaminC, forKey: .vitaminC)
        try container.encodeIfPresent(vitaminD, forKey: .vitaminD)
        try container.encodeIfPresent(vitaminE, forKey: .vitaminE)
        try container.encodeIfPresent(vitaminK, forKey: .vitaminK)
        try container.encodeIfPresent(thiamin, forKey: .thiamin)
        try container.encodeIfPresent(riboflavin, forKey: .riboflavin)
        try container.encodeIfPresent(niacin, forKey: .niacin)
        try container.encodeIfPresent(vitaminB6, forKey: .vitaminB6)
        try container.encodeIfPresent(folate, forKey: .folate)
        try container.encodeIfPresent(vitaminB12, forKey: .vitaminB12)
        try container.encodeIfPresent(calcium, forKey: .calcium)
        try container.encodeIfPresent(iron, forKey: .iron)
        try container.encodeIfPresent(magnesium, forKey: .magnesium)
        try container.encodeIfPresent(phosphorus, forKey: .phosphorus)
        try container.encodeIfPresent(potassium, forKey: .potassium)
        try container.encodeIfPresent(zinc, forKey: .zinc)
    }
}

/// Indicates what nutrition data is available for a product
struct DataAvailability: Codable {
    var hasMacros: Bool = false
    var hasMicronutrients: Bool = false
    var hasIngredients: Bool = false
}

// MARK: - Nutrient Availability (for scoring)

/// OptionSet representing which nutrient data points are available
struct NutrientAvailability: OptionSet, Codable {
    let rawValue: Int

    static let energy = NutrientAvailability(rawValue: 1 << 0)
    static let sugar = NutrientAvailability(rawValue: 1 << 1)
    static let saturatedFat = NutrientAvailability(rawValue: 1 << 2)
    static let sodium = NutrientAvailability(rawValue: 1 << 3)
    static let fiber = NutrientAvailability(rawValue: 1 << 4)
    static let protein = NutrientAvailability(rawValue: 1 << 5)
    static let fruitVeg = NutrientAvailability(rawValue: 1 << 6)

    static let all: NutrientAvailability = [.energy, .sugar, .saturatedFat, .sodium, .fiber, .protein, .fruitVeg]
}

// MARK: - Fruit/Veg Estimation

/// Estimation of fruit, vegetable, legume, and nut content
struct FruitVegEstimate: Codable {
    let percentage: Double?
    let method: EstimationMethod

    enum EstimationMethod: String, Codable {
        case explicitPercentage
        case singleIngredientProduce
        case primaryIngredientHeuristic
        case presenceHeuristic
        case unknown
    }

    static var unknown: FruitVegEstimate {
        FruitVegEstimate(percentage: nil, method: .unknown)
    }
}

/// Service for estimating fruit/veg content from ingredients
final class FruitVegLegumeNutEstimator {
    static let shared = FruitVegLegumeNutEstimator()

    private init() {}

    func estimate(ingredients: [String], rawText: String?, categorySlug: String?) -> FruitVegEstimate {
        // Check for single-ingredient produce
        if ingredients.count == 1 {
            let ingredient = ingredients[0].lowercased()
            if isSingleIngredientProduce(ingredient) {
                return FruitVegEstimate(percentage: 100, method: .singleIngredientProduce)
            }
        }

        // Check for explicit percentage in raw text (e.g., "40% fruit")
        if let rawText = rawText,
           let percentage = extractExplicitPercentage(from: rawText) {
            return FruitVegEstimate(percentage: percentage, method: .explicitPercentage)
        }

        // Heuristic based on primary ingredient
        if let firstIngredient = ingredients.first?.lowercased(),
           isProduceIngredient(firstIngredient) {
            return FruitVegEstimate(percentage: 60, method: .primaryIngredientHeuristic)
        }

        // Heuristic based on presence of produce ingredients
        let produceCount = ingredients.filter { isProduceIngredient($0.lowercased()) }.count
        if produceCount > 0 {
            let estimatedPercentage = min(Double(produceCount) * 15, 50)
            return FruitVegEstimate(percentage: estimatedPercentage, method: .presenceHeuristic)
        }

        return .unknown
    }

    private func isSingleIngredientProduce(_ ingredient: String) -> Bool {
        let produce = ["apple", "banana", "orange", "spinach", "broccoli", "carrot", "tomato",
                       "potato", "onion", "garlic", "lemon", "lime", "avocado", "blueberry",
                       "strawberry", "raspberry", "grape", "pear", "peach", "mango", "pineapple"]
        return produce.contains(where: { ingredient.contains($0) })
    }

    private func isProduceIngredient(_ ingredient: String) -> Bool {
        let produceTerms = ["fruit", "vegetable", "apple", "banana", "orange", "spinach",
                           "broccoli", "carrot", "tomato", "potato", "onion", "garlic",
                           "legume", "bean", "lentil", "chickpea", "nut", "almond", "walnut",
                           "peanut", "cashew", "pecan", "pistachio"]
        return produceTerms.contains(where: { ingredient.contains($0) })
    }

    private func extractExplicitPercentage(from text: String) -> Double? {
        let pattern = "(\\d+(?:\\.\\d+)?)\\s*%\\s*(fruit|vegetable|veg|produce|legume|nut)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        if let match = regex.firstMatch(in: text, options: [], range: range),
           match.numberOfRanges > 1,
           let matchRange = Range(match.range(at: 1), in: text) {
            return Double(String(text[matchRange]))
        }
        return nil
    }
}

// MARK: - Health Focus
enum HealthFocus: String, CaseIterable, Codable {
    case gutHealth = "gut_health"
    case weightLoss = "weight_loss"
    case proteinFocus = "protein_focus"
    case heartHealth = "heart_health"
    case generalWellness = "general_wellness"

    var displayName: String {
        switch self {
        case .gutHealth:
            return "Gut Health"
        case .weightLoss:
            return "Weight Loss"
        case .proteinFocus:
            return "Protein Focus"
        case .heartHealth:
            return "Heart Health"
        case .generalWellness:
            return "General Wellness"
        }
    }

    var icon: String {
        switch self {
        case .gutHealth:
            return "🦠"
        case .weightLoss:
            return "⚖️"
        case .proteinFocus:
            return "💪"
        case .heartHealth:
            return "🫀"
        case .generalWellness:
            return "✨"
        }
    }

    /// Initialize from a stored string, handling both camelCase and snake_case formats.
    /// Falls back to `.generalWellness` if the string doesn't match any known focus.
    init(fromStored string: String) {
        if let focus = HealthFocus(rawValue: string) {
            self = focus
            return
        }
        switch string {
        case "gutHealth": self = .gutHealth
        case "weightLoss": self = .weightLoss
        case "proteinFocus": self = .proteinFocus
        case "heartHealth": self = .heartHealth
        case "generalWellness": self = .generalWellness
        default: self = .generalWellness
        }
    }

    var detailDescription: String {
        switch self {
        case .gutHealth:
            return "Supports digestion with fiber-rich, microbiome-friendly foods."
        case .weightLoss:
            return "Prioritizes lower calories, balanced macros, and satiating fiber."
        case .heartHealth:
            return "Optimized for cardiovascular health. Prioritizes low cholesterol, high fiber, and heart-healthy fats."
        case .proteinFocus:
            return "Highlights higher-protein choices to build and maintain lean muscle."
        case .generalWellness:
            return "Balanced guidance for everyday healthy habits across nutrients."
        }
    }
}

// MARK: - Dietary Restrictions
enum DietaryRestriction: String, CaseIterable, Codable {
    case vegan = "vegan"
    case vegetarian = "vegetarian"
    case glutenFree = "gluten_free"
    case dairyFree = "dairy_free"
    case nutFree = "nut_free"
    case lowSodium = "low_sodium"
    case sugarFree = "sugar_free"

    var displayName: String {
        switch self {
        case .vegan:
            return "Vegan"
        case .vegetarian:
            return "Vegetarian"
        case .glutenFree:
            return "Gluten-Free"
        case .dairyFree:
            return "Dairy-Free"
        case .nutFree:
            return "Nut-Free"
        case .lowSodium:
            return "Low Sodium"
        case .sugarFree:
            return "Sugar-Free"
        }
    }

    /// Convert a Set of stored strings into an array of DietaryRestriction.
    static func fromStrings(_ strings: Set<String>) -> [DietaryRestriction] {
        strings.compactMap { DietaryRestriction(from: $0) }
    }

    /// Parse a comma-separated stored string into an array of DietaryRestriction.
    static func fromCommaSeparated(_ stored: String?) -> [DietaryRestriction] {
        guard let stored, !stored.isEmpty else { return [] }
        return stored.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .compactMap { DietaryRestriction(from: $0) }
    }
}

// MARK: - Extensions
extension APIProduct {
    var servingSizeInGrams: Double? {
        guard !servingSizeUnit.isEmpty else { return servingSize }
        return servingSizeUnit.lowercased().hasPrefix("g") ? servingSize : nil
    }

    var displayServingSize: String {
        if let size = servingSize {
            return "\(size.formatted(.number.precision(.fractionLength(0...1)))) \(servingSizeUnit)"
        }
        return "100\(servingSizeUnit)"
    }

    var macronutrientTotal: Double {
        return nutritionalData.protein + nutritionalData.carbohydrates + nutritionalData.fat
    }

    var proteinPercentage: Double {
        guard macronutrientTotal > 0 else { return 0 }
        return (nutritionalData.protein / macronutrientTotal) * 100
    }

    var carbsPercentage: Double {
        guard macronutrientTotal > 0 else { return 0 }
        return (nutritionalData.carbohydrates / macronutrientTotal) * 100
    }

    var fatPercentage: Double {
        guard macronutrientTotal > 0 else { return 0 }
        return (nutritionalData.fat / macronutrientTotal) * 100
    }
}

extension NutritionalData {
    func scaled(by multiplier: Double) -> NutritionalData {
        guard multiplier > 0 else { return self }
        if multiplier == 1 { return self }

        return NutritionalData(
            calories: calories * multiplier,
            protein: protein * multiplier,
            carbohydrates: carbohydrates * multiplier,
            fat: fat * multiplier,
            fiber: fiber * multiplier,
            sugar: sugar * multiplier,
            sodium: sodium * multiplier,
            cholesterol: cholesterol * multiplier
        )
    }

    var totalMacros: Double {
        return protein + carbohydrates + fat
    }

    var caloriesFromMacros: Double {
        return (protein * 4) + (carbohydrates * 4) + (fat * 9)
    }

    var isComplete: Bool {
        return calories > 0 ||
            protein > 0 ||
            carbohydrates > 0 ||
            fat > 0 ||
            fiber > 0 ||
            sugar > 0 ||
            sodium > 0 ||
            cholesterol > 0
    }
}

// Ensure UI models can also be checked for completeness
extension ProductNutrition {
    var isComplete: Bool {
        return calories > 0 ||
            protein > 0 ||
            carbohydrates > 0 ||
            fat > 0 ||
            fiber > 0 ||
            sugar > 0 ||
            sodium > 0 ||
            cholesterol > 0
    }
}
