import Foundation

struct ScoringInput {
    let product: ProductModel
    let nutrition: ProductNutrition
    let availability: NutrientAvailability
    let energyKJ: Double
    let isBeverage: Bool
    let fruitVegEstimate: FruitVegEstimate
    let normalizedServing: NormalizedServing
    let density: NutritionDensity
    let ingredientHits: [IngredientHit]
    let additiveHits: [AdditiveHit]
    let ingredientMatchResult: IngredientMatchResult

    var fruitVegPercent: Double? {
        fruitVegEstimate.percentage
    }
}

final class ScoringInputNormalizer {
    private let additiveLexicon: AdditiveLexiconAsset?
    private let additiveAliasLookup: [String: AdditiveLexiconAsset.Entry]

    init(additiveLexicon: AdditiveLexiconAsset? = try? AssetLoader.lexiconAdditives()) {
        self.additiveLexicon = additiveLexicon
        if let lexicon = additiveLexicon {
            var lookup: [String: AdditiveLexiconAsset.Entry] = [:]
            for entry in lexicon.entries {
                for alias in entry.aliases {
                    lookup[Self.normalizeAlias(alias)] = entry
                }
            }
            self.additiveAliasLookup = lookup
        } else {
            self.additiveAliasLookup = [:]
        }
    }

