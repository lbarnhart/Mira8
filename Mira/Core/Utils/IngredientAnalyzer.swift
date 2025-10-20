import Foundation

enum IngredientCategory: String, Codable, CaseIterable {
    case beneficial
    case neutral
    case concerning
    case unknown
}

struct IngredientAnalysis: Identifiable {
    let id = UUID()
    let originalName: String
    let displayName: String
    let normalizedName: String
    let category: IngredientCategory
    let explanation: String
    let position: Int
}

final class IngredientAnalyzer {
    static let shared = IngredientAnalyzer()

    private struct IngredientMetadata {
        let displayName: String
        let category: IngredientCategory
        let explanation: String
    }

    private let ingredientDatabase: [String: IngredientMetadata]

    private init() {
        ingredientDatabase = IngredientAnalyzer.buildIngredientDatabase()
    }

    func parseIngredientList(_ raw: String?) -> [String] {
        guard let raw = raw, !raw.isEmpty else { return [] }

        let separators = CharacterSet(charactersIn: ",;•\n")
        let components = raw
            .lowercased()
            .components(separatedBy: separators)
            .map { removeParentheticalContent(from: $0) }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return components.map { formatDisplayName(from: $0) }
    }

    func analyze(ingredients: [String]) -> [IngredientAnalysis] {
        ingredients.enumerated().map { index, ingredient in
            let normalized = normalize(ingredient)
            if let metadata = ingredientDatabase[normalized] {
                return IngredientAnalysis(
                    originalName: ingredient,
                    displayName: metadata.displayName,
                    normalizedName: normalized,
                    category: metadata.category,
                    explanation: metadata.explanation,
                    position: index + 1
                )
            }

            let heuristics = classifyIngredient(named: normalized)
            return IngredientAnalysis(
                originalName: ingredient,
                displayName: heuristics.displayName,
                normalizedName: normalized,
                category: heuristics.category,
                explanation: heuristics.explanation,
                position: index + 1
            )
        }
    }

    // MARK: - Private Helpers

