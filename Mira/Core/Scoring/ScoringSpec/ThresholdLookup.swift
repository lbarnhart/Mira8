import Foundation

struct ThresholdConfig {
    let baseline: Double
    let step: Double
    let maxPoints: Int
    let weight: Double
    let guideline: String
}

final class ThresholdLookup {
    static let shared = ThresholdLookup()

    private let asset: ThresholdAsset?
    private let thresholdMap: [String: ThresholdAsset.Threshold]

    init(asset: ThresholdAsset? = try? AssetLoader.thresholds()) {
        self.asset = asset
        if let thresholds = asset?.thresholds {
            var map: [String: ThresholdAsset.Threshold] = [:]
            for threshold in thresholds {
                map[threshold.id] = threshold
            }
            self.thresholdMap = map
        } else {
            self.thresholdMap = [:]
        }
    }

    func config(for id: String, isBeverage: Bool = false) -> ThresholdConfig? {
        guard let threshold = thresholdMap[id] else {
            return nil
        }

        if isBeverage, let beverageContext = threshold.contexts.first(where: { $0.id == "beverage" }) {
            return ThresholdConfig(
                baseline: beverageContext.baseline ?? threshold.baseline,
                step: beverageContext.step ?? threshold.step,
                maxPoints: beverageContext.maxPoints ?? threshold.maxPoints,
                weight: beverageContext.weight ?? threshold.weight,
                guideline: threshold.guideline
            )
        }

        return ThresholdConfig(
            baseline: threshold.baseline,
            step: threshold.step,
            maxPoints: threshold.maxPoints,
            weight: threshold.weight,
            guideline: threshold.guideline
        )
    }

    func energyConfig(isBeverage: Bool = false) -> ThresholdConfig {
        config(for: "negative.energy_density", isBeverage: isBeverage) ?? ThresholdConfig(
            baseline: 335.0,
            step: 335.0,
            maxPoints: 10,
            weight: 1.5,
            guideline: "WHO encourages limiting energy-dense packaged foods."
        )
    }

    func sugarConfig(isBeverage: Bool = false, category: String? = nil) -> ThresholdConfig {
        // Use category-adjusted thresholds if available
        if let category = category {
            let profile = CategoryAdjustments.adjustedThresholds(for: category)
            let thresholds = profile.sugarThresholds
            return ThresholdConfig(
                baseline: thresholds.baseline,
                step: thresholds.step,
                maxPoints: 15,
                weight: 3.0,
                guideline: "Adjusted for \(category) category"
            )
        }
        
        // Fallback to standard thresholds
        return config(for: "negative.total_sugars", isBeverage: isBeverage) ?? ThresholdConfig(
            baseline: isBeverage ? 2.25 : 4.5,
            step: isBeverage ? 2.25 : 4.5,
            maxPoints: 15,
            weight: 3.0,
            guideline: "WHO guidance: keep free sugars <10% of energy."
        )
    }

    func saturatedFatConfig(isBeverage: Bool = false) -> ThresholdConfig {
        config(for: "negative.saturated_fat", isBeverage: isBeverage) ?? ThresholdConfig(
            baseline: 1.0,
            step: 1.0,
            maxPoints: 15,
            weight: 2.5,
            guideline: "AHA recommends keeping saturated fat under 6% of calories."
        )
    }

    func sodiumConfig(isBeverage: Bool = false, category: String? = nil) -> ThresholdConfig {
        // Use category-adjusted thresholds if available
        if let category = category {
            let profile = CategoryAdjustments.adjustedThresholds(for: category)
            let thresholds = profile.sodiumThresholds
            return ThresholdConfig(
                baseline: thresholds.baseline,
                step: thresholds.step,
                maxPoints: 20,
                weight: 2.0,
                guideline: "Adjusted for \(category) category"
            )
        }
        
        // Fallback to standard thresholds
        return config(for: "negative.sodium", isBeverage: isBeverage) ?? ThresholdConfig(
            baseline: isBeverage ? 45.0 : 90.0,
            step: isBeverage ? 45.0 : 90.0,
            maxPoints: 20,
            weight: 2.0,
            guideline: "US Dietary Guidelines cap sodium at 2300 mg/day (~460 mg per meal)."
        )
    }

    func fruitVegConfig(isBeverage: Bool = false) -> ThresholdConfig {
        config(for: "positive.fruit_veg", isBeverage: isBeverage) ?? ThresholdConfig(
            baseline: 40.0,
            step: 7.5,
            maxPoints: 20,
            weight: 4.5,
            guideline: "Modeled after Nutri-Score produce thresholds."
        )
    }

    func fiberConfig(isBeverage: Bool = false) -> ThresholdConfig {
        config(for: "positive.fiber", isBeverage: isBeverage) ?? ThresholdConfig(
            baseline: isBeverage ? 0.45 : 0.9,
            step: isBeverage ? 0.45 : 0.9,
            maxPoints: 10,
            weight: 3.0,
            guideline: "Most adults need about 28 g of fiber daily (~1 g per 100g)."
        )
    }

    func proteinConfig(isBeverage: Bool = false) -> ThresholdConfig {
        config(for: "positive.protein", isBeverage: isBeverage) ?? ThresholdConfig(
            baseline: 1.6,
            step: 1.6,
            maxPoints: 10,
            weight: 2.0,
            guideline: "Supports satiety and aligns with EFSA protein density guidance."
        )
    }
}
