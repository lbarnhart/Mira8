import Foundation

enum NutritionDataConfidence: String, Codable {
    case high
    case medium
    case low
}

enum NormalizationNote: String, Codable {
    case derivedFromLabelMass = "derived_from_label_mass"
    case derivedFromLabelVolume = "derived_from_label_volume"
    case fallbackPerServing = "fallback_per_serving"
    case beverageVolumeMissing = "beverage_volume_missing"
    case householdMeasureNoDensity = "household_measure_no_density"
    case assumedWaterDensity = "assumed_water_density"
}

struct NormalizedServing: Codable, Equatable {
    enum Basis: String, Codable {
        case per100g
        case per100ml
        case perServing
    }

    let basis: Basis
    let massInGrams: Double?
    let volumeInMilliliters: Double?
    let labelText: String?
    var massOrVolumeMissing: Bool
}

struct NutritionDensity: Codable, Equatable {
    struct Snapshot: Codable, Equatable {
        let calories: Double?
        let protein: Double?
        let carbohydrates: Double?
        let fat: Double?
        let saturatedFat: Double?
        let fiber: Double?
        let sugar: Double?
        let sodium: Double?
        let cholesterol: Double?
    }

    enum DensityMetric: String, Codable {
        case per100g
        case per100ml
        case perServing
    }

    enum MissingField: String, Codable {
        case servingMass
        case servingVolume
        case servingDescription
    }

    let per100g: Snapshot?
    let per100ml: Snapshot?
    let perServing: Snapshot
    let dataConfidence: NutritionDataConfidence
    let missingFields: [MissingField]
    let notes: [NormalizationNote]
    let availableMetrics: [DensityMetric]
    let skippedMetrics: [DensityMetric]
}

enum AdditiveRiskLevel: String, Codable {
    case supportive
    case expected
    case elevated
    case unknown
}

struct AdditiveHit: Codable, Equatable {
    let originalName: String
    let displayName: String
    let normalizedName: String
    let lexiconIdentifier: String?
    let riskLevel: AdditiveRiskLevel
}

struct IngredientHit: Codable, Equatable {
    let originalName: String
    let normalizedName: String
    let category: IngredientCategory
    let position: Int
}

struct NormalizedProduct {
    let input: ScoringInput

    var product: ProductModel { input.product }
    var categorySlug: String? { input.product.categorySlug }
    var ingredientHits: [IngredientHit] { input.ingredientHits }
    var additiveHits: [AdditiveHit] { input.additiveHits }
    var ingredientMatchResult: IngredientMatchResult { input.ingredientMatchResult }
    var density: NutritionDensity { input.density }
    var normalizedServing: NormalizedServing { input.normalizedServing }
    var isBeverage: Bool { input.isBeverage }
}