    private static func buildIngredientDatabase() -> [String: IngredientMetadata] {
        return [
            "high fructose corn syrup": IngredientMetadata(
                displayName: "High Fructose Corn Syrup",
                category: .concerning,
                explanation: "A highly processed sweetener linked to weight gain and metabolic issues when consumed in excess."
            ),
            "light brown sugar": IngredientMetadata(
                displayName: "Light Brown Sugar",
                category: .neutral,
                explanation: "Provides sweetness and moisture but offers minimal nutritional value. Enjoy in moderation."
            ),
            "brown sugar": IngredientMetadata(
                displayName: "Brown Sugar",
                category: .neutral,
                explanation: "Adds sweetness and flavor depth. Consider portion size to manage added sugars."
            ),
            "cane sugar": IngredientMetadata(
                displayName: "Cane Sugar",
                category: .neutral,
                explanation: "Common table sugar. Neutral for most people when enjoyed sparingly."
            ),
            "turbinado sugar": IngredientMetadata(
                displayName: "Turbinado Sugar",
                category: .neutral,
                explanation: "Less refined sugar with trace minerals but similar metabolic impact as white sugar."
            ),
            "ascorbic acid": IngredientMetadata(
                displayName: "Vitamin C (Ascorbic Acid)",
                category: .beneficial,
                explanation: "An essential vitamin that supports immune function and acts as an antioxidant."
            ),
            "tocopherol": IngredientMetadata(
                displayName: "Vitamin E (Tocopherol)",
                category: .beneficial,
                explanation: "A fat-soluble antioxidant that helps protect cells from oxidative stress."
            ),
            "citric acid": IngredientMetadata(
                displayName: "Citric Acid",
                category: .neutral,
                explanation: "A natural acid used to add tartness or preserve freshness; generally recognized as safe."
            ),
            "acetic acid": IngredientMetadata(
                displayName: "Acetic Acid",
                category: .neutral,
                explanation: "Main acid in vinegar; provides preservation benefits with minimal nutritional impact."
            ),
            "lactic acid": IngredientMetadata(
                displayName: "Lactic Acid",
                category: .neutral,
                explanation: "Commonly used to regulate acidity or enhance tang. Typically well tolerated."
            ),
            "malic acid": IngredientMetadata(
                displayName: "Malic Acid",
                category: .neutral,
                explanation: "Naturally occurring acid found in fruits, used for tartness and freshness."
            ),
            "tartaric acid": IngredientMetadata(
                displayName: "Tartaric Acid",
                category: .neutral,
                explanation: "Grape-derived acidifier that stabilizes textures and flavors."
            ),
            // Flavors & Seasonings
            "cheese flavor": IngredientMetadata(
                displayName: "Cheese Flavor",
                category: .concerning,
                explanation: "Flavoring agents that often rely on artificial compounds; best limited."
            ),
            "cheddar cheese flavor": IngredientMetadata(
                displayName: "Cheddar Cheese Flavor",
                category: .concerning,
                explanation: "Typically formulated with artificial flavor chemicals; minimize intake."
            ),
            "natural cheese flavor": IngredientMetadata(
                displayName: "Natural Cheese Flavor",
                category: .neutral,
                explanation: "Flavoring derived from dairy ingredients; neutral but processed."
            ),
            "natural flavor": IngredientMetadata(
                displayName: "Natural Flavor",
                category: .neutral,
                explanation: "Broad term for flavor extracts from plant or animal sources. Usually safe, though not very transparent."
            ),
            "natural flavors": IngredientMetadata(
                displayName: "Natural Flavors",
                category: .neutral,
                explanation: "Broad term for flavor extracts from plant or animal sources. Usually safe, though not very transparent."
            ),
            "artificial flavor": IngredientMetadata(
                displayName: "Artificial Flavor",
                category: .concerning,
                explanation: "Synthetic compounds that mimic natural flavors; generally safe but offer no nutritional value."
            ),
            "vanilla extract": IngredientMetadata(
                displayName: "Vanilla Extract",
                category: .neutral,
                explanation: "Alcohol-based extract for flavor. Neutral when used in culinary amounts."
            ),
            "paprika extract": IngredientMetadata(
                displayName: "Paprika Extract",
                category: .neutral,
                explanation: "Extracted spice providing color and flavor. Generally safe."
            ),
            "artificial flavors": IngredientMetadata(
                displayName: "Artificial Flavors",
                category: .concerning,
                explanation: "Synthetic compounds that mimic natural flavors; generally safe but offer no nutritional value."
            ),
            "artificial colors": IngredientMetadata(
                displayName: "Artificial Colors",
                category: .concerning,
                explanation: "Synthetic dyes that provide visual appeal; some are linked to hyperactivity and should be limited."
            ),
            "red 40": IngredientMetadata(
                displayName: "Red 40 (Artificial Color)",
                category: .concerning,
                explanation: "A synthetic dye. While approved for use, some studies suggest sensitivity in certain children."
            ),
            "yellow 5": IngredientMetadata(
                displayName: "Yellow 5 (Artificial Color)",
                category: .concerning,
                explanation: "A synthetic dye associated with hyperactivity in sensitive individuals."
            ),
            "inulin": IngredientMetadata(
                displayName: "Inulin (Prebiotic Fiber)",
                category: .beneficial,
                explanation: "A soluble fiber that feeds beneficial gut bacteria and supports digestive health."
            ),
            // Vegetables & Produce
            "tomato": IngredientMetadata(
                displayName: "Tomato",
                category: .beneficial,
                explanation: "Whole tomato providing vitamins, antioxidants, and natural sweetness."
            ),
            "tomato paste": IngredientMetadata(
                displayName: "Tomato Paste",
                category: .beneficial,
                explanation: "Concentrated tomato product rich in lycopene and flavor with minimal additives."
            ),
            "tomato puree": IngredientMetadata(
                displayName: "Tomato Puree",
                category: .beneficial,
                explanation: "Cooked, blended tomatoes offering fiber and phytonutrients for sauces and soups."
            ),
            "tomato sauce": IngredientMetadata(
                displayName: "Tomato Sauce",
                category: .neutral,
                explanation: "Seasoned tomato base; check labels for added sugar or sodium."
            ),
            "sun dried tomatoes": IngredientMetadata(
                displayName: "Sun Dried Tomatoes",
                category: .beneficial,
                explanation: "Dehydrated tomatoes concentrated in antioxidants and savory flavor."
            ),
            "tomato powder": IngredientMetadata(
                displayName: "Tomato Powder",
                category: .neutral,
                explanation: "Dried tomato used for seasoning; neutral unless sodium or additives are included."
            ),
            "carrot powder": IngredientMetadata(
                displayName: "Carrot Powder",
                category: .beneficial,
                explanation: "Dehydrated carrot supplying natural vitamins, fiber, and color."
            ),
            "ginger powder": IngredientMetadata(
                displayName: "Ginger Powder",
                category: .beneficial,
                explanation: "Ground ginger root offering antioxidants and digestive support."
            ),
            "onion powder": IngredientMetadata(
                displayName: "Onion Powder",
                category: .beneficial,
                explanation: "Concentrated onion providing natural flavor along with trace phytonutrients."
            ),
            "garlic powder": IngredientMetadata(
                displayName: "Garlic Powder",
                category: .beneficial,
                explanation: "Dried garlic carrying compounds that support immune and cardiovascular health."
            ),
            "whole grain oats": IngredientMetadata(
                displayName: "Whole Grain Oats",
                category: .beneficial,
                explanation: "A whole grain rich in fiber, supporting heart health and steady energy."
            ),
            "hydrogenated oil": IngredientMetadata(
                displayName: "Hydrogenated Oil",
                category: .concerning,
                explanation: "A source of trans fats that can raise LDL (bad) cholesterol and increase heart disease risk."
            ),
            "canola oil": IngredientMetadata(
                displayName: "Canola Oil",
                category: .neutral,
                explanation: "Common cooking oil with a neutral flavor; choose cold-pressed versions when possible."
            ),
            "sunflower oil": IngredientMetadata(
                displayName: "Sunflower Oil",
                category: .neutral,
                explanation: "Neutral oil frequently used for sautéing and baking. Keep heat moderate to preserve quality."
            ),
            "safflower oil": IngredientMetadata(
                displayName: "Safflower Oil",
                category: .neutral,
                explanation: "Light flavored oil suitable for high-heat cooking; monitor overall omega-6 intake."
            ),
            "soybean oil": IngredientMetadata(
                displayName: "Soybean Oil",
                category: .neutral,
                explanation: "Widely used neutral oil. Fine for most people, though highly refined."
            ),
            "vinegar": IngredientMetadata(
                displayName: "Vinegar",
                category: .beneficial,
                explanation: "Fermented acidifier that supports flavor while contributing minimal calories."
            ),
            "white vinegar": IngredientMetadata(
                displayName: "White Vinegar",
                category: .beneficial,
                explanation: "Bright, fermented acid used for cleaning and cooking with virtually no calories."
            ),
            "apple cider vinegar": IngredientMetadata(
                displayName: "Apple Cider Vinegar",
                category: .beneficial,
                explanation: "Fermented apple tonic containing organic acids and trace phytonutrients."
            ),
            "balsamic vinegar": IngredientMetadata(
                displayName: "Balsamic Vinegar",
                category: .beneficial,
                explanation: "Aged grape vinegar rich in flavor compounds and naturally low in sugar."
            ),
            "rice vinegar": IngredientMetadata(
                displayName: "Rice Vinegar",
                category: .beneficial,
                explanation: "Mild vinegar made from fermented rice that adds brightness without sodium."
            ),
            "wine vinegar": IngredientMetadata(
                displayName: "Wine Vinegar",
                category: .beneficial,
                explanation: "Fermented wine providing acidity and antioxidant compounds."
            ),
            "red wine vinegar": IngredientMetadata(
                displayName: "Red Wine Vinegar",
                category: .beneficial,
                explanation: "Vinegar crafted from red wine that delivers tartness plus polyphenols."
            ),
            "white wine vinegar": IngredientMetadata(
                displayName: "White Wine Vinegar",
                category: .beneficial,
                explanation: "Light vinegar from white wine, excellent for dressings and sauces."
            ),
            "malt vinegar": IngredientMetadata(
                displayName: "Malt Vinegar",
                category: .beneficial,
                explanation: "Barley-based vinegar bringing tangy depth with minimal calories."
            ),
            "distilled vinegar": IngredientMetadata(
                displayName: "Distilled Vinegar",
                category: .beneficial,
                explanation: "Crystal-clear vinegar ideal for pickling and preserving freshness."
            ),
            "spirit vinegar": IngredientMetadata(
                displayName: "Spirit Vinegar",
                category: .beneficial,
                explanation: "Distilled grain vinegar delivering sharp acidity and virtually no sugar."
            ),
            "organic vinegar": IngredientMetadata(
                displayName: "Organic Vinegar",
                category: .beneficial,
                explanation: "Certified organic vinegar produced via natural fermentation."
            ),
            "organic white vinegar": IngredientMetadata(
                displayName: "Organic White Vinegar",
                category: .beneficial,
                explanation: "Organic distilled vinegar offering clean acidity for cooking and pickling."
            ),
            "xanthan gum": IngredientMetadata(
                displayName: "Xanthan Gum",
                category: .neutral,
                explanation: "A fermented polysaccharide used to stabilize and thicken foods."
            ),
            "guar gum": IngredientMetadata(
                displayName: "Guar Gum",
                category: .neutral,
                explanation: "Plant-derived thickener that adds body to sauces and dairy alternatives."
            ),
            "locust bean gum": IngredientMetadata(
                displayName: "Locust Bean Gum",
                category: .neutral,
                explanation: "Carob bean gum used for texture in frozen desserts and plant milks."
            ),
            "calcium disodium edta": IngredientMetadata(
                displayName: "Calcium Disodium EDTA",
                category: .neutral,
                explanation: "Chelating agent that helps prevent discoloration and rancidity in packaged foods."
            ),
            "egg yolk": IngredientMetadata(
                displayName: "Egg Yolk",
                category: .beneficial,
                explanation: "Whole-food source of vitamins, minerals, and healthy fats."
            ),
            // Dairy
            "milk": IngredientMetadata(
                displayName: "Milk",
                category: .neutral,
                explanation: "Conventional cow's milk providing calcium and protein with moderate saturated fat."
            ),
            "reduced fat milk": IngredientMetadata(
                displayName: "Reduced Fat Milk",
                category: .beneficial,
                explanation: "Lower-fat milk offering protein and calcium with less saturated fat."
            ),
            "low fat milk": IngredientMetadata(
                displayName: "Low Fat Milk",
                category: .beneficial,
                explanation: "Reduced-fat dairy delivering protein and calcium while limiting saturated fat."
            ),
            "skim milk": IngredientMetadata(
                displayName: "Skim Milk",
                category: .beneficial,
                explanation: "Fat-free milk rich in protein and calcium with minimal saturated fat."
            ),
            "whole milk": IngredientMetadata(
                displayName: "Whole Milk",
                category: .neutral,
                explanation: "Full-fat dairy supplying fat-soluble vitamins alongside higher saturated fat."
            ),
            "cheese": IngredientMetadata(
                displayName: "Cheese",
                category: .neutral,
                explanation: "General cheese ingredient providing calcium and protein with moderate saturated fat."
            ),
            "cheddar cheese": IngredientMetadata(
                displayName: "Cheddar Cheese",
                category: .neutral,
                explanation: "Aged cheese rich in calcium and protein but also saturated fat and sodium."
            ),
            "mozzarella cheese": IngredientMetadata(
                displayName: "Mozzarella Cheese",
                category: .neutral,
                explanation: "Soft cheese offering calcium and protein with moderate sodium."
            ),
            "parmesan cheese": IngredientMetadata(
                displayName: "Parmesan Cheese",
                category: .neutral,
                explanation: "Aged hard cheese with concentrated flavor, protein, and sodium."
            ),
            "cheese cultures": IngredientMetadata(
                displayName: "Cheese Cultures",
                category: .beneficial,
                explanation: "Beneficial bacteria used in cheese fermentation that support gut health."
            ),
            "cream cheese": IngredientMetadata(
                displayName: "Cream Cheese",
                category: .neutral,
                explanation: "Spreadable cheese delivering creamy texture along with higher saturated fat."
            ),
            "cottage cheese": IngredientMetadata(
                displayName: "Cottage Cheese",
                category: .beneficial,
                explanation: "Fresh cheese curds high in protein and relatively low in fat."
            ),
            "whey protein": IngredientMetadata(
                displayName: "Whey Protein",
                category: .beneficial,
                explanation: "Dairy-derived protein supporting muscle maintenance and satiety."
            ),
            "milk powder": IngredientMetadata(
                displayName: "Milk Powder",
                category: .beneficial,
                explanation: "Dehydrated milk preserving protein, calcium, and other nutrients."
            ),
            // Flours & Starches
            "rice flour": IngredientMetadata(
                displayName: "Rice Flour",
                category: .beneficial,
                explanation: "Gluten-free flour providing complex carbohydrates and gentle texture."
            ),
            "brown rice flour": IngredientMetadata(
                displayName: "Brown Rice Flour",
                category: .beneficial,
                explanation: "Whole-grain rice flour retaining fiber, minerals, and steady energy."
            ),
            "white rice flour": IngredientMetadata(
                displayName: "White Rice Flour",
                category: .neutral,
                explanation: "Refined rice flour offering light texture but fewer nutrients than whole-grain versions."
            ),
            "rice starch": IngredientMetadata(
                displayName: "Rice Starch",
                category: .neutral,
                explanation: "Refined rice starch used for thickening; provides structure with minimal nutrition."
            ),
            "tapioca flour": IngredientMetadata(
                displayName: "Tapioca Flour",
                category: .beneficial,
                explanation: "Cassava-based starch that is gluten-free and gentle on digestion."
            ),
            "potato starch": IngredientMetadata(
                displayName: "Potato Starch",
                category: .neutral,
                explanation: "Resistant starch used for thickening; neutral unless heavily processed."
            ),
            "cornstarch": IngredientMetadata(
                displayName: "Cornstarch",
                category: .neutral,
                explanation: "Common thickener from corn endosperm; offers texture but limited nutrients."
            ),
            "arrowroot flour": IngredientMetadata(
                displayName: "Arrowroot Flour",
                category: .beneficial,
                explanation: "Root-derived starch that is easy to digest and a good thickener for sensitive diets."
            ),
            // Protein & Enzymes
            "enzymes": IngredientMetadata(
                displayName: "Enzymes",
                category: .beneficial,
                explanation: "Natural catalysts used in food processing that support digestion and fermentation."
            ),
            "rennet": IngredientMetadata(
                displayName: "Rennet",
                category: .neutral,
                explanation: "Coagulating enzyme used in cheese making; typically well tolerated."
            ),
            "protease": IngredientMetadata(
                displayName: "Protease",
                category: .neutral,
                explanation: "Protein-digesting enzyme used to tenderize foods or aid digestion."
            ),
            "amylase": IngredientMetadata(
                displayName: "Amylase",
                category: .neutral,
                explanation: "Starch-digesting enzyme used in baking and food processing."
            ),
            "monosodium glutamate": IngredientMetadata(
                displayName: "Monosodium Glutamate (MSG)",
                category: .neutral,
                explanation: "A flavor enhancer considered safe for most people, though some report sensitivity in large amounts."
            )
        ]
    }

