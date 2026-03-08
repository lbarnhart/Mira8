import Foundation

/// Provides fuzzy string matching for product identification.
/// Uses multiple algorithms to find the best matches.
struct ProductFuzzyMatcher {

    // MARK: - Match Products

    /// Calculate match score between identification and search results.
    static func calculateMatchScore(
        identification: ProductIdentification,
        candidateName: String,
        candidateBrand: String?,
        candidateCategory: String? = nil
    ) -> Double {
        var score = 0.0
        var totalWeight = 0.0

        // Name matching (weight: 0.35 - reduced to make room for better category matching)
        let nameScore = stringSimilarity(
            normalize(identification.name),
            normalize(candidateName)
        )
        score += nameScore * 0.35
        totalWeight += 0.35

        // Brand matching (weight: 0.2)
        if let identBrand = identification.brand, let candBrand = candidateBrand {
            let brandScore = stringSimilarity(
                normalize(identBrand),
                normalize(candBrand)
            )
            score += brandScore * 0.2
            totalWeight += 0.2
        } else if identification.brand == nil && candidateBrand != nil {
            // Brand in candidate but not in identification - partial match
            score += 0.1
            totalWeight += 0.2
        }

        // Key descriptor matching (weight: 0.25)
        // This is crucial for distinguishing product variants like "Stone-Ground White" vs "100% Whole Grain"
        let descriptorScore = descriptorMatchScore(
            identifiedName: identification.name,
            candidateName: candidateName
        )
        score += descriptorScore * 0.25
        totalWeight += 0.25

        // Category matching (weight: 0.2 - increased for better accuracy)
        let categoryScore = categoryMatchScore(
            identifiedCategory: identification.category,
            candidateCategory: candidateCategory,
            candidateName: candidateName
        )
        score += categoryScore * 0.2
        totalWeight += 0.2

        // Normalize score
        return score / totalWeight
    }

    // MARK: - Category Matching

    /// Category aliases for matching similar categories
    private static let categoryAliases: [String: [String]] = [
        "condiments": ["ketchup", "mustard", "sauce", "sauces", "dressing", "dressings", "condiment"],
        "ketchup": ["condiments", "condiment", "sauce", "sauces", "tomato sauce"],
        "sauce": ["sauces", "condiments", "condiment"],
        "sauces": ["sauce", "condiments", "condiment"],
        "snacks": ["chips", "crackers", "snack", "snack foods"],
        "chips": ["snacks", "snack", "potato chips", "tortilla chips"],
        "cereals": ["cereal", "breakfast cereals", "breakfast"],
        "cereal": ["cereals", "breakfast cereals", "breakfast"],
        "beverages": ["drinks", "beverage", "juice", "soda"],
        "drinks": ["beverages", "beverage", "juice", "soda"],
        "dairy": ["milk", "cheese", "yogurt", "butter"],
        "cheese": ["dairy", "cheeses"],
        "pizza": ["frozen pizza", "frozen foods"],
        "frozen foods": ["frozen", "frozen pizza", "frozen meals"],
        "canned goods": ["canned", "canned vegetables", "canned beans"],
        "beans": ["canned beans", "legumes", "canned goods"]
    ]

    /// Calculate category match score
    private static func categoryMatchScore(
        identifiedCategory: String?,
        candidateCategory: String?,
        candidateName: String
    ) -> Double {
        guard let identCat = identifiedCategory?.lowercased() else {
            return 0.5 // No category to compare, neutral score
        }

        let candCat = candidateCategory?.lowercased() ?? ""
        let candNameLower = candidateName.lowercased()

        // Direct category match
        if !candCat.isEmpty && candCat.contains(identCat) {
            return 1.0
        }

        // Check if candidate category is an alias of identified category
        if !candCat.isEmpty, let aliases = categoryAliases[identCat] {
            for alias in aliases {
                if candCat.contains(alias) {
                    return 0.9
                }
            }
        }

        // Check if identified category appears in candidate name
        if candNameLower.contains(identCat) {
            return 0.8
        }

        // Check if aliases appear in candidate name
        if let aliases = categoryAliases[identCat] {
            for alias in aliases {
                if candNameLower.contains(alias) {
                    return 0.7
                }
            }
        }

        // PENALTY: Check for clearly mismatched categories
        let mismatchedCategories: [(identified: [String], candidate: [String])] = [
            (["condiments", "ketchup", "sauce"], ["pizza", "cheese", "dairy", "frozen"]),
            (["pizza", "frozen pizza"], ["condiments", "sauce", "ketchup"]),
            (["beverages", "drinks", "juice"], ["snacks", "chips", "crackers"]),
            (["snacks", "chips"], ["beverages", "drinks", "dairy"]),
            (["cereal", "cereals", "breakfast"], ["frozen", "pizza", "cheese"])
        ]

        for mismatch in mismatchedCategories {
            let identifiedMatches = mismatch.identified.contains { identCat.contains($0) }
            let candidateMatches = mismatch.candidate.contains { name in
                candCat.contains(name) || candNameLower.contains(name)
            }

            if identifiedMatches && candidateMatches {
                return 0.1 // Heavy penalty for category mismatch
            }
        }

        // No clear match or mismatch
        return 0.4
    }

