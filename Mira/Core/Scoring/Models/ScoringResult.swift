import Foundation

struct GuardrailCap: Codable, Equatable {
    let ruleID: String
    let tier: GuardrailTier
    let reason: String
}

/// Score tier representing quality level
enum ScoreTier: String, Codable {
    case excellent
    case good
    case fair
    case poor
    case insufficientData
}

/// Letter grade for the score
enum ScoreGrade: String, Codable {
    case aPlus = "A+"
    case a = "A"
    case aMinus = "A-"
    case bPlus = "B+"
    case b = "B"
    case bMinus = "B-"
    case cPlus = "C+"
    case c = "C"
    case cMinus = "C-"
    case d = "D"
    case f = "F"

    init(score: Double) {
        switch score {
        case 97...100: self = .aPlus
        case 93..<97: self = .a
        case 90..<93: self = .aMinus
        case 87..<90: self = .bPlus
        case 83..<87: self = .b
        case 80..<83: self = .bMinus
        case 77..<80: self = .cPlus
        case 73..<77: self = .c
        case 70..<73: self = .cMinus
        case 60..<70: self = .d
        default: self = .f
        }
    }
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
