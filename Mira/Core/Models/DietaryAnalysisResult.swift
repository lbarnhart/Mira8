import Foundation

/// Comprehensive result model for dietary restriction analysis.
/// Supports both quick regex-based checks and AI-enhanced analysis.
struct DietaryAnalysisResult: Identifiable, Equatable {
    let id = UUID()
    let restriction: DietaryRestriction
    let status: DietaryStatus
    let confidence: ConfidenceLevel
    let violations: [DietaryViolation]
    let warnings: [DietaryWarning]
    let analysisMethod: AnalysisMethod

    /// Backward compatibility with existing code
    var passes: Bool? {
        switch status {
        case .compliant: return true
        case .violation: return false
        case .uncertain, .mayContain: return nil
        }
    }

    var reason: String {
        if let primaryViolation = violations.first {
            return primaryViolation.description
        }
        if let primaryWarning = warnings.first {
            return primaryWarning.description
        }
        switch status {
        case .compliant:
            return "No \(restriction.violationNoun) detected"
        case .violation:
            return "Contains \(restriction.violationNoun)"
        case .uncertain:
            return "Could not verify - check ingredients"
        case .mayContain:
            return "May contain \(restriction.violationNoun)"
        }
    }
}

// MARK: - DietaryRestriction Extensions
// The DietaryRestriction enum is defined in Product.swift
// These extensions add functionality needed for dietary analysis

extension DietaryRestriction {
    var violationNoun: String {
        switch self {
        case .vegan: return "animal-derived ingredients"
        case .vegetarian: return "meat or fish"
        case .glutenFree: return "gluten"
        case .dairyFree: return "dairy"
        case .nutFree: return "nuts"
        case .lowSodium: return "high sodium"
        case .sugarFree: return "sugar"
        }
    }

    var iconName: String {
        switch self {
        case .vegan: return "leaf.fill"
        case .vegetarian: return "leaf"
        case .glutenFree: return "wheat.circle.slash"
        case .dairyFree: return "drop.triangle"
        case .nutFree: return "exclamationmark.triangle"
        case .lowSodium: return "drop.circle"
        case .sugarFree: return "cube"
        }
    }

    /// Initialize from various string formats (settings, API, etc.)
    init?(from string: String) {
        let normalized = string
            .lowercased()
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")

        switch normalized {
        case "vegan": self = .vegan
        case "vegetarian": self = .vegetarian
        case "glutenfree": self = .glutenFree
        case "dairyfree": self = .dairyFree
        case "nutfree": self = .nutFree
        case "lowsodium": self = .lowSodium
        case "sugarfree": self = .sugarFree
        default: return nil
        }
    }
}

/// Status of dietary compliance
enum DietaryStatus: String, Codable, Equatable {
    case compliant      // Product meets the dietary restriction
    case violation      // Product clearly violates the restriction
    case uncertain      // Cannot determine (missing data, ambiguous ingredients)
    case mayContain     // Cross-contamination warning detected

    var color: String {
        switch self {
        case .compliant: return "green"
        case .violation: return "red"
        case .uncertain: return "gray"
        case .mayContain: return "orange"
        }
    }

    var iconName: String {
        switch self {
        case .compliant: return "checkmark.circle.fill"
        case .violation: return "xmark.circle.fill"
        case .uncertain: return "questionmark.circle.fill"
        case .mayContain: return "exclamationmark.triangle.fill"
        }
    }
}

/// Confidence level of the analysis
enum ConfidenceLevel: String, Codable, Equatable, Comparable {
    case high       // Direct match, clear violation/pass
    case medium     // Derivative match or partial data
    case low        // Ambiguous, AI uncertain, or sparse data

    var numericValue: Double {
        switch self {
        case .high: return 0.9
        case .medium: return 0.6
        case .low: return 0.3
        }
    }

    static func < (lhs: ConfidenceLevel, rhs: ConfidenceLevel) -> Bool {
        lhs.numericValue < rhs.numericValue
    }
}

