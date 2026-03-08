import Foundation

/// Library of educational explainers for each score component, tailored to different health focuses
struct ExplainerLibrary {

    // MARK: - Public API

    /// Get explainer for a specific component and health focus
    static func explainer(for componentName: String, healthFocus: HealthFocus) -> ScoreExplainer? {
        // Normalize component name for matching
        let normalized = componentName.lowercased()

        if normalized.contains("macronutrient") {
            return macronutrientExplainer(for: healthFocus)
        } else if normalized.contains("micronutrient") {
            return micronutrientExplainer(for: healthFocus)
        } else if normalized.contains("processing") {
            return processingExplainer(for: healthFocus)
        } else if normalized.contains("ingredient") {
            return ingredientQualityExplainer(for: healthFocus)
        } else if normalized.contains("additive") {
            return additivesExplainer(for: healthFocus)
        }

        return nil
    }

    // MARK: - Macronutrient Balance

    private static func macronutrientExplainer(for focus: HealthFocus) -> ScoreExplainer {
        let whyItMatters: String
        let examples: [String]

        switch focus {
        case .gutHealth:
            whyItMatters = "For gut health, fiber is the star player. It feeds beneficial gut bacteria (prebiotics) and supports regular digestion. We prioritize high-fiber products and penalize excess sugar, which can disrupt your gut microbiome."
            examples = [
                "Excellent: 5g+ fiber per serving",
                "Good: 3-5g fiber, moderate sugar",
                "Watch out for: <1g fiber, >10g sugar"
            ]

        case .weightLoss:
            whyItMatters = "For weight loss, we focus on satiety and calorie efficiency. Protein and fiber keep you full longer, while excess sugar provides empty calories. The best products have high protein-to-calorie ratios."
            examples = [
                "Excellent: 10g+ protein, 5g+ fiber, <5g sugar",
                "Good: Balanced macros with moderate calories",
                "Watch out for: High calories with low protein/fiber"
            ]

        case .proteinFocus:
            whyItMatters = "For protein focus, we prioritize protein density above all else. Higher protein content relative to calories scores better. We also consider complete protein sources and protein-to-fat ratios."
            examples = [
                "Excellent: 15g+ protein per 100 calories",
                "Good: 10-15g protein per serving",
                "Watch out for: <5g protein or poor protein-to-fat ratio"
            ]

        case .heartHealth:
            whyItMatters = "For heart health, we emphasize fiber (which helps lower cholesterol) and balanced macros. We penalize saturated fat and excess sodium, both of which can impact cardiovascular health."
            examples = [
                "Excellent: High fiber, low saturated fat",
                "Good: Balanced macros, moderate sodium",
                "Watch out for: High saturated fat (>5g) or sodium (>500mg)"
            ]

        case .generalWellness:
            whyItMatters = "For general wellness, we look for balanced nutrition. Adequate protein, beneficial fiber, and minimal added sugars create a well-rounded macronutrient profile that supports overall health."
            examples = [
                "Excellent: Balanced protein, fiber, and healthy fats",
                "Good: Adequate macros without excesses",
                "Watch out for: Extreme imbalances or excess sugar"
            ]
        }

        return ScoreExplainer(
            componentName: "Macronutrient Balance",
            subtitle: "Protein, Carbs, Fiber, and Sugar",
            icon: "chart.pie.fill",
            whatItMeasures: "This component evaluates the balance of macronutrients—protein, carbohydrates, and fat—along with key sub-nutrients like fiber and sugar. It assesses whether the product provides adequate protein and fiber while avoiding excess sugar and unhealthy fats.",
            whyItMatters: whyItMatters,
            examples: examples,
            learnMoreURL: URL(string: "https://www.hsph.harvard.edu/nutritionsource/what-should-you-eat/")
        )
    }

    // MARK: - Micronutrient Density

