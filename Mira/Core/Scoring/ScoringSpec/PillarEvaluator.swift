import Foundation

enum PillarID: String, Codable, CaseIterable {
    case p1Sugar
    case p2Sodium
    case p3MetabolicLoad
    case p4PositiveNutrition

    var label: String {
        switch self {
        case .p1Sugar:
            return "Added sugar limits"
        case .p2Sodium:
            return "Sodium balance"
        case .p3MetabolicLoad:
            return "Energy & saturated fat"
        case .p4PositiveNutrition:
            return "Positive nutrition density"
        }
    }
}

struct PillarResult {
    let id: PillarID
    let label: String
    let contributions: [NutrientContribution]
    let score: Double?
}

struct PillarEvaluation {
    let contributions: [NutrientContribution]
    let rawNegativePoints: Int
    let rawPositivePoints: Int
    let weightedNegativePoints: Double
    let weightedPositivePoints: Double
    let baseScore: Double
    let missingCriticalNutrients: [String]
    let pillars: [PillarResult]
    let pillarsDropped: [PillarID]
    let weightsProfileID: String
    let lensApplied: Bool
}

final class PillarEvaluator {
    private let lensAdjuster = LensAdjuster()
    private let thresholdLookup: ThresholdLookup

    private enum Constants {
        static let maxNegativeRaw = 60
        static let maxPositiveRaw = 40
        static let hydrationEnergyThreshold = 20.0
        static let hydrationSugarThreshold = 0.5
        static let minContributionWeight = 0.01
    }

    init(thresholdLookup: ThresholdLookup = .shared) {
        self.thresholdLookup = thresholdLookup
    }

    private enum ContributionBucket {
        case negative
        case positive
    }

    private struct ContributionBlueprint {
        let kind: NutrientContribution.Kind
        let nutrient: NutrientContribution.Nutrient
        let label: String
        let rawPoints: Int
        let maxPoints: Int
        let baseWeight: Double
        var weight: Double
        let value: Double?
        let unit: String
        let explanation: String
        let guideline: String
        let dataAvailable: Bool
        var modifiers: [String]
    }

    private struct PillarSubcomponent {
        var blueprint: ContributionBlueprint
        let pillar: PillarID
        let bucket: ContributionBucket
    }

    private struct PillarContribution {
        let pillar: PillarID
        let contribution: NutrientContribution
    }

