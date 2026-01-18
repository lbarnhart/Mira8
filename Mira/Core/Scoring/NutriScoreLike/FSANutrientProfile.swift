import Foundation

struct FSAPointThreshold {
    let value: Double
    let points: Int
}

struct FSANutrientThresholds {
    let energyPoints: [FSAPointThreshold]
    let satFatPoints: [FSAPointThreshold]
    let sodiumPoints: [FSAPointThreshold]
    let sugarPoints: [FSAPointThreshold]
    let fiberPoints: [FSAPointThreshold]
    let proteinPoints: [FSAPointThreshold]
    
    static let standard = FSANutrientThresholds(
        energyPoints: [
            FSAPointThreshold(value: 335, points: 0),
            FSAPointThreshold(value: 670, points: 1),
            FSAPointThreshold(value: 1005, points: 2),
            FSAPointThreshold(value: 1340, points: 3),
            FSAPointThreshold(value: 1675, points: 4),
            FSAPointThreshold(value: 2010, points: 5),
            FSAPointThreshold(value: 2345, points: 6),
            FSAPointThreshold(value: 2680, points: 7),
            FSAPointThreshold(value: 3015, points: 8),
            FSAPointThreshold(value: 3350, points: 9),
            FSAPointThreshold(value: 3685, points: 10),
        ],
        satFatPoints: [
            FSAPointThreshold(value: 1.0, points: 0),
            FSAPointThreshold(value: 2.0, points: 1),
            FSAPointThreshold(value: 3.0, points: 2),
            FSAPointThreshold(value: 4.0, points: 3),
            FSAPointThreshold(value: 5.0, points: 4),
            FSAPointThreshold(value: 6.0, points: 5),
            FSAPointThreshold(value: 7.0, points: 6),
            FSAPointThreshold(value: 8.0, points: 7),
            FSAPointThreshold(value: 9.0, points: 8),
            FSAPointThreshold(value: 10.0, points: 9),
            FSAPointThreshold(value: 11.0, points: 10),
        ],
        sodiumPoints: [
            FSAPointThreshold(value: 90, points: 0),
            FSAPointThreshold(value: 180, points: 1),
            FSAPointThreshold(value: 270, points: 2),
            FSAPointThreshold(value: 360, points: 3),
            FSAPointThreshold(value: 450, points: 4),
            FSAPointThreshold(value: 540, points: 5),
            FSAPointThreshold(value: 630, points: 6),
            FSAPointThreshold(value: 720, points: 7),
            FSAPointThreshold(value: 810, points: 8),
            FSAPointThreshold(value: 900, points: 9),
            FSAPointThreshold(value: 990, points: 10),
        ],
        sugarPoints: [
            FSAPointThreshold(value: 4.5, points: 0),
            FSAPointThreshold(value: 9.0, points: 1),
            FSAPointThreshold(value: 13.5, points: 2),
            FSAPointThreshold(value: 18.0, points: 3),
            FSAPointThreshold(value: 22.5, points: 4),
            FSAPointThreshold(value: 27.0, points: 5),
            FSAPointThreshold(value: 31.0, points: 6),
            FSAPointThreshold(value: 36.0, points: 7),
            FSAPointThreshold(value: 40.0, points: 8),
            FSAPointThreshold(value: 45.0, points: 9),
            FSAPointThreshold(value: 50.0, points: 10),
        ],
        fiberPoints: [
            FSAPointThreshold(value: 0.9, points: 0),
            FSAPointThreshold(value: 1.9, points: 1),
            FSAPointThreshold(value: 2.8, points: 2),
            FSAPointThreshold(value: 3.7, points: 3),
            FSAPointThreshold(value: 4.7, points: 4),
            FSAPointThreshold(value: 5.6, points: 5),
            FSAPointThreshold(value: 6.5, points: 6),
            FSAPointThreshold(value: 7.4, points: 7),
            FSAPointThreshold(value: 8.4, points: 8),
            FSAPointThreshold(value: 9.3, points: 9),
            FSAPointThreshold(value: 10.0, points: 10),
        ],
        proteinPoints: [
            FSAPointThreshold(value: 1.6, points: 0),
            FSAPointThreshold(value: 3.2, points: 1),
            FSAPointThreshold(value: 4.8, points: 2),
            FSAPointThreshold(value: 6.4, points: 3),
            FSAPointThreshold(value: 8.0, points: 4),
            FSAPointThreshold(value: 9.6, points: 5),
            FSAPointThreshold(value: 11.2, points: 6),
            FSAPointThreshold(value: 12.8, points: 7),
            FSAPointThreshold(value: 14.4, points: 8),
            FSAPointThreshold(value: 16.0, points: 9),
            FSAPointThreshold(value: 17.0, points: 10),
        ]
    )
}