    private static func micronutrientExplainer(for focus: HealthFocus) -> ScoreExplainer {
        let whyItMatters: String

        switch focus {
        case .gutHealth:
            whyItMatters = "For gut health, certain vitamins and minerals support intestinal health and immune function. We look for products rich in vitamins A, C, D, and minerals like zinc and magnesium that support gut barrier function."

        case .weightLoss:
            whyItMatters = "For weight loss, micronutrient density helps you get maximum nutrition per calorie. Nutrient-dense foods satisfy your body's needs with fewer calories, reducing cravings and supporting metabolism."

        case .proteinFocus:
            whyItMatters = "For protein focus, micronutrients like B vitamins, iron, and zinc support protein metabolism and muscle function. We favor products that provide both protein and essential micronutrients."

        case .heartHealth:
            whyItMatters = "For heart health, micronutrients like potassium, magnesium, and antioxidant vitamins (C, E) are crucial. These support healthy blood pressure, reduce inflammation, and protect cardiovascular tissue."

        case .generalWellness:
            whyItMatters = "For general wellness, a wide variety of vitamins and minerals supports all body systems. Micronutrient-rich foods provide the building blocks your body needs for optimal function."
        }

        return ScoreExplainer(
            componentName: "Micronutrient Density",
            subtitle: "Vitamins and Minerals",
            icon: "pills.fill",
            whatItMeasures: "This component measures the presence and quantity of essential vitamins and minerals. It evaluates whether the product contributes meaningful amounts of micronutrients relative to calories, favoring nutrient-dense foods.",
            whyItMatters: whyItMatters,
            examples: [
                "Excellent: Rich in multiple vitamins/minerals (20%+ DV)",
                "Good: Contains several micronutrients (10-20% DV)",
                "Limited: Minimal micronutrient contribution (<10% DV)"
            ],
            learnMoreURL: URL(string: "https://www.hsph.harvard.edu/nutritionsource/vitamins/")
        )
    }

    // MARK: - Processing Level

    private static func processingExplainer(for focus: HealthFocus) -> ScoreExplainer {
        let whyItMatters: String

        switch focus {
        case .gutHealth:
            whyItMatters = "For gut health, less processing means more intact fiber and prebiotics that feed beneficial bacteria. Ultra-processed foods often lack the fiber and resistant starches that support digestive health."

        case .weightLoss:
            whyItMatters = "For weight loss, minimally processed foods are more satiating and require more energy to digest. Ultra-processed foods are often engineered to be hyper-palatable, making portion control harder."

        case .proteinFocus:
            whyItMatters = "For protein focus, processing level affects protein quality and bioavailability. Minimally processed protein sources often retain more beneficial co-nutrients like vitamins and minerals."

        case .heartHealth:
            whyItMatters = "For heart health, ultra-processed foods are linked to increased cardiovascular risk. Whole and minimally processed foods retain beneficial compounds like fiber, polyphenols, and healthy fats."

        case .generalWellness:
            whyItMatters = "For general wellness, less processing preserves nutrients and beneficial compounds. Research shows that ultra-processed food consumption is linked to various health concerns."
        }

        return ScoreExplainer(
            componentName: "Processing Level",
            subtitle: "How much the food has been altered",
            icon: "gearshape.2.fill",
            whatItMeasures: "This component uses the NOVA classification system to evaluate how processed a food is. It ranges from unprocessed/minimally processed (Group 1) to ultra-processed (Group 4), considering factors like industrial formulation, ingredient complexity, and manufacturing methods.",
            whyItMatters: whyItMatters,
            examples: [
                "NOVA 1: Fresh fruits, vegetables, plain meats",
                "NOVA 2: Simple processed foods (cheese, canned beans)",
                "NOVA 3: Processed foods (bread, canned fish)",
                "NOVA 4: Ultra-processed (sugary snacks, instant meals)"
            ],
            learnMoreURL: URL(string: "https://www.hsph.harvard.edu/nutritionsource/processed-foods/")
        )
    }