    func evaluate(input: ScoringInput) -> PillarEvaluation {
        let energyKJValue = normalizedValue(\.calories, input: input).map { $0 * 4.184 }
        let sugarValue = normalizedValue(\.sugar, input: input)
        let saturatedFatValue = normalizedValue(\.saturatedFat, input: input)
        let sodiumValue = normalizedValue(\.sodium, input: input)
        let fiberValue = normalizedValue(\.fiber, input: input)
        let proteinValue = normalizedValue(\.protein, input: input)

        let normalizedProduct = NormalizedProduct(input: input)
        var weightProfile = WeightProfile.profile(for: normalizedProduct)
        let lensApplied = lensAdjuster.apply(profile: &weightProfile, product: normalizedProduct)
        let originalTotalWeight = weightProfile.totalWeight()

        // Extract category for category-relative scoring
        let category = input.product.category ?? input.product.categorySlug
        
        var subcomponents: [PillarSubcomponent] = []
        subcomponents.append(
            PillarSubcomponent(
                blueprint: energyContribution(energyKJ: energyKJValue, availability: input.availability, isBeverage: input.isBeverage),
                pillar: .p3MetabolicLoad,
                bucket: .negative
            )
        )
        subcomponents.append(
            PillarSubcomponent(
                blueprint: sugarContribution(value: sugarValue, availability: input.availability, isBeverage: input.isBeverage, category: category),
                pillar: .p1Sugar,
                bucket: .negative
            )
        )
        subcomponents.append(
            PillarSubcomponent(
                blueprint: saturatedFatContribution(value: saturatedFatValue, availability: input.availability, isBeverage: input.isBeverage),
                pillar: .p3MetabolicLoad,
                bucket: .negative
            )
        )
        subcomponents.append(
            PillarSubcomponent(
                blueprint: sodiumContribution(value: sodiumValue, availability: input.availability, isBeverage: input.isBeverage, category: category),
                pillar: .p2Sodium,
                bucket: .negative
            )
        )

        subcomponents.append(
            PillarSubcomponent(
                blueprint: fruitVegContribution(input: input),
                pillar: .p4PositiveNutrition,
                bucket: .positive
            )
        )
        subcomponents.append(
            PillarSubcomponent(
                blueprint: fiberContribution(value: fiberValue, availability: input.availability, isBeverage: input.isBeverage),
                pillar: .p4PositiveNutrition,
                bucket: .positive
            )
        )
        subcomponents.append(
            PillarSubcomponent(
                blueprint: proteinContribution(
                    value: proteinValue,
                    availability: input.availability,
                    energyKJ: energyKJValue,
                    fruitVegPercent: input.fruitVegPercent,
                    isBeverage: input.isBeverage,
                    sugar: sugarValue
                ),
                pillar: .p4PositiveNutrition,
                bucket: .positive
            )
        )

        var pillarIndexes: [PillarID: [Int]] = [:]
        for index in subcomponents.indices {
            pillarIndexes[subcomponents[index].pillar, default: []].append(index)
        }

        var pillarsDropped: [PillarID] = []
        var pillarBaseSums: [PillarID: Double] = [:]

        for pillar in PillarID.allCases {
            guard let indexes = pillarIndexes[pillar], !indexes.isEmpty else { continue }
            let availableIndexes = indexes.filter { subcomponents[$0].blueprint.dataAvailable }
            guard !availableIndexes.isEmpty else {
                pillarsDropped.append(pillar)
                weightProfile.updateWeight(for: pillar, to: 0)
                for idx in indexes { subcomponents[idx].blueprint.weight = 0 }
                continue
            }

            let baseSum = availableIndexes.reduce(0.0) { $0 + subcomponents[$1].blueprint.baseWeight }
            pillarBaseSums[pillar] = baseSum
        }

        if weightProfile.totalWeight() > 0 {
            weightProfile.renormalize(total: originalTotalWeight)
        }

        for pillar in PillarID.allCases {
            guard let indexes = pillarIndexes[pillar], !indexes.isEmpty else { continue }
            if pillarsDropped.contains(pillar) { continue }
            guard let baseSum = pillarBaseSums[pillar], baseSum > 0 else {
                for idx in indexes { subcomponents[idx].blueprint.weight = 0 }
                continue
            }
            let targetWeight = weightProfile.weight(for: pillar)
            for idx in indexes {
                if subcomponents[idx].blueprint.dataAvailable {
                    let baseWeight = subcomponents[idx].blueprint.baseWeight
                    let calculatedWeight = (baseWeight / baseSum) * targetWeight
                    subcomponents[idx].blueprint.weight = max(calculatedWeight, Constants.minContributionWeight)
                } else {
                    subcomponents[idx].blueprint.weight = 0
                }
            }
        }

        let negativeComponents = subcomponents.filter { $0.bucket == .negative }
        let positiveComponents = subcomponents.filter { $0.bucket == .positive }

        let scaledNegative = scale(negativeComponents, maxRawTotal: Constants.maxNegativeRaw)
        let scaledPositive = scale(positiveComponents, maxRawTotal: Constants.maxPositiveRaw)

        let allPillarContributions = scaledNegative.contributions + scaledPositive.contributions
        let contributions = allPillarContributions.map { $0.contribution }

        let rawNegative = scaledNegative.rawTotal
        let rawPositive = scaledPositive.rawTotal
        let weightedNegative = scaledNegative.weightedTotal
        let weightedPositive = scaledPositive.weightedTotal
        let baseScore = 40 + weightedPositive - weightedNegative

        let missingCritical = determineMissingCriticalNutrients(from: subcomponents)

        let grouped = Dictionary(grouping: allPillarContributions, by: { $0.pillar })
        var pillarResults: [PillarResult] = []
        for pillar in PillarID.allCases {
            let pillarContributions = grouped[pillar]?.map { $0.contribution } ?? []
            let score: Double?
            if pillarsDropped.contains(pillar) {
                score = nil
            } else {
                let total = pillarContributions.reduce(0.0) { partial, contribution in
                    let signed = contribution.kind == .negative ? -contribution.weightedPoints : contribution.weightedPoints
                    return partial + signed
                }
                score = total
            }
            pillarResults.append(
                PillarResult(
                    id: pillar,
                    label: pillar.label,
                    contributions: pillarContributions,
                    score: score
                )
            )
        }

        return PillarEvaluation(
            contributions: contributions,
            rawNegativePoints: rawNegative,
            rawPositivePoints: rawPositive,
            weightedNegativePoints: weightedNegative,
            weightedPositivePoints: weightedPositive,
            baseScore: baseScore,
            missingCriticalNutrients: missingCritical,
            pillars: pillarResults,
            pillarsDropped: pillarsDropped,
            weightsProfileID: weightProfile.profileID,
            lensApplied: lensApplied
        )
    }