    private func classifyIngredient(named normalized: String) -> IngredientMetadata {
        if let eNumberMetadata = classifyENumber(named: normalized) {
            return eNumberMetadata
        }

        if normalized.contains("vitamin") {
            return IngredientMetadata(
                displayName: formatDisplayName(from: normalized),
                category: .beneficial,
                explanation: "Vitamins support essential bodily functions and overall wellness."
            )
        }

        if normalized.contains("whole") || normalized.contains("sprouted") || normalized.contains("flax") || normalized.contains("chia") {
            return IngredientMetadata(
                displayName: formatDisplayName(from: normalized),
                category: .beneficial,
                explanation: "Whole-food ingredients provide fiber, antioxidants, and steady energy."
            )
        }

        if normalized.contains("fiber") || normalized.contains("prebiotic") {
            return IngredientMetadata(
                displayName: formatDisplayName(from: normalized),
                category: .beneficial,
                explanation: "Fiber supports digestive health and helps keep blood sugar steady."
            )
        }

        if normalized.contains("hydrogenated") || normalized.contains("partially hydrogenated") || normalized.contains("artificial") || normalized.contains("corn syrup") {
            return IngredientMetadata(
                displayName: formatDisplayName(from: normalized),
                category: .concerning,
                explanation: "Highly processed additives that may negatively impact heart or metabolic health when eaten frequently."
            )
        }

        if normalized.contains("color") || normalized.contains("dye") {
            return IngredientMetadata(
                displayName: formatDisplayName(from: normalized),
                category: .concerning,
                explanation: "Artificial colorings provide no nutritional value and can trigger sensitivities in some people."
            )
        }

        if let oilMetadata = classifyOil(named: normalized) {
            return oilMetadata
        }

        if let sugarMetadata = classifySugar(named: normalized) {
            return sugarMetadata
        }

        if let acidMetadata = classifyAcid(named: normalized) {
            return acidMetadata
        }

        if let gumMetadata = classifyGumOrThickener(named: normalized) {
            return gumMetadata
        }

        if let powderMetadata = classifyPowder(named: normalized) {
            return powderMetadata
        }

        if normalized.contains("sodium") || normalized.contains("salt") {
            return IngredientMetadata(
                displayName: formatDisplayName(from: normalized),
                category: .neutral,
                explanation: "Salt is necessary in small amounts but can contribute to high blood pressure when excessive."
            )
        }

        if normalized.contains("water") {
            return IngredientMetadata(
                displayName: "Water",
                category: .neutral,
                explanation: "Water is often used as a base or solvent in foods."
            )
        }

        #if DEBUG
        print("⚠️ Unknown ingredient: '\(normalized)'")
        #endif

        return IngredientMetadata(
            displayName: formatDisplayName(from: normalized),
            category: .unknown,
            explanation: "Limited data on this ingredient's impact."
        )
    }

