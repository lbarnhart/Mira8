import Foundation

struct DietaryRestrictionResult: Identifiable {
    let id = UUID()
    let restriction: String
    let passes: Bool?
    let reason: String
}

struct DietaryRestrictionChecker {
    static func checkRestrictions(
        for product: ProductModel,
        restrictions: Set<String>
    ) -> [DietaryRestrictionResult] {
        let activeRestrictionIds = restrictions.filter { identifier in
            let normalized = DietaryRestrictionType.normalize(identifier)
            return !normalized.isEmpty && normalized != "none"
        }

        guard !activeRestrictionIds.isEmpty else { return [] }

        let mappedRestrictions = DietaryRestrictionType.allCases.filter { type in
            activeRestrictionIds.contains(where: { type.matches($0) })
        }

        if mappedRestrictions.isEmpty {
            return []
        }

        guard let ingredientsContext = IngredientsContext(product: product) else {
            return mappedRestrictions.map { type in
                DietaryRestrictionResult(
                    restriction: type.displayName,
                    passes: nil,
                    reason: "Ingredient data not available"
                )
            }
        }

        return mappedRestrictions.map { type in
            switch type {
            case .vegan:
                return checkVegan(context: ingredientsContext)
            case .vegetarian:
                return checkVegetarian(context: ingredientsContext)
            case .glutenFree:
                return checkGlutenFree(context: ingredientsContext)
            case .dairyFree:
                return checkDairyFree(context: ingredientsContext)
            case .nutFree:
                return checkNutFree(context: ingredientsContext)
            }
        }
    }

    private static func checkVegan(context: IngredientsContext) -> DietaryRestrictionResult {
        let restrictionName = DietaryRestrictionType.vegan.displayName

        for keyword in KeywordSets.veganRestricted {
            if context.contains(keyword) {
                return DietaryRestrictionResult(
                    restriction: restrictionName,
                    passes: false,
                    reason: "Contains \(keyword.displayName)"
                )
            }
        }

        if context.containsAmbiguousVeganIngredients {
            return DietaryRestrictionResult(
                restriction: restrictionName,
                passes: nil,
                reason: "Ambiguous ingredient detected (natural flavors)"
            )
        }

        return DietaryRestrictionResult(
            restriction: restrictionName,
            passes: true,
            reason: "No animal-derived ingredients detected"
        )
    }

    private static func checkVegetarian(context: IngredientsContext) -> DietaryRestrictionResult {
        let restrictionName = DietaryRestrictionType.vegetarian.displayName

        for keyword in KeywordSets.vegetarianRestricted {
            if context.contains(keyword) {
                return DietaryRestrictionResult(
                    restriction: restrictionName,
                    passes: false,
                    reason: "Contains \(keyword.displayName)"
                )
            }
        }

        return DietaryRestrictionResult(
            restriction: restrictionName,
            passes: true,
            reason: "No meat or fish ingredients detected"
        )
    }

    private static func checkGlutenFree(context: IngredientsContext) -> DietaryRestrictionResult {
        let restrictionName = DietaryRestrictionType.glutenFree.displayName

        if context.containsGlutenFlour {
            return DietaryRestrictionResult(
                restriction: restrictionName,
                passes: false,
                reason: "Contains flour (likely wheat)"
            )
        }

        for keyword in KeywordSets.glutenRestricted {
            if context.contains(keyword) {
                return DietaryRestrictionResult(
                    restriction: restrictionName,
                    passes: false,
                    reason: "Contains \(keyword.displayName)"
                )
            }
        }

        return DietaryRestrictionResult(
            restriction: restrictionName,
            passes: true,
            reason: "No gluten-containing ingredients detected"
        )
    }

    private static func checkDairyFree(context: IngredientsContext) -> DietaryRestrictionResult {
        let restrictionName = DietaryRestrictionType.dairyFree.displayName

        for keyword in KeywordSets.dairyRestricted {
            if context.contains(keyword) {
                return DietaryRestrictionResult(
                    restriction: restrictionName,
                    passes: false,
                    reason: "Contains \(keyword.displayName)"
                )
            }
        }

        return DietaryRestrictionResult(
            restriction: restrictionName,
            passes: true,
            reason: "No dairy ingredients detected"
        )
    }