    // MARK: - Descriptor Matching

    /// Key descriptors that distinguish product variants
    private static let distinguishingDescriptors: [String] = [
        // Grain types
        "100%", "whole grain", "stone-ground", "stone ground", "white",
        "whole wheat", "refined", "unbleached", "bleached",
        // Processing
        "all-purpose", "all purpose", "bread", "cake", "pastry", "self-rising",
        // Health/Diet
        "organic", "gluten-free", "gluten free", "keto", "paleo",
        "low sodium", "no salt", "unsalted", "reduced sodium",
        "fat free", "reduced fat", "low fat", "light", "lite",
        "sugar free", "no sugar", "reduced sugar", "unsweetened",
        // Quality/Type
        "extra virgin", "virgin", "cold pressed", "cold-pressed",
        "raw", "roasted", "smoked", "spicy", "mild", "hot",
        "original", "classic", "traditional", "homestyle",
        // Size/Quantity descriptors
        "mini", "jumbo", "bite-size", "bite size", "family size",
        // Flavor variants
        "plain", "flavored", "seasoned", "unseasoned",
        "salted", "honey", "cinnamon", "vanilla", "chocolate"
    ]

    /// Calculate how well the key descriptors match between identified and candidate products
    private static func descriptorMatchScore(identifiedName: String, candidateName: String) -> Double {
        let identLower = identifiedName.lowercased()
        let candLower = candidateName.lowercased()

        var identDescriptors: Set<String> = []
        var candDescriptors: Set<String> = []

        // Find which descriptors are present in each name
        for descriptor in distinguishingDescriptors {
            if identLower.contains(descriptor) {
                identDescriptors.insert(descriptor)
            }
            if candLower.contains(descriptor) {
                candDescriptors.insert(descriptor)
            }
        }

        // If no descriptors found in identified name, give partial credit
        if identDescriptors.isEmpty {
            return 0.5
        }

        // Calculate overlap
        let intersection = identDescriptors.intersection(candDescriptors)
        let union = identDescriptors.union(candDescriptors)

        // If candidate has conflicting descriptors (e.g., identified has "whole grain" but candidate has "white"),
        // heavily penalize
        let conflictingPairs: [(String, String)] = [
            ("white", "whole grain"),
            ("white", "100%"),
            ("bleached", "unbleached"),
            ("salted", "unsalted"),
            ("sweetened", "unsweetened"),
            ("flavored", "plain"),
            ("spicy", "mild"),
            ("regular", "light"),
            ("original", "flavored")
        ]

        for (desc1, desc2) in conflictingPairs {
            let identHasDesc1 = identDescriptors.contains(desc1)
            let identHasDesc2 = identDescriptors.contains(desc2)
            let candHasDesc1 = candDescriptors.contains(desc1)
            let candHasDesc2 = candDescriptors.contains(desc2)

            // Check for conflicts: identified has desc1 but candidate has desc2 (or vice versa)
            if (identHasDesc1 && candHasDesc2 && !candHasDesc1) ||
               (identHasDesc2 && candHasDesc1 && !candHasDesc2) {
                return 0.1 // Heavy penalty for conflicting descriptors
            }
        }

        // If candidate is missing key descriptors from identified, penalize
        let missingDescriptors = identDescriptors.subtracting(candDescriptors)
        if !missingDescriptors.isEmpty {
            // Check if missing descriptors are important (e.g., "whole grain", "100%", "white")
            let criticalDescriptors: Set<String> = [
                "100%", "whole grain", "stone-ground", "stone ground", "white",
                "organic", "gluten-free", "gluten free"
            ]

            let missingCritical = missingDescriptors.intersection(criticalDescriptors)
            if !missingCritical.isEmpty {
                // Missing critical descriptors - significant penalty
                return max(0.2, Double(intersection.count) / Double(union.count) * 0.5)
            }
        }

        // Standard Jaccard similarity for descriptors
        if union.isEmpty {
            return 0.5
        }

        return Double(intersection.count) / Double(union.count)
    }

    /// Rank multiple matches and return sorted by score
    static func rankMatches(
        identification: ProductIdentification,
        candidates: [(name: String, brand: String?, barcode: String, data: Any)]
    ) -> [(score: Double, barcode: String, data: Any)] {
        candidates.map { candidate in
            let score = calculateMatchScore(
                identification: identification,
                candidateName: candidate.name,
                candidateBrand: candidate.brand
            )
            return (score, candidate.barcode, candidate.data)
        }
        .sorted { $0.score > $1.score }
    }