    private func classifyENumber(named normalized: String) -> IngredientMetadata? {
        let compact = normalized
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")

        guard compact.hasPrefix("e"), compact.count > 1, let code = Int(compact.dropFirst()) else {
            return nil
        }

        let displayName = compact.uppercased()

        let mapping: [Int: (String, IngredientCategory, String)] = [
            322: ("Lecithin", .neutral, "Fatty emulsifier that keeps textures smooth; typically derived from soy or sunflower."),
            330: ("Citric Acid", .neutral, "Naturally occurring acid that balances acidity and acts as a mild preservative."),
            415: ("Xanthan Gum", .neutral, "Fermented thickener providing body and stability."),
            440: ("Pectin", .neutral, "Fruit-derived thickener supplying soluble fiber.")
        ]

        if (300...309).contains(code) {
            return IngredientMetadata(
                displayName: "\(displayName) (Vitamin)",
                category: .beneficial,
                explanation: "Antioxidant vitamins (such as vitamin C and E) that support cellular health."
            )
        }

        if let entry = mapping[code] {
            return IngredientMetadata(
                displayName: "\(displayName) (\(entry.0))",
                category: entry.1,
                explanation: entry.2
            )
        }

        let concerningCodes: Set<Int> = [102, 110, 122, 124]
        if concerningCodes.contains(code) {
            return IngredientMetadata(
                displayName: "\(displayName) (Artificial Colour)",
                category: .concerning,
                explanation: "Synthetic dye linked to hyperactivity or sensitivities in some individuals."
            )
        }

        return nil
    }

