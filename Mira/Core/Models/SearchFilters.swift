import Foundation

/// Structured search filters for natural language product search.
/// Parsed from user queries like "high protein vegan snacks under 200 calories".
struct SearchFilters: Equatable {
    // MARK: - Nutritional Filters
    var caloriesMin: Double?
    var caloriesMax: Double?
    var proteinMin: Double?
    var proteinMax: Double?
    var carbsMin: Double?
    var carbsMax: Double?
    var fatMin: Double?
    var fatMax: Double?
    var fiberMin: Double?
    var fiberMax: Double?
    var sugarMax: Double?
    var sodiumMax: Double?

    // MARK: - Dietary Filters
    var dietaryRestrictions: Set<String>

    // MARK: - Category Filters
    var categories: [String]
    var excludeCategories: [String]

    // MARK: - Text Search
    var searchTerms: [String]
    var excludeTerms: [String]

    // MARK: - Sort Options
    var sortBy: SortOption

    // MARK: - Initialization

    init(
        caloriesMin: Double? = nil,
        caloriesMax: Double? = nil,
        proteinMin: Double? = nil,
        proteinMax: Double? = nil,
        carbsMin: Double? = nil,
        carbsMax: Double? = nil,
        fatMin: Double? = nil,
        fatMax: Double? = nil,
        fiberMin: Double? = nil,
        fiberMax: Double? = nil,
        sugarMax: Double? = nil,
        sodiumMax: Double? = nil,
        dietaryRestrictions: Set<String> = [],
        categories: [String] = [],
        excludeCategories: [String] = [],
        searchTerms: [String] = [],
        excludeTerms: [String] = [],
        sortBy: SortOption = .relevance
    ) {
        self.caloriesMin = caloriesMin
        self.caloriesMax = caloriesMax
        self.proteinMin = proteinMin
        self.proteinMax = proteinMax
        self.carbsMin = carbsMin
        self.carbsMax = carbsMax
        self.fatMin = fatMin
        self.fatMax = fatMax
        self.fiberMin = fiberMin
        self.fiberMax = fiberMax
        self.sugarMax = sugarMax
        self.sodiumMax = sodiumMax
        self.dietaryRestrictions = dietaryRestrictions
        self.categories = categories
        self.excludeCategories = excludeCategories
        self.searchTerms = searchTerms
        self.excludeTerms = excludeTerms
        self.sortBy = sortBy
    }

    // MARK: - Computed Properties

    var isEmpty: Bool {
        caloriesMin == nil &&
        caloriesMax == nil &&
        proteinMin == nil &&
        proteinMax == nil &&
        carbsMin == nil &&
        carbsMax == nil &&
        fatMin == nil &&
        fatMax == nil &&
        fiberMin == nil &&
        fiberMax == nil &&
        sugarMax == nil &&
        sodiumMax == nil &&
        dietaryRestrictions.isEmpty &&
        categories.isEmpty &&
        excludeCategories.isEmpty &&
        searchTerms.isEmpty &&
        excludeTerms.isEmpty
    }

    var hasNutritionalFilters: Bool {
        caloriesMin != nil ||
        caloriesMax != nil ||
        proteinMin != nil ||
        proteinMax != nil ||
        carbsMin != nil ||
        carbsMax != nil ||
        fatMin != nil ||
        fatMax != nil ||
        fiberMin != nil ||
        fiberMax != nil ||
        sugarMax != nil ||
        sodiumMax != nil
    }

    var activeFilterCount: Int {
        var count = 0
        if caloriesMin != nil || caloriesMax != nil { count += 1 }
        if proteinMin != nil || proteinMax != nil { count += 1 }
        if carbsMin != nil || carbsMax != nil { count += 1 }
        if fatMin != nil || fatMax != nil { count += 1 }
        if fiberMin != nil || fiberMax != nil { count += 1 }
        if sugarMax != nil { count += 1 }
        if sodiumMax != nil { count += 1 }
        count += dietaryRestrictions.count
        count += categories.count
        return count
    }

    /// Human-readable description of active filters
    var filterDescription: String {
        var parts: [String] = []

        if let min = proteinMin {
            parts.append("protein ≥\(Int(min))g")
        }
        if let max = caloriesMax {
            parts.append("≤\(Int(max)) cal")
        }
        if let max = sugarMax {
            parts.append("sugar ≤\(Int(max))g")
        }
        if !dietaryRestrictions.isEmpty {
            parts.append(contentsOf: dietaryRestrictions.map { $0.capitalized })
        }
        if !categories.isEmpty {
            parts.append(contentsOf: categories)
        }

        return parts.joined(separator: ", ")
    }
}