    func normalize(product: ProductModel) -> ScoringInput {
        let nutrition = product.nutrition
        let isBeverage = product.isLikelyBeverage
        let labelText = normalizedLabelText(from: nutrition)
        let basis = determineBasis(from: nutrition.servingSize, fallbackLabel: labelText, isBeverage: isBeverage)
        let parsedMass = extractMassInGrams(from: labelText)
        let parsedVolume = extractVolumeInMilliliters(from: labelText)

        var notes: [NormalizationNote] = []
        var missingFields: [NutritionDensity.MissingField] = []
        var availableMetrics: Set<NutritionDensity.DensityMetric> = [.perServing]
        var expectedMetrics: Set<NutritionDensity.DensityMetric> = []
        var confidence: NutritionDataConfidence = .low
        var per100gSnapshot: NutritionDensity.Snapshot?
        var per100mlSnapshot: NutritionDensity.Snapshot?

        let perServingSnapshot = buildSnapshot(from: nutrition)
        var normalizedServing = NormalizedServing(
            basis: basis,
            massInGrams: parsedMass,
            volumeInMilliliters: parsedVolume,
            labelText: labelText,
            massOrVolumeMissing: false
        )

        if labelText?.isEmpty ?? true {
            missingFields.append(.servingDescription)
        }

        if isBeverage {
            expectedMetrics.insert(.per100ml)
        } else {
            expectedMetrics.insert(.per100g)
        }

        switch basis {
        case .per100g:
            per100gSnapshot = perServingSnapshot
            confidence = .high
            availableMetrics.insert(.per100g)
        case .per100ml:
            per100mlSnapshot = perServingSnapshot
            confidence = .high
            availableMetrics.insert(.per100ml)
        case .perServing:
            if let grams = parsedMass, grams > 0 {
                per100gSnapshot = scaleSnapshot(perServingSnapshot, factor: 100.0 / grams)
                confidence = .medium
                availableMetrics.insert(.per100g)
                notes.append(.derivedFromLabelMass)
            } else if let milliliters = parsedVolume, milliliters > 0 {
                per100mlSnapshot = scaleSnapshot(perServingSnapshot, factor: 100.0 / milliliters)
                confidence = .medium
                availableMetrics.insert(.per100ml)
                notes.append(.derivedFromLabelVolume)

                // For beverages, assume 1 ml = 1 g for water-based drinks (density unknown)
                if isBeverage {
                    per100gSnapshot = scaleSnapshot(perServingSnapshot, factor: 100.0 / milliliters)
                    availableMetrics.insert(.per100g)
                    notes.append(.assumedWaterDensity)
                }
            } else {
                normalizedServing.massOrVolumeMissing = true
                confidence = .low
                notes.append(.fallbackPerServing)

                if isBeverage {
                    missingFields.append(.servingVolume)
                    notes.append(.beverageVolumeMissing)
                } else {
                    missingFields.append(.servingMass)
                    notes.append(.householdMeasureNoDensity)
                }
            }
        }

        if !normalizedServing.massOrVolumeMissing && basis == .perServing {
            normalizedServing.massOrVolumeMissing = (parsedMass == nil && parsedVolume == nil)
        }

        if basis != .perServing {
            confidence = .high
        }

        if parsedMass == nil && !isBeverage && basis != .per100g {
            missingFields.append(.servingMass)
        }

        if parsedVolume == nil && isBeverage && basis != .per100ml {
            missingFields.append(.servingVolume)
        }

        let skippedMetrics = expectedMetrics.subtracting(availableMetrics)

        let density = NutritionDensity(
            per100g: per100gSnapshot,
            per100ml: per100mlSnapshot,
            perServing: perServingSnapshot,
            dataConfidence: confidence,
            missingFields: uniqueOrdered(missingFields),
            notes: uniqueOrdered(notes),
            availableMetrics: orderedMetrics(from: availableMetrics),
            skippedMetrics: orderedMetrics(from: skippedMetrics)
        )

        let availability = nutrition.availability
        let energyKJ = nutrition.calories * 4.184
        let ingredientHits = buildIngredientHits(from: product.ingredients)
        let additiveHits = buildAdditiveHits(from: product.additives)

        let scoringInput = ScoringInput(
            product: product,
            nutrition: nutrition,
            availability: availability,
            energyKJ: energyKJ,
            isBeverage: isBeverage,
            fruitVegEstimate: product.fruitVegEstimate,
            normalizedServing: normalizedServing,
            density: density,
            ingredientHits: ingredientHits,
            additiveHits: additiveHits,
            ingredientMatchResult: IngredientMatchResult(
                containsRefinedOil: false,
                containsAdditive: false,
                containsNonNutritiveSweetener: false,
                containsFlavorOrColor: false,
                containsUltraProcessedMarker: false,
                matchedAdditives: [],
                firstIngredientCategory: .unknown
            )
        )

        let normalizedProduct = NormalizedProduct(input: scoringInput)
        let ingredientMatchResult = IngredientMatchService.shared.analyze(product: normalizedProduct)

        return ScoringInput(
            product: product,
            nutrition: nutrition,
            availability: availability,
            energyKJ: energyKJ,
            isBeverage: isBeverage,
            fruitVegEstimate: product.fruitVegEstimate,
            normalizedServing: normalizedServing,
            density: density,
            ingredientHits: ingredientHits,
            additiveHits: additiveHits,
            ingredientMatchResult: ingredientMatchResult
        )
    }

    private func buildIngredientHits(from ingredients: [String]) -> [IngredientHit] {
        let analyses = IngredientAnalyzer.shared.analyze(ingredients: ingredients)
        return analyses.map {
            IngredientHit(
                originalName: $0.originalName,
                normalizedName: $0.normalizedName,
                category: $0.category,
                position: $0.position
            )
        }
    }

    private func buildAdditiveHits(from additives: [String]) -> [AdditiveHit] {
        additives.map { additiveHit(for: $0) }
    }

    private func additiveHit(for additive: String) -> AdditiveHit {
        let normalized = Self.normalizeAlias(additive)

        if let entry = additiveAliasLookup[normalized], let lexicon = additiveLexicon {
            let risk = AdditiveRiskLevel(rawValue: entry.riskLevel.rawValue) ?? .unknown
            let identifier = "\(lexicon.metadata.id)#\(lexicon.metadata.version)::\(entry.id)"
            return AdditiveHit(
                originalName: additive,
                displayName: entry.displayName,
                normalizedName: normalized,
                lexiconIdentifier: identifier,
                riskLevel: risk
            )
        }

        return AdditiveHit(
            originalName: additive,
            displayName: additive,
            normalizedName: normalized,
            lexiconIdentifier: nil,
            riskLevel: .unknown
        )
    }

