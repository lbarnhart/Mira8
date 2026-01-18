import Foundation

struct GuardrailCap: Codable, Equatable {
    let ruleID: String
    let tier: GuardrailTier
    let reason: String
}

struct ScoringResult {
    let productID: UUID
    let algorithmVersion: String
    let weightsProfileID: String
    let thresholdSetID: String
    let rawScore: Double
    let tier: ScoreTier
    let grade: ScoreGrade
    let topReasons: [String]
    let categoryLabel: String
    let lensApplied: Bool
    let capsApplied: [GuardrailCap]
    let pillarsDropped: [PillarID]
    let missingFields: [String]
    let dataConfidence: NutritionDataConfidence
    let notes: [String]
    let isConfidentCategoryClassification: Bool
    let suggestedSwapCategories: [String]
}