// MARK: - Sort Options

enum SortOption: String, CaseIterable, Equatable {
    case relevance
    case healthScore
    case proteinHighToLow
    case caloriesLowToHigh
    case sugarLowToHigh

    var displayName: String {
        switch self {
        case .relevance: return "Relevance"
        case .healthScore: return "Health Score"
        case .proteinHighToLow: return "Protein (High to Low)"
        case .caloriesLowToHigh: return "Calories (Low to High)"
        case .sugarLowToHigh: return "Sugar (Low to High)"
        }
    }
}

// MARK: - Search Result

struct NLSearchResult: Identifiable, Equatable {
    let id = UUID()
    let product: ProductModel
    let healthScore: HealthScore
    let matchedFilters: [String]
    let relevanceScore: Double

    static func == (lhs: NLSearchResult, rhs: NLSearchResult) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Query Parsing Result

struct ParsedQuery: Equatable {
    let originalQuery: String
    let filters: SearchFilters
    let confidence: Double
    let interpretation: String

    /// Whether the query was successfully parsed with meaningful filters
    var wasSuccessfullyParsed: Bool {
        !filters.isEmpty && confidence > 0.3
    }
}

// MARK: - Predefined Filter Templates

extension SearchFilters {
    static let highProtein = SearchFilters(
        proteinMin: 15,
        searchTerms: []
    )

    static let lowCalorie = SearchFilters(
        caloriesMax: 150,
        searchTerms: []
    )

    static let lowSugar = SearchFilters(
        sugarMax: 5,
        searchTerms: []
    )

    static let highFiber = SearchFilters(
        fiberMin: 5,
        searchTerms: []
    )

    static func vegan(withTerms terms: [String] = []) -> SearchFilters {
        SearchFilters(
            dietaryRestrictions: ["vegan"],
            searchTerms: terms
        )
    }

    static func glutenFree(withTerms terms: [String] = []) -> SearchFilters {
        SearchFilters(
            dietaryRestrictions: ["gluten_free"],
            searchTerms: terms
        )
    }
}

// MARK: - Category Mappings

extension SearchFilters {
    /// Common category aliases to Open Food Facts categories
    static let categoryMappings: [String: [String]] = [
        "snack": ["snacks", "chips", "crackers", "nuts", "trail-mix"],
        "snacks": ["snacks", "chips", "crackers", "nuts", "trail-mix"],
        "breakfast": ["breakfast-cereals", "cereals", "oatmeal", "granola", "breakfast"],
        "cereal": ["breakfast-cereals", "cereals"],
        "cereals": ["breakfast-cereals", "cereals"],
        "drink": ["beverages", "drinks", "juices", "sodas"],
        "drinks": ["beverages", "drinks", "juices", "sodas"],
        "beverage": ["beverages", "drinks", "juices"],
        "beverages": ["beverages", "drinks", "juices"],
        "dairy": ["dairy", "milk", "cheese", "yogurt"],
        "yogurt": ["yogurt", "yogurts"],
        "bread": ["breads", "bread"],
        "protein": ["protein-bars", "protein", "protein-powder"],
        "bar": ["snack-bars", "protein-bars", "granola-bars"],
        "bars": ["snack-bars", "protein-bars", "granola-bars"],
        "chip": ["chips", "crisps"],
        "chips": ["chips", "crisps"],
        "cookie": ["cookies", "biscuits"],
        "cookies": ["cookies", "biscuits"],
        "candy": ["candy", "confectionery", "chocolates"],
        "chocolate": ["chocolates", "chocolate"],
        "sauce": ["sauces", "condiments"],
        "sauces": ["sauces", "condiments"],
        "frozen": ["frozen", "frozen-foods", "frozen-meals"],
        "meat": ["meats", "meat", "poultry"],
        "vegetable": ["vegetables", "frozen-vegetables"],
        "vegetables": ["vegetables", "frozen-vegetables"],
        "fruit": ["fruits", "dried-fruits"],
        "fruits": ["fruits", "dried-fruits"],
        "pasta": ["pasta", "noodles"],
        "rice": ["rice", "grains"],
        "soup": ["soups", "soup"],
        "soups": ["soups", "soup"]
    ]

    /// Resolve category aliases to Open Food Facts category slugs
    static func resolveCategories(_ input: [String]) -> [String] {
        var resolved: Set<String> = []
        for category in input {
            let lower = category.lowercased()
            if let mappings = categoryMappings[lower] {
                resolved.formUnion(mappings)
            } else {
                resolved.insert(lower)
            }
        }
        return Array(resolved)
    }
}