    private func normalizedLabelText(from nutrition: ProductNutrition) -> String? {
        if let label = nutrition.labelServingSize, !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return label
        }
        let trimmed = nutrition.servingSize.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func determineBasis(from servingSize: String, fallbackLabel: String?, isBeverage: Bool) -> NormalizedServing.Basis {
        let candidates = [servingSize, fallbackLabel ?? ""]
            .map { $0.lowercased() }

        for candidate in candidates {
            if candidate.contains("100ml") || candidate.contains("100 ml") {
                return .per100ml
            }
            if candidate.contains("100g") || candidate.contains("100 g") {
                return .per100g
            }
        }

        if isBeverage {
            return .perServing
        }

        return .perServing
    }

    private func extractMassInGrams(from text: String?) -> Double? {
        guard let text else { return nil }
        return firstMatch(in: text, patterns: [
            "(\\d+(?:\\.\\d+)?)\\s?(?:g|grams?)",
            "(\\d+(?:\\.\\d+)?)\\s?(?:gram)"
        ])
    }

    private func extractVolumeInMilliliters(from text: String?) -> Double? {
        guard let text else { return nil }

        if let milliliters = firstMatch(in: text, patterns: ["(\\d+(?:\\.\\d+)?)\\s?(?:ml|milliliters?)"]) {
            return milliliters
        }

        if let liters = firstMatch(in: text, patterns: ["(\\d+(?:\\.\\d+)?)\\s?(?:l|liters?)"]) {
            return liters * 1000
        }

        return nil
    }

    private func firstMatch(in text: String, patterns: [String]) -> Double? {
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(text.startIndex..<text.endIndex, in: text)
                if let match = regex.firstMatch(in: text, options: [], range: range), match.numberOfRanges > 1,
                   let matchRange = Range(match.range(at: 1), in: text) {
                    let valueString = String(text[matchRange]).replacingOccurrences(of: ",", with: "")
                    if let value = Double(valueString) {
                        return value
                    }
                }
            }
        }
        return nil
    }

    private func buildSnapshot(from nutrition: ProductNutrition) -> NutritionDensity.Snapshot {
        NutritionDensity.Snapshot(
            calories: nutrition.calories,
            protein: nutrition.protein,
            carbohydrates: nutrition.carbohydrates,
            fat: nutrition.fat,
            saturatedFat: nutrition.saturatedFat,
            fiber: nutrition.fiber,
            sugar: nutrition.sugar,
            sodium: nutrition.sodium,
            cholesterol: nutrition.cholesterol
        )
    }

    private func scaleSnapshot(_ snapshot: NutritionDensity.Snapshot, factor: Double) -> NutritionDensity.Snapshot {
        NutritionDensity.Snapshot(
            calories: snapshot.calories.map { $0 * factor },
            protein: snapshot.protein.map { $0 * factor },
            carbohydrates: snapshot.carbohydrates.map { $0 * factor },
            fat: snapshot.fat.map { $0 * factor },
            saturatedFat: snapshot.saturatedFat.map { $0 * factor },
            fiber: snapshot.fiber.map { $0 * factor },
            sugar: snapshot.sugar.map { $0 * factor },
            sodium: snapshot.sodium.map { $0 * factor },
            cholesterol: snapshot.cholesterol.map { $0 * factor }
        )
    }

    private static func normalizeAlias(_ alias: String) -> String {
        alias.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func uniqueOrdered<T: Hashable>(_ items: [T]) -> [T] {
        var seen = Set<T>()
        var ordered: [T] = []
        for item in items {
            if seen.insert(item).inserted {
                ordered.append(item)
            }
        }
        return ordered
    }

    private func orderedMetrics(from set: Set<NutritionDensity.DensityMetric>) -> [NutritionDensity.DensityMetric] {
        let order: [NutritionDensity.DensityMetric] = [.per100g, .per100ml, .perServing]
        return order.filter { set.contains($0) }
    }
}
