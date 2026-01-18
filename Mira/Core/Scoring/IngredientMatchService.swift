import Foundation

struct IngredientMatchResult {
    enum FirstIngredientCategory {
        case staple
        case wholeFood
        case unrefinedOil
        case refinedOil
        case ultraProcessed
        case additive
        case unknown
    }

    let containsRefinedOil: Bool
    let containsAdditive: Bool
    let containsNonNutritiveSweetener: Bool
    let containsFlavorOrColor: Bool
    let containsUltraProcessedMarker: Bool
    let matchedAdditives: [AdditiveHit]
    let firstIngredientCategory: FirstIngredientCategory
}

final class IngredientMatchService {
    static let shared = IngredientMatchService()

    private let additiveLexicon: AdditiveLexiconAsset?
    private let additiveTokens: Set<String>
    private let refinedOilTokens: Set<String>
    private let nnsTokens: Set<String>
    private let flavorColorTokens: Set<String>
    private let ultraProcessedTokens: Set<String>
    private let stapleTokens: Set<String>
    private let unrefinedOilTokens: Set<String>
    private let punctuationSet = CharacterSet.alphanumerics.inverted

    init(assetLoader: () -> AdditiveLexiconAsset? = { try? AssetLoader.lexiconAdditives() }) {
        let lexicon = assetLoader()
        self.additiveLexicon = lexicon

        var additive: Set<String> = []
        var refined: Set<String> = []
        var nns: Set<String> = []
        var flavorColor: Set<String> = []
        var ultra: Set<String> = []

        if let entries = lexicon?.entries {
            for entry in entries {
                let normalizedAliases = IngredientMatchService.collectTokens(from: entry)
                additive.formUnion(normalizedAliases)

                if entry.tags.contains(where: { $0 == "refined_oil" }) {
                    refined.formUnion(normalizedAliases)
                }
                if entry.tags.contains(where: { $0 == "nns" }) {
                    nns.formUnion(normalizedAliases)
                }
                if entry.tags.contains(where: { $0 == "flavor" || $0 == "flavoring" || $0 == "color" || $0 == "colorant" }) {
                    flavorColor.formUnion(normalizedAliases)
                }
                if entry.tags.contains(where: { $0 == "ultra_processed_marker" }) {
                    ultra.formUnion(normalizedAliases)
                }
            }
        }

        self.additiveTokens = additive
        self.refinedOilTokens = refined
        self.nnsTokens = nns
        self.flavorColorTokens = flavorColor
        self.ultraProcessedTokens = ultra

        self.stapleTokens = Set([
            "water",
            "whole milk",
            "milk",
            "skim milk",
            "cream",
            "tomato",
            "tomatoes",
            "wheat flour",
            "whole grain wheat",
            "whole grain oats",
            "brown rice",
            "rolled oats",
            "corn",
            "potato",
            "peanut",
            "almond"
        ].map { IngredientMatchService.normalizeToken($0) })

        self.unrefinedOilTokens = Set([
            "extra virgin olive oil",
            "olive oil",
            "avocado oil",
            "coconut oil",
            "sesame oil"
        ].map { IngredientMatchService.normalizeToken($0) })
    }

    func analyze(product: NormalizedProduct) -> IngredientMatchResult {
        let matchedAdditives = product.additiveHits
        let normalizedIngredients = product.product.ingredients.map { normalize($0) }

        var refinedOilDetected = false
        var additiveDetected = !matchedAdditives.isEmpty
        var nnsDetected = false
        var flavorColorDetected = false
        var ultraProcessedDetected = false

        for ingredient in normalizedIngredients {
            if matches(tokenSet: refinedOilTokens, in: ingredient) {
                refinedOilDetected = true
            }
            if matches(tokenSet: additiveTokens, in: ingredient) {
                additiveDetected = true
            }
            if matches(tokenSet: nnsTokens, in: ingredient) {
                nnsDetected = true
            }
            if matches(tokenSet: flavorColorTokens, in: ingredient) {
                flavorColorDetected = true
            }
            if matches(tokenSet: ultraProcessedTokens, in: ingredient) {
                ultraProcessedDetected = true
            }
        }

        let firstIngredientCategory = classifyFirstIngredient(normalizedIngredients.first)

        return IngredientMatchResult(
            containsRefinedOil: refinedOilDetected,
            containsAdditive: additiveDetected,
            containsNonNutritiveSweetener: nnsDetected,
            containsFlavorOrColor: flavorColorDetected,
            containsUltraProcessedMarker: ultraProcessedDetected,
            matchedAdditives: matchedAdditives,
            firstIngredientCategory: firstIngredientCategory
        )
    }

    func classifyFirstIngredient(_ ingredient: String?) -> IngredientMatchResult.FirstIngredientCategory {
        let normalized = normalize(ingredient)
        guard !normalized.isEmpty else { return .unknown }

        if matches(tokenSet: additiveTokens, in: normalized) {
            return .additive
        }
        if matches(tokenSet: refinedOilTokens, in: normalized) {
            return .refinedOil
        }
        if matches(tokenSet: ultraProcessedTokens, in: normalized) {
            return .ultraProcessed
        }
        if stapleTokens.contains(normalized) {
            return .staple
        }
        if unrefinedOilTokens.contains(normalized) {
            return .unrefinedOil
        }
        if normalized.count > 0 {
            return .wholeFood
        }
        return .unknown
    }

    // MARK: - Private helpers

    private func matches(tokenSet: Set<String>, in ingredient: String) -> Bool {
        guard !tokenSet.isEmpty else { return false }
        if tokenSet.contains(ingredient) { return true }
        return tokenSet.contains { ingredient.contains($0) }
    }

    private func normalize(_ ingredient: String?) -> String {
        guard let ingredient = ingredient, !ingredient.isEmpty else { return "" }
        let lower = ingredient.lowercased()
        let components = lower.components(separatedBy: punctuationSet).filter { !$0.isEmpty }
        return components.joined(separator: " ")
    }

    private static func collectTokens(from entry: AdditiveLexiconAsset.Entry) -> Set<String> {
        var tokens: Set<String> = []
        tokens.insert(normalizeToken(entry.displayName))
        entry.aliases.forEach { tokens.insert(normalizeToken($0)) }
        return tokens
    }

    private static func normalizeToken(_ value: String) -> String {
        let lower = value.lowercased()
        let components = lower.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        return components.joined(separator: " ")
    }
}