    private func classifyOil(named normalized: String) -> IngredientMetadata? {
        guard normalized.contains("oil") else { return nil }

        if normalized.contains("hydrogenated") {
            return IngredientMetadata(
                displayName: formatDisplayName(from: normalized),
                category: .concerning,
                explanation: "Hydrogenated oils introduce trans fats that negatively affect heart health."
            )
        }

        let beneficialOils = ["olive", "extra virgin", "avocado", "coconut"]
        if beneficialOils.contains(where: { normalized.contains($0) }) {
            return IngredientMetadata(
                displayName: formatDisplayName(from: normalized),
                category: .beneficial,
                explanation: "Rich in heart-healthy fats and antioxidants when minimally processed."
            )
        }

        return IngredientMetadata(
            displayName: formatDisplayName(from: normalized),
            category: .neutral,
            explanation: "Common culinary oil providing energy and aiding nutrient absorption."
        )
    }

    private func classifySugar(named normalized: String) -> IngredientMetadata? {
        if normalized.contains("high fructose") {
            return IngredientMetadata(
                displayName: formatDisplayName(from: normalized),
                category: .concerning,
                explanation: "Highly processed sweetener associated with metabolic stress when consumed frequently."
            )
        }

        let sugarKeywords = ["sugar", "syrup", "molasses", "honey"]
        guard sugarKeywords.contains(where: { normalized.contains($0) }) else { return nil }

        return IngredientMetadata(
            displayName: formatDisplayName(from: normalized),
            category: .neutral,
            explanation: "Adds sweetness and browning. Keep portions modest to manage added sugars."
        )
    }