    // MARK: - Ingredient Quality

    private static func ingredientQualityExplainer(for focus: HealthFocus) -> ScoreExplainer {
        let whyItMatters: String

        switch focus {
        case .gutHealth:
            whyItMatters = "For gut health, ingredient quality matters because certain additives and derivatives can irritate the gut lining or disrupt the microbiome. We favor products with recognizable, whole-food ingredients."

        case .weightLoss:
            whyItMatters = "For weight loss, clean ingredients often correlate with better satiety and nutritional value. Products with fewer additives and preservatives tend to be more satisfying and nutrient-dense."

        case .proteinFocus:
            whyItMatters = "For protein focus, ingredient quality affects protein bioavailability and overall nutritional value. Clean protein sources without excessive fillers or additives score higher."

        case .heartHealth:
            whyItMatters = "For heart health, ingredient quality is crucial. We penalize trans fats, excessive sodium, and certain preservatives linked to cardiovascular concerns while favoring whole-food ingredients."

        case .generalWellness:
            whyItMatters = "For general wellness, ingredient quality reflects overall food integrity. Products with simple, recognizable ingredients tend to be more nutritious and better for long-term health."
        }

        return ScoreExplainer(
            componentName: "Ingredient Quality",
            subtitle: "What's in the ingredients list",
            icon: "list.bullet.clipboard.fill",
            whatItMeasures: "This component evaluates the ingredient list for quality markers: recognizable whole-food ingredients, absence of highly processed derivatives, short ingredient lists, and transparency. It uses both pattern matching and AI analysis to detect concerning ingredients.",
            whyItMatters: whyItMatters,
            examples: [
                "Excellent: Short list, all recognizable ingredients",
                "Good: Mostly whole foods, few derivatives",
                "Watch out for: Long lists with chemical names, hidden derivatives"
            ],
            learnMoreURL: URL(string: "https://www.hsph.harvard.edu/nutritionsource/healthy-eating-plate/")
        )
    }

    // MARK: - Additives

    private static func additivesExplainer(for focus: HealthFocus) -> ScoreExplainer {
        let whyItMatters: String

        switch focus {
        case .gutHealth:
            whyItMatters = "For gut health, certain additives (like emulsifiers and artificial sweeteners) can disrupt your gut microbiome. We penalize products with gut-irritating additives while accepting safe preservatives."

        case .weightLoss:
            whyItMatters = "For weight loss, some additives can affect satiety signals and metabolism. We favor products with minimal additives, especially avoiding artificial sweeteners that may impact appetite regulation."

        case .proteinFocus:
            whyItMatters = "For protein focus, additives in protein products matter. We penalize unnecessary fillers and potentially harmful additives while accepting functional ingredients that improve protein quality."

        case .heartHealth:
            whyItMatters = "For heart health, we penalize additives linked to cardiovascular concerns (like certain preservatives and trans fat sources) while accepting safe, necessary additives."

        case .generalWellness:
            whyItMatters = "For general wellness, we favor products with minimal additives. While many additives are safe, limiting exposure to unnecessary chemicals aligns with a whole-food approach to health."
        }

        return ScoreExplainer(
            componentName: "Additives",
            subtitle: "Preservatives, colors, and artificial ingredients",
            icon: "flask.fill",
            whatItMeasures: "This component scans for artificial colors, flavors, preservatives, sweeteners, and other food additives. It distinguishes between harmful additives (marked red), questionable ones (yellow), and generally safe additives (green), using evidence-based safety assessments.",
            whyItMatters: whyItMatters,
            examples: [
                "Excellent: No artificial additives, only natural preservatives",
                "Good: Safe, necessary preservatives only",
                "Watch out for: Artificial colors, sweeteners, or controversial additives"
            ],
            learnMoreURL: URL(string: "https://www.hsph.harvard.edu/nutritionsource/food-additives/")
        )
    }
}
