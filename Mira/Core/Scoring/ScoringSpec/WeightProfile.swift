import Foundation

struct WeightProfile {
    private(set) var weights: [PillarID: Double]
    let profileID: String
    var lensApplied: Bool

    private init(weights: [PillarID: Double], profileID: String, lensApplied: Bool = false) {
        self.weights = weights
        self.profileID = profileID
        self.lensApplied = lensApplied
    }

    static func profile(for product: NormalizedProduct) -> WeightProfile {
        var weights: [PillarID: Double]
        var profileID: String

        // Always use general wellness profile (health focus removed)
        weights = [
            .p1Sugar: 30,
            .p2Sodium: 20,
            .p3MetabolicLoad: 25,
            .p4PositiveNutrition: 25
        ]
        profileID = "weights.general_wellness"

        if product.isBeverage {
            weights[.p1Sugar] = (weights[.p1Sugar] ?? 25) * 0.85
            weights[.p2Sodium] = (weights[.p2Sodium] ?? 15) * 0.75
            weights[.p3MetabolicLoad] = (weights[.p3MetabolicLoad] ?? 20) * 0.8
            weights[.p4PositiveNutrition] = (weights[.p4PositiveNutrition] ?? 40) * 1.6
            profileID = "\(profileID).beverages"
        } else if let slug = product.categorySlug?.lowercased(), slug.contains("snack") {
            weights[.p1Sugar] = (weights[.p1Sugar] ?? 30) * 1.15
            weights[.p2Sodium] = (weights[.p2Sodium] ?? 20) * 1.25
            weights[.p3MetabolicLoad] = (weights[.p3MetabolicLoad] ?? 25) * 1.0
            weights[.p4PositiveNutrition] = (weights[.p4PositiveNutrition] ?? 25) * 0.6
            profileID = "\(profileID).snacks"
        }

        return WeightProfile(weights: weights, profileID: profileID)
    }

    func totalWeight() -> Double {
        weights.values.reduce(0, +)
    }

    func weight(for pillar: PillarID) -> Double {
        weights[pillar] ?? 0
    }

    mutating func updateWeight(for pillar: PillarID, to value: Double) {
        weights[pillar] = value
    }

    mutating func scale(pillar: PillarID, factor: Double) {
        guard let current = weights[pillar] else { return }
        weights[pillar] = current * factor
    }

    mutating func clamp(min minValue: Double, max maxValue: Double) {
        for pillar in PillarID.allCases {
            guard let value = weights[pillar] else { continue }
            weights[pillar] = min(max(value, minValue), maxValue)
        }
    }

    mutating func renormalize(total: Double = 100.0) {
        let currentTotal = totalWeight()
        guard currentTotal > 0 else { return }
        let scale = total / currentTotal
        for pillar in PillarID.allCases {
            if let value = weights[pillar] {
                weights[pillar] = value * scale
            }
        }
    }
}

struct LensAdjuster {
    private let minWeight: Double = 5
    private let maxWeight: Double = 60

    @discardableResult
    func apply(profile: inout WeightProfile, product: NormalizedProduct) -> Bool {
        var applied = false

        if product.isBeverage {
        profile.scale(pillar: .p3MetabolicLoad, factor: 0.9)
        profile.scale(pillar: .p4PositiveNutrition, factor: 1.1)
        applied = true
    }

        let matchResult = product.ingredientMatchResult
        if matchResult.containsRefinedOil || matchResult.containsNonNutritiveSweetener || matchResult.containsUltraProcessedMarker {
            profile.scale(pillar: .p4PositiveNutrition, factor: 0.9)
            profile.scale(pillar: .p1Sugar, factor: 1.1)
            applied = true
        }

        profile.clamp(min: minWeight, max: maxWeight)
        profile.renormalize()
        profile.lensApplied = applied
        return applied
    }
}