    // MARK: - String Similarity Algorithms

    /// Combined similarity using multiple algorithms
    static func stringSimilarity(_ s1: String, _ s2: String) -> Double {
        guard !s1.isEmpty && !s2.isEmpty else { return 0 }

        // Weight different algorithms
        let levenshtein = levenshteinSimilarity(s1, s2) * 0.3
        let jaccard = jaccardSimilarity(s1, s2) * 0.3
        let longestCommon = longestCommonSubsequenceSimilarity(s1, s2) * 0.2
        let tokenMatch = tokenMatchSimilarity(s1, s2) * 0.2

        return levenshtein + jaccard + longestCommon + tokenMatch
    }

    // MARK: - Levenshtein Distance

    /// Levenshtein similarity (1 - normalized distance)
    static func levenshteinSimilarity(_ s1: String, _ s2: String) -> Double {
        let distance = levenshteinDistance(s1, s2)
        let maxLength = max(s1.count, s2.count)

        guard maxLength > 0 else { return 1.0 }

        return 1.0 - (Double(distance) / Double(maxLength))
    }

    private static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)

        if s1Array.isEmpty { return s2Array.count }
        if s2Array.isEmpty { return s1Array.count }

        var matrix = [[Int]](
            repeating: [Int](repeating: 0, count: s2Array.count + 1),
            count: s1Array.count + 1
        )

        for i in 0...s1Array.count { matrix[i][0] = i }
        for j in 0...s2Array.count { matrix[0][j] = j }

        for i in 1...s1Array.count {
            for j in 1...s2Array.count {
                let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,
                    matrix[i][j - 1] + 1,
                    matrix[i - 1][j - 1] + cost
                )
            }
        }

        return matrix[s1Array.count][s2Array.count]
    }

    // MARK: - Jaccard Similarity

    /// Jaccard similarity based on character bigrams
    static func jaccardSimilarity(_ s1: String, _ s2: String) -> Double {
        let bigrams1 = Set(bigrams(s1))
        let bigrams2 = Set(bigrams(s2))

        guard !bigrams1.isEmpty || !bigrams2.isEmpty else { return 0 }

        let intersection = bigrams1.intersection(bigrams2).count
        let union = bigrams1.union(bigrams2).count

        return Double(intersection) / Double(union)
    }

    private static func bigrams(_ string: String) -> [String] {
        guard string.count >= 2 else { return [] }

        var result: [String] = []
        let chars = Array(string)

        for i in 0..<(chars.count - 1) {
            result.append(String(chars[i]) + String(chars[i + 1]))
        }

        return result
    }

    // MARK: - Longest Common Subsequence

    /// LCS similarity
    static func longestCommonSubsequenceSimilarity(_ s1: String, _ s2: String) -> Double {
        let lcsLength = longestCommonSubsequenceLength(s1, s2)
        let maxLength = max(s1.count, s2.count)

        guard maxLength > 0 else { return 1.0 }

        return Double(lcsLength) / Double(maxLength)
    }

    private static func longestCommonSubsequenceLength(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)

        var dp = [[Int]](
            repeating: [Int](repeating: 0, count: s2Array.count + 1),
            count: s1Array.count + 1
        )

        for i in 1...s1Array.count {
            for j in 1...s2Array.count {
                if s1Array[i - 1] == s2Array[j - 1] {
                    dp[i][j] = dp[i - 1][j - 1] + 1
                } else {
                    dp[i][j] = max(dp[i - 1][j], dp[i][j - 1])
                }
            }
        }

        return dp[s1Array.count][s2Array.count]
    }

    // MARK: - Token Match

    /// Word token overlap similarity
    static func tokenMatchSimilarity(_ s1: String, _ s2: String) -> Double {
        let tokens1 = Set(tokenize(s1))
        let tokens2 = Set(tokenize(s2))

        guard !tokens1.isEmpty || !tokens2.isEmpty else { return 0 }

        let intersection = tokens1.intersection(tokens2).count
        let minTokens = min(tokens1.count, tokens2.count)

        guard minTokens > 0 else { return 0 }

        return Double(intersection) / Double(minTokens)
    }

    private static func tokenize(_ string: String) -> [String] {
        string
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 2 }
    }

    // MARK: - Normalization

    /// Normalize string for comparison
    static func normalize(_ string: String) -> String {
        string
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: "", options: .regularExpression)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    // MARK: - Quick Match Check

    /// Fast check if two strings are likely the same product
    static func isLikelyMatch(_ s1: String, _ s2: String, threshold: Double = 0.6) -> Bool {
        stringSimilarity(normalize(s1), normalize(s2)) >= threshold
    }
}