    private func energyContribution(energyKJ: Double?, availability: NutrientAvailability, isBeverage: Bool) -> ContributionBlueprint {
        let hasData = availability.contains(.energy)
        let dataAvailable = hasData && energyKJ != nil
        let config = thresholdLookup.energyConfig(isBeverage: isBeverage)
        let value = energyKJ ?? 0
        let rawPoints = dataAvailable ? pointsOverBaseline(value: value, baseline: config.baseline, step: config.step, maxPoints: config.maxPoints) : 0

        return ContributionBlueprint(
            kind: .negative,
            nutrient: .energy,
            label: "Energy density",
            rawPoints: rawPoints,
            maxPoints: config.maxPoints,
            baseWeight: config.weight,
            weight: config.weight,
            value: dataAvailable ? value : nil,
            unit: "kJ",
            explanation: dataAvailable ? "Adds 1 penalty per \(Int(config.step)) kJ above \(Int(config.baseline)) kJ per 100g." : "Energy data unavailable; no penalty applied.",
            guideline: config.guideline,
            dataAvailable: dataAvailable,
            modifiers: []
        )
    }

    private func sugarContribution(value: Double?, availability: NutrientAvailability, isBeverage: Bool, category: String?) -> ContributionBlueprint {
        let hasData = availability.contains(.sugar)
        let dataAvailable = hasData && value != nil
        let sugar = value ?? 0
        let config = thresholdLookup.sugarConfig(isBeverage: isBeverage, category: category)
        let rawPoints = dataAvailable ? pointsOverBaseline(value: sugar, baseline: config.baseline, step: config.step, maxPoints: config.maxPoints) : 0

        var modifiers: [String] = []
        if isBeverage {
            modifiers.append("Beverage thresholds applied (\(config.baseline) g steps)")
        }
        if let category = category, config.guideline.contains("Adjusted") {
            modifiers.append("Category-adjusted thresholds for \(category)")
        }

        return ContributionBlueprint(
            kind: .negative,
            nutrient: .sugars,
            label: "Total sugars",
            rawPoints: rawPoints,
            maxPoints: config.maxPoints,
            baseWeight: config.weight,
            weight: config.weight,
            value: dataAvailable ? sugar : nil,
            unit: "g",
            explanation: dataAvailable ? "Penalizes added sugars above \(config.baseline)g per 100g." : "Sugar data unavailable; no penalty applied.",
            guideline: config.guideline,
            dataAvailable: dataAvailable,
            modifiers: modifiers
        )
    }

    private func saturatedFatContribution(value: Double?, availability: NutrientAvailability, isBeverage: Bool) -> ContributionBlueprint {
        let hasData = availability.contains(.saturatedFat)
        let dataAvailable = hasData && value != nil
        let saturatedFat = value ?? 0
        let config = thresholdLookup.saturatedFatConfig(isBeverage: isBeverage)
        let rawPoints = dataAvailable ? pointsOverBaseline(value: saturatedFat, baseline: config.baseline, step: config.step, maxPoints: config.maxPoints) : 0

        return ContributionBlueprint(
            kind: .negative,
            nutrient: .saturatedFat,
            label: "Saturated fat",
            rawPoints: rawPoints,
            maxPoints: config.maxPoints,
            baseWeight: config.weight,
            weight: config.weight,
            value: dataAvailable ? saturatedFat : nil,
            unit: "g",
            explanation: dataAvailable ? "Adds 1 penalty per gram above \(config.baseline) g saturated fat." : "Saturated fat data unavailable; no penalty applied.",
            guideline: config.guideline,
            dataAvailable: dataAvailable,
            modifiers: []
        )
    }

    private func sodiumContribution(value: Double?, availability: NutrientAvailability, isBeverage: Bool, category: String?) -> ContributionBlueprint {
        let hasData = availability.contains(.sodium)
        let dataAvailable = hasData && value != nil
        let sodiumMg = (value ?? 0) * 1000
        let config = thresholdLookup.sodiumConfig(isBeverage: isBeverage, category: category)
        let rawPoints = dataAvailable ? pointsOverBaseline(value: sodiumMg, baseline: config.baseline, step: config.step, maxPoints: config.maxPoints) : 0

        var modifiers: [String] = []
        if isBeverage {
            modifiers.append("Beverage thresholds applied (\(Int(config.baseline)) mg steps)")
        }
        if let category = category, config.guideline.contains("Adjusted") {
            modifiers.append("Category-adjusted thresholds for \(category)")
        }

        return ContributionBlueprint(
            kind: .negative,
            nutrient: .sodium,
            label: "Sodium",
            rawPoints: rawPoints,
            maxPoints: config.maxPoints,
            baseWeight: config.weight,
            weight: config.weight,
            value: dataAvailable ? sodiumMg : nil,
            unit: "mg",
            explanation: dataAvailable ? "Penalizes sodium above \(Int(config.baseline)) mg per 100g." : "Sodium data unavailable; no penalty applied.",
            guideline: config.guideline,
            dataAvailable: dataAvailable,
            modifiers: modifiers
        )
    }