    private static func checkNutFree(context: IngredientsContext) -> DietaryRestrictionResult {
        let restrictionName = DietaryRestrictionType.nutFree.displayName

        if context.containsNutAdvisory {
            return DietaryRestrictionResult(
                restriction: restrictionName,
                passes: false,
                reason: "Warning label indicates possible nut content"
            )
        }

        for keyword in KeywordSets.nutRestricted {
            if context.contains(keyword) {
                return DietaryRestrictionResult(
                    restriction: restrictionName,
                    passes: false,
                    reason: "Contains \(keyword.displayName)"
                )
            }
        }

        return DietaryRestrictionResult(
            restriction: restrictionName,
            passes: true,
            reason: "No nut ingredients detected"
        )
    }
}

// MARK: - Support Types
private enum DietaryRestrictionType: CaseIterable {
    case vegan
    case vegetarian
    case glutenFree
    case dairyFree
    case nutFree

    init?(rawValue: String) {
        guard let match = DietaryRestrictionType.allCases.first(where: { $0.matches(rawValue) }) else {
            return nil
        }
        self = match
    }

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
        }
    }

    func matches(_ rawValue: String) -> Bool {
        DietaryRestrictionType.normalize(rawValue) == normalizedKey
    }

    var normalizedKey: String {
        switch self {
        case .vegan:
            return "vegan"
        case .vegetarian:
            return "vegetarian"
        case .glutenFree:
            return "glutenfree"
        case .dairyFree:
            return "dairyfree"
        case .nutFree:
            return "nutfree"
        }
    }

    static func normalize(_ rawValue: String) -> String {
        rawValue
            .lowercased()
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
    }
}

private struct Keyword: Hashable {
    let rawValue: String

    var displayName: String {
        rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: " ")
            .capitalized
    }
}

private enum KeywordSets {
    static let veganRestricted: [Keyword] = [
        Keyword(rawValue: "milk"),
        Keyword(rawValue: "dairy"),
        Keyword(rawValue: "cream"),
        Keyword(rawValue: "butter"),
        Keyword(rawValue: "cheese"),
        Keyword(rawValue: "whey"),
        Keyword(rawValue: "casein"),
        Keyword(rawValue: "lactose"),
        Keyword(rawValue: "egg"),
        Keyword(rawValue: "egg white"),
        Keyword(rawValue: "egg whites"),
        Keyword(rawValue: "albumin"),
        Keyword(rawValue: "honey"),
        Keyword(rawValue: "gelatin"),
        Keyword(rawValue: "lard"),
        Keyword(rawValue: "tallow"),
        Keyword(rawValue: "animal fat")
    ]

    static let vegetarianRestricted: [Keyword] = [
        Keyword(rawValue: "chicken"),
        Keyword(rawValue: "beef"),
        Keyword(rawValue: "pork"),
        Keyword(rawValue: "meat"),
        Keyword(rawValue: "fish"),
        Keyword(rawValue: "salmon"),
        Keyword(rawValue: "tuna"),
        Keyword(rawValue: "anchovy"),
        Keyword(rawValue: "gelatin"),
        Keyword(rawValue: "lard"),
        Keyword(rawValue: "animal fat"),
        Keyword(rawValue: "seafood"),
        Keyword(rawValue: "bacon"),
        Keyword(rawValue: "pepperoni"),
        Keyword(rawValue: "sausage"),
        Keyword(rawValue: "chorizo")
    ]

    static let glutenRestricted: [Keyword] = [
        Keyword(rawValue: "wheat"),
        Keyword(rawValue: "barley"),
        Keyword(rawValue: "rye"),
        Keyword(rawValue: "malt"),
        Keyword(rawValue: "triticale"),
        Keyword(rawValue: "semolina"),
        Keyword(rawValue: "durum"),
        Keyword(rawValue: "spelt"),
        Keyword(rawValue: "farina"),
        Keyword(rawValue: "farro")
    ]