enum FSACategory: String, CaseIterable {
    case general
    case beverage
    case cheese
    case oil
    case butter
}

struct FSAProfileOverride {
    let category: FSACategory
    let energyMultiplier: Double?
    let satFatMultiplier: Double?
    let sugarMultiplier: Double?
    let sodiumMultiplier: Double?
}

class FSANutrientProfile {
    let thresholds: FSANutrientThresholds
    let overrides: [FSAProfileOverride]
    
    init(thresholds: FSANutrientThresholds = .standard) {
        self.thresholds = thresholds
        self.overrides = [
            FSAProfileOverride(category: .beverage, energyMultiplier: 0.5, satFatMultiplier: nil, sugarMultiplier: 1.5, sodiumMultiplier: nil),
            FSAProfileOverride(category: .cheese, energyMultiplier: 1.0, satFatMultiplier: 1.2, sugarMultiplier: 0.0, sodiumMultiplier: 1.1),
            FSAProfileOverride(category: .oil, energyMultiplier: 1.5, satFatMultiplier: 1.5, sugarMultiplier: 0.0, sodiumMultiplier: 0.0),
            FSAProfileOverride(category: .butter, energyMultiplier: 1.5, satFatMultiplier: 1.5, sugarMultiplier: 0.0, sodiumMultiplier: 0.0),
        ]
    }
    
    func pointsForEnergy(_ kcal: Double, category: FSACategory = .general) -> Int {
        let value = category == .beverage ? kcal * 0.5 : kcal
        return pointsForThreshold(value, thresholds: thresholds.energyPoints)
    }
    
    func pointsForSaturatedFat(_ grams: Double, category: FSACategory = .general) -> Int {
        let multiplier = overrides.first(where: { $0.category == category })?.satFatMultiplier ?? 1.0
        return pointsForThreshold(grams * multiplier, thresholds: thresholds.satFatPoints)
    }
    
    func pointsForSodium(_ mg: Double, category: FSACategory = .general) -> Int {
        let multiplier = overrides.first(where: { $0.category == category })?.sodiumMultiplier ?? 1.0
        return pointsForThreshold(mg * multiplier, thresholds: thresholds.sodiumPoints)
    }
    
    func pointsForSugar(_ grams: Double, category: FSACategory = .general) -> Int {
        let multiplier = overrides.first(where: { $0.category == category })?.sugarMultiplier ?? 1.0
        return pointsForThreshold(grams * multiplier, thresholds: thresholds.sugarPoints)
    }
    
    func pointsForFiber(_ grams: Double) -> Int {
        return -pointsForThreshold(grams, thresholds: thresholds.fiberPoints)
    }
    
    func pointsForProtein(_ grams: Double) -> Int {
        return -pointsForThreshold(grams, thresholds: thresholds.proteinPoints)
    }
    
    private func pointsForThreshold(_ value: Double, thresholds: [FSAPointThreshold]) -> Int {
        guard let threshold = thresholds.last(where: { $0.value <= value }) else {
            return thresholds.first?.points ?? 0
        }
        return threshold.points
    }
}