    private func classifyAcid(named normalized: String) -> IngredientMetadata? {
        guard normalized.contains("acid") else { return nil }

        if normalized.contains("ascorbic") {
            return IngredientMetadata(
                displayName: "Vitamin C (Ascorbic Acid)",
                category: .beneficial,
                explanation: "Antioxidant vitamin that supports immune and skin health."
            )
        }

        return IngredientMetadata(
            displayName: formatDisplayName(from: normalized),
            category: .neutral,
            explanation: "Food-safe acidifier that brightens flavor and aids preservation."
        )
    }

    private func classifyGumOrThickener(named normalized: String) -> IngredientMetadata? {
        let gumKeywords = ["gum", "pectin", "cellulose", "starch", "carrageenan"]
        guard gumKeywords.contains(where: { normalized.contains($0) }) else { return nil }

        return IngredientMetadata(
            displayName: formatDisplayName(from: normalized),
            category: .neutral,
            explanation: "Texturizer that helps stabilize or thicken foods without significant nutritional impact."
        )
    }

    private func classifyPowder(named normalized: String) -> IngredientMetadata? {
        guard normalized.contains("powder") else { return nil }

        let beneficialKeywords = [
            "carrot", "ginger", "onion", "garlic", "tomato", "spinach", "kale", "beet", "turmeric", "mushroom", "paprika"
        ]

        if beneficialKeywords.contains(where: { normalized.contains($0) }) {
            return IngredientMetadata(
                displayName: formatDisplayName(from: normalized),
                category: .beneficial,
                explanation: "Dehydrated whole-food ingredient providing concentrated flavor and phytonutrients."
            )
        }

        return IngredientMetadata(
            displayName: formatDisplayName(from: normalized),
            category: .neutral,
            explanation: "Powdered ingredient used for flavor or texture; limited nutritional impact."
        )
    }

    private func removeParentheticalContent(from text: String) -> String {
        var cleaned = text
        while let start = cleaned.firstIndex(of: "("), let end = cleaned[start...].firstIndex(of: ")") {
            cleaned.removeSubrange(start...end)
        }
        return cleaned
    }

    private func normalize(_ ingredient: String) -> String {
        ingredient
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "\u{00a0}", with: " ")
    }

    private func formatDisplayName(from ingredient: String) -> String {
        let components = ingredient
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: CharacterSet.punctuationCharacters) }
            .filter { !$0.isEmpty }

        guard !components.isEmpty else {
            return ingredient.trimmingCharacters(in: .whitespacesAndNewlines).capitalized
        }

        return components
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}
