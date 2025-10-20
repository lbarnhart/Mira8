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
        processingLevel: ProcessingLevel? = nil
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
    }
}

// MARK: - Nutritional Data
struct NutritionalData: Codable {
    var calories: Double
    var protein: Double
    var carbohydrates: Double
    var fat: Double
    var fiber: Double
    var sugar: Double
    var sodium: Double
    var cholesterol: Double

    init(
        calories: Double = 0,
        protein: Double = 0,
        carbohydrates: Double = 0,
        fat: Double = 0,
        fiber: Double = 0,
        sugar: Double = 0,
        sodium: Double = 0,
        cholesterol: Double = 0
    ) {
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.cholesterol = cholesterol
    }

    enum CodingKeys: String, CodingKey {
        case calories
        case protein
        case carbohydrates
        case fat
        case fiber
        case sugar
        case sodium
        case cholesterol
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        calories = try container.decodeIfPresent(Double.self, forKey: .calories) ?? 0
        protein = try container.decodeIfPresent(Double.self, forKey: .protein) ?? 0
        carbohydrates = try container.decodeIfPresent(Double.self, forKey: .carbohydrates) ?? 0
        fat = try container.decodeIfPresent(Double.self, forKey: .fat) ?? 0
        fiber = try container.decodeIfPresent(Double.self, forKey: .fiber) ?? 0
        sugar = try container.decodeIfPresent(Double.self, forKey: .sugar) ?? 0
        sodium = try container.decodeIfPresent(Double.self, forKey: .sodium) ?? 0
        cholesterol = try container.decodeIfPresent(Double.self, forKey: .cholesterol) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(calories, forKey: .calories)
        try container.encode(protein, forKey: .protein)
        try container.encode(carbohydrates, forKey: .carbohydrates)
        try container.encode(fat, forKey: .fat)
        try container.encode(fiber, forKey: .fiber)
        try container.encode(sugar, forKey: .sugar)
        try container.encode(sodium, forKey: .sodium)
        try container.encode(cholesterol, forKey: .cholesterol)
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
}

struct ProductNutrition: Codable {
    var calories: Double
    var protein: Double
    var carbohydrates: Double
    var fat: Double
    var fiber: Double
    var sugar: Double
    var sodium: Double
    var cholesterol: Double
    var servingSize: String

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
        fiber: Double = 0,
        sugar: Double = 0,
        sodium: Double = 0,
        cholesterol: Double = 0,
        servingSize: String = "100g",
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
        zinc: Double? = nil
    ) {
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.cholesterol = cholesterol
        self.servingSize = servingSize
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
    }

    enum CodingKeys: String, CodingKey {
        case calories
        case protein
        case carbohydrates
        case fat
        case fiber
        case sugar
        case sodium
        case cholesterol
        case servingSize
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
        fiber = try container.decodeIfPresent(Double.self, forKey: .fiber) ?? 0
        sugar = try container.decodeIfPresent(Double.self, forKey: .sugar) ?? 0
        sodium = try container.decodeIfPresent(Double.self, forKey: .sodium) ?? 0
        cholesterol = try container.decodeIfPresent(Double.self, forKey: .cholesterol) ?? 0
        servingSize = try container.decodeIfPresent(String.self, forKey: .servingSize) ?? "100g"
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
        try container.encode(fiber, forKey: .fiber)
        try container.encode(sugar, forKey: .sugar)
        try container.encode(sodium, forKey: .sodium)
        try container.encode(cholesterol, forKey: .cholesterol)
        try container.encode(servingSize, forKey: .servingSize)
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