    private func fruitVegContribution(input: ScoringInput) -> ContributionBlueprint {
        let estimate = input.fruitVegEstimate
        let percentage = estimate.percentage ?? 0
        let dataAvailable = estimate.percentage != nil
        let config = thresholdLookup.fruitVegConfig(isBeverage: input.isBeverage)
        let rawPoints = dataAvailable ? pointsOverBaseline(value: percentage, baseline: config.baseline, step: config.step, maxPoints: config.maxPoints) : 0

        var modifiers: [String] = []
        switch estimate.method {
        case .explicitPercentage:
            modifiers.append("Explicit % on label")
        case .singleIngredientProduce:
            modifiers.append("Single-ingredient produce")
        case .primaryIngredientHeuristic:
            modifiers.append("Primary ingredient heuristic")
        case .presenceHeuristic:
            modifiers.append("Presence heuristic")
        case .unknown:
            modifiers.append("Produce percentage missing")
        }

        return ContributionBlueprint(
            kind: .positive,
            nutrient: .fruitVegLegumeNut,
            label: "Fruits/veg/legumes/nuts",
            rawPoints: rawPoints,
            maxPoints: config.maxPoints,
            baseWeight: config.weight,
            weight: config.weight,
            value: dataAvailable ? percentage : nil,
            unit: "%",
            explanation: dataAvailable ? "Rewards produce content above \(config.baseline)%." : "Produce percentage missing; no bonus applied.",
            guideline: config.guideline,
            dataAvailable: dataAvailable,
            modifiers: modifiers
        )
    }

    private func fiberContribution(value: Double?, availability: NutrientAvailability, isBeverage: Bool) -> ContributionBlueprint {
        let hasData = availability.contains(.fiber)
        let dataAvailable = hasData && value != nil
        let fiber = value ?? 0
        let config = thresholdLookup.fiberConfig(isBeverage: isBeverage)
        let rawPoints = dataAvailable ? pointsOverBaseline(value: fiber, baseline: config.baseline, step: config.step, maxPoints: config.maxPoints) : 0

        var modifiers: [String] = []
        if isBeverage {
            modifiers.append("Beverage thresholds applied (\(config.baseline) g steps)")
        }

        return ContributionBlueprint(
            kind: .positive,
            nutrient: .fiber,
            label: "Dietary fiber",
            rawPoints: rawPoints,
            maxPoints: config.maxPoints,
            baseWeight: config.weight,
            weight: config.weight,
            value: dataAvailable ? fiber : nil,
            unit: "g",
            explanation: dataAvailable ? "Rewards fiber above \(config.baseline)g per 100g." : "Fiber data unavailable; no bonus applied.",
            guideline: config.guideline,
            dataAvailable: dataAvailable,
            modifiers: modifiers
        )
    }

    private func proteinContribution(
        value: Double?,
        availability: NutrientAvailability,
        energyKJ: Double?,
        fruitVegPercent: Double?,
        isBeverage: Bool,
        sugar: Double?
    ) -> ContributionBlueprint {
        let hasData = availability.contains(.protein)
        let dataAvailable = hasData && value != nil
        let protein = value ?? 0
        let config = thresholdLookup.proteinConfig(isBeverage: isBeverage)
        var rawPoints = dataAvailable ? pointsOverBaseline(value: protein, baseline: config.baseline, step: config.step, maxPoints: config.maxPoints) : 0

        var modifiers: [String] = []
        let highEnergy = (energyKJ ?? 0) >= 670
        let lowProduce = (fruitVegPercent ?? 0) < 40
        if highEnergy && lowProduce && rawPoints > 5 {
            rawPoints = 5
            modifiers.append("Protein bonus capped due to energy-density")
        }

        if isBeverage,
           let sugar = sugar,
           let energyKJ = energyKJ,
           sugar <= Constants.hydrationSugarThreshold,
           energyKJ <= Constants.hydrationEnergyThreshold {
            rawPoints = max(rawPoints, 5)
            modifiers.append("Hydrating beverage bonus")
        }

        return ContributionBlueprint(
            kind: .positive,
            nutrient: .protein,
            label: "Protein",
            rawPoints: rawPoints,
            maxPoints: config.maxPoints,
            baseWeight: config.weight,
            weight: config.weight,
            value: dataAvailable ? protein : nil,
            unit: "g",
            explanation: dataAvailable ? "Rewards protein above \(config.baseline) g per 100g; caps prevent high-calorie loopholes." : "Protein data unavailable; no bonus applied.",
            guideline: config.guideline,
            dataAvailable: dataAvailable,
            modifiers: modifiers
        )
    }