    static let dairyRestricted: [Keyword] = [
        Keyword(rawValue: "milk"),
        Keyword(rawValue: "dairy"),
        Keyword(rawValue: "cream"),
        Keyword(rawValue: "butter"),
        Keyword(rawValue: "cheese"),
        Keyword(rawValue: "whey"),
        Keyword(rawValue: "casein"),
        Keyword(rawValue: "lactose"),
        Keyword(rawValue: "yogurt"),
        Keyword(rawValue: "ghee"),
        Keyword(rawValue: "milk powder")
    ]

    static let nutRestricted: [Keyword] = [
        Keyword(rawValue: "peanut"),
        Keyword(rawValue: "peanuts"),
        Keyword(rawValue: "almond"),
        Keyword(rawValue: "almonds"),
        Keyword(rawValue: "cashew"),
        Keyword(rawValue: "cashews"),
        Keyword(rawValue: "walnut"),
        Keyword(rawValue: "walnuts"),
        Keyword(rawValue: "pecan"),
        Keyword(rawValue: "pecans"),
        Keyword(rawValue: "hazelnut"),
        Keyword(rawValue: "hazelnuts"),
        Keyword(rawValue: "pistachio"),
        Keyword(rawValue: "pistachios"),
        Keyword(rawValue: "macadamia"),
        Keyword(rawValue: "macadamias"),
        Keyword(rawValue: "pine nut"),
        Keyword(rawValue: "pine nuts"),
        Keyword(rawValue: "nut"),
        Keyword(rawValue: "nuts"),
        Keyword(rawValue: "nut butter"),
        Keyword(rawValue: "nut oil"),
        Keyword(rawValue: "marzipan"),
        Keyword(rawValue: "praline")
    ]
}

private struct IngredientsContext {
    let normalized: String
    let original: String

    init?(product: ProductModel) {
        let rawString: String?

        if let raw = product.rawIngredientsText, !raw.isEmpty {
            rawString = raw
        } else if !product.ingredients.isEmpty {
            rawString = product.ingredients.joined(separator: ", ")
        } else {
            rawString = nil
        }

        guard let rawString, !rawString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        original = rawString.lowercased()
        normalized = IngredientsContext.normalize(rawString)
    }

    func contains(_ keyword: Keyword) -> Bool {
        return contains(keyword.rawValue)
    }

    func contains(_ keyword: String) -> Bool {
        let normalizedKeyword = IngredientsContext.normalize(keyword)
        guard !normalizedKeyword.isEmpty else { return false }

        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: normalizedKeyword))\\b"
        return normalized.range(of: pattern, options: [.regularExpression]) != nil
    }

    var containsGlutenFlour: Bool {
        guard contains("flour") else { return false }

        let safeFlours = [
            "rice flour",
            "corn flour",
            "almond flour"
        ]

        if safeFlours.contains(where: { contains($0) }) {
            // If both safe and unsafe flours are present, the gluten keywords will catch the unsafe one
            // Skip marking as violation solely based on flour when safe alternatives are noted
            return false
        }

        return true
    }

    var containsAmbiguousVeganIngredients: Bool {
        contains("natural flavors") || contains("natural flavor")
    }

    var containsNutAdvisory: Bool {
        let advisoryPatterns = [
            "may contain nut",
            "may contain nuts",
            "may contain tree nut",
            "may contain tree nuts",
            "processed in a facility that also processes nut",
            "processed in a facility that also processes nuts",
            "processed in a facility that also processes peanut",
            "processed in a facility that also processes peanuts"
        ]

        if advisoryPatterns.contains(where: { original.contains($0) }) {
            return true
        }

        let regexPattern = "may\\s+contain\\s+[a-z\\s]*(nut|peanut|almond|cashew|walnut|pecan|hazelnut|pistachio|macadamia)s?"
        return original.range(of: regexPattern, options: [.regularExpression]) != nil
    }

    static func normalize(_ string: String) -> String {
        let lowercased = string
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        let punctuationCleaned = lowercased.replacingOccurrences(
            of: "[^a-z0-9\n]+",
            with: " ",
            options: [.regularExpression]
        )

        return punctuationCleaned
            .replacingOccurrences(of: "\\s+", with: " ", options: [.regularExpression])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