/// Specific violation detected
struct DietaryViolation: Identifiable, Equatable, Codable {
    var id: String { "\(ingredient)-\(violationType.rawValue)" }
    let ingredient: String              // The ingredient that caused the violation
    let violationType: ViolationType    // Type of violation
    let isDerivative: Bool              // Is this a derivative (e.g., casein = dairy)
    let derivedFrom: String?            // Original source if derivative (e.g., "milk" for casein)
    let aiExplanation: String?          // AI-provided explanation if available

    var description: String {
        if isDerivative, let source = derivedFrom {
            return "Contains \(ingredient) (derived from \(source))"
        }
        return "Contains \(ingredient)"
    }

    enum ViolationType: String, Codable {
        case directMatch        // Exact keyword match (e.g., "milk")
        case derivativeMatch    // Derivative ingredient (e.g., "casein")
        case compositeMatch     // Part of compound ingredient (e.g., "milk chocolate")
        case aiDetected         // Detected by AI analysis
    }
}

/// Warning without definite violation
struct DietaryWarning: Identifiable, Equatable, Codable {
    var id: String { "\(warningType.rawValue)-\(detail)" }
    let warningType: WarningType
    let detail: String
    let aiExplanation: String?

    var description: String {
        switch warningType {
        case .crossContamination:
            return "May contain: \(detail)"
        case .ambiguousIngredient:
            return "Uncertain: \(detail)"
        case .missingData:
            return "Incomplete data: \(detail)"
        case .processingFacility:
            return "Processed in facility with: \(detail)"
        }
    }

    var iconName: String {
        switch warningType {
        case .crossContamination: return "exclamationmark.triangle"
        case .ambiguousIngredient: return "questionmark.circle"
        case .missingData: return "doc.questionmark"
        case .processingFacility: return "building.2"
        }
    }

    enum WarningType: String, Codable {
        case crossContamination     // "may contain nuts"
        case ambiguousIngredient    // "natural flavors"
        case missingData            // No ingredients available
        case processingFacility     // "processed in facility that..."
    }
}

/// Method used for analysis
enum AnalysisMethod: String, Codable, Equatable {
    case regexOnly      // Fast regex-based check
    case aiEnhanced     // AI analysis used
    case cached         // Result from cache
    case fallback       // Fallback due to error
}

// MARK: - Factory Methods

extension DietaryAnalysisResult {
    /// Create a compliant result
    static func compliant(
        restriction: DietaryRestriction,
        confidence: ConfidenceLevel = .high,
        method: AnalysisMethod = .regexOnly
    ) -> DietaryAnalysisResult {
        DietaryAnalysisResult(
            restriction: restriction,
            status: .compliant,
            confidence: confidence,
            violations: [],
            warnings: [],
            analysisMethod: method
        )
    }

    /// Create a violation result
    static func violation(
        restriction: DietaryRestriction,
        violations: [DietaryViolation],
        confidence: ConfidenceLevel = .high,
        method: AnalysisMethod = .regexOnly
    ) -> DietaryAnalysisResult {
        DietaryAnalysisResult(
            restriction: restriction,
            status: .violation,
            confidence: confidence,
            violations: violations,
            warnings: [],
            analysisMethod: method
        )
    }

    /// Create an uncertain result
    static func uncertain(
        restriction: DietaryRestriction,
        warnings: [DietaryWarning],
        confidence: ConfidenceLevel = .low,
        method: AnalysisMethod = .regexOnly
    ) -> DietaryAnalysisResult {
        DietaryAnalysisResult(
            restriction: restriction,
            status: .uncertain,
            confidence: confidence,
            violations: [],
            warnings: warnings,
            analysisMethod: method
        )
    }

    /// Create a may-contain result (cross-contamination)
    static func mayContain(
        restriction: DietaryRestriction,
        warnings: [DietaryWarning],
        confidence: ConfidenceLevel = .medium,
        method: AnalysisMethod = .regexOnly
    ) -> DietaryAnalysisResult {
        DietaryAnalysisResult(
            restriction: restriction,
            status: .mayContain,
            confidence: confidence,
            violations: [],
            warnings: warnings,
            analysisMethod: method
        )
    }
}