    private func scale(_ components: [PillarSubcomponent], maxRawTotal: Int) -> (contributions: [PillarContribution], rawTotal: Int, weightedTotal: Double) {
        guard !components.isEmpty else {
            return ([], 0, 0)
        }

        let rawSum = components.reduce(0) { $0 + $1.blueprint.rawPoints }
        let target = min(rawSum, maxRawTotal)
        let scaling = (rawSum > 0 && rawSum > target) ? Double(target) / Double(rawSum) : 1.0

        let scaledValues = components.map { Double($0.blueprint.rawPoints) * scaling }
        let rawInts = distributeRounded(values: scaledValues, targetSum: target)

        var contributions: [PillarContribution] = []
        var weightedTotal: Double = 0

        for (index, component) in components.enumerated() {
            let blueprint = component.blueprint
            let raw = blueprint.dataAvailable ? rawInts[index] : 0
            let weighted = Double(raw) * blueprint.weight
            weightedTotal += weighted

            let contribution = NutrientContribution(
                kind: blueprint.kind,
                nutrient: blueprint.nutrient,
                label: blueprint.label,
                rawPoints: raw,
                weightedPoints: weighted,
                maxPoints: Double(blueprint.maxPoints),
                weightMultiplier: blueprint.weight,
                value: blueprint.dataAvailable ? blueprint.value : nil,
                unit: blueprint.unit,
                explanation: blueprint.explanation,
                guideline: blueprint.guideline,
                dataAvailable: blueprint.dataAvailable,
                modifiers: blueprint.modifiers
            )

            contributions.append(PillarContribution(pillar: component.pillar, contribution: contribution))
        }

        return (contributions, target, weightedTotal)
    }

    private func determineMissingCriticalNutrients(from subcomponents: [PillarSubcomponent]) -> [String] {
        var seen = Set<String>()
        var ordered: [String] = []
        for component in subcomponents where !component.blueprint.dataAvailable {
            if let label = missingLabel(for: component.blueprint.nutrient), !seen.contains(label) {
                seen.insert(label)
                ordered.append(label)
            }
        }
        return ordered
    }

    private func missingLabel(for nutrient: NutrientContribution.Nutrient) -> String? {
        switch nutrient {
        case .energy:
            return "energy"
        case .sugars:
            return "sugars"
        case .saturatedFat:
            return "saturated fat"
        case .sodium:
            return "sodium"
        case .fiber:
            return "fiber"
        case .protein:
            return "protein"
        case .fruitVegLegumeNut:
            return nil
        }
    }

    private func normalizedValue(_ keyPath: KeyPath<NutritionDensity.Snapshot, Double?>, input: ScoringInput) -> Double? {
        if input.isBeverage {
            if let value = input.density.per100ml?[keyPath: keyPath] {
                return value
            }
            if let per100g = input.density.per100g?[keyPath: keyPath] {
                return per100g
            }
            return input.density.perServing[keyPath: keyPath]
        }

        if let per100g = input.density.per100g?[keyPath: keyPath] {
            return per100g
        }

        return input.density.perServing[keyPath: keyPath]
    }

    private func distributeRounded(values: [Double], targetSum: Int) -> [Int] {
        guard !values.isEmpty else { return [] }

        var integers = values.map { Int(floor($0)) }
        var remainder = targetSum - integers.reduce(0, +)

        if remainder > 0 {
            let fractionalParts = values.enumerated()
                .map { ($0.offset, $0.element - floor($0.element)) }
                .sorted { $0.1 > $1.1 }

            for (index, _) in fractionalParts where remainder > 0 {
                integers[index] += 1
                remainder -= 1
            }
        }

        return integers
    }

    private func pointsOverBaseline(value: Double, baseline: Double, step: Double, maxPoints: Int) -> Int {
        guard value > baseline else { return 0 }
        let raw = Int(ceil((value - baseline) / step))
        return min(max(raw, 0), maxPoints)
    }
}
