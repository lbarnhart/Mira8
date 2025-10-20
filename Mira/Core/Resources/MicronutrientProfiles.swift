import Foundation

struct MicronutrientProfile {
    let vitaminA: Double?
    let vitaminC: Double?
    let vitaminK: Double?
    let folate: Double?
    let calcium: Double?
    let iron: Double?
    let magnesium: Double?
    let potassium: Double?
}

struct MicronutrientProfiles {
    static let profiles: [String: MicronutrientProfile] = [
        "spinach": MicronutrientProfile(
            vitaminA: 469.0,
            vitaminC: 28.1,
            vitaminK: 482.9,
            folate: 194.0,
            calcium: 99.0,
            iron: 2.7,
            magnesium: 79.0,
            potassium: 558.0
        ),
        "kale": MicronutrientProfile(
            vitaminA: 500.0,
            vitaminC: 120.0,
            vitaminK: 390.0,
            folate: 141.0,
            calcium: 150.0,
            iron: 1.5,
            magnesium: 47.0,
            potassium: 491.0
        ),
        "broccoli": MicronutrientProfile(
            vitaminA: 31.0,
            vitaminC: 89.2,
            vitaminK: 101.6,
            folate: 63.0,
            calcium: 47.0,
            iron: 0.7,
            magnesium: 21.0,
            potassium: 316.0
        ),
        "carrot": MicronutrientProfile(
            vitaminA: 835.0,
            vitaminC: 5.9,
            vitaminK: 13.2,
            folate: 19.0,
            calcium: 33.0,
            iron: 0.3,
            magnesium: 12.0,
            potassium: 320.0
        ),
        "sweet potato": MicronutrientProfile(
            vitaminA: 709.0,
            vitaminC: 2.4,
            vitaminK: 1.8,
            folate: 11.0,
            calcium: 30.0,
            iron: 0.6,
            magnesium: 25.0,
            potassium: 337.0
        ),
        "tomato": MicronutrientProfile(
            vitaminA: 42.0,
            vitaminC: 13.7,
            vitaminK: 7.9,
            folate: 15.0,
            calcium: 10.0,
            iron: 0.3,
            magnesium: 11.0,
            potassium: 237.0
        ),
        "blueberry": MicronutrientProfile(
            vitaminA: 3.0,
            vitaminC: 9.7,
            vitaminK: 19.3,
            folate: 6.0,
            calcium: 6.0,
            iron: 0.3,
            magnesium: 6.0,
            potassium: 77.0
        ),
        "strawberry": MicronutrientProfile(
            vitaminA: 1.0,
            vitaminC: 58.8,
            vitaminK: 2.2,
            folate: 24.0,
            calcium: 16.0,
            iron: 0.4,
            magnesium: 13.0,
            potassium: 153.0
        ),
        "orange": MicronutrientProfile(
            vitaminA: 11.0,
            vitaminC: 53.2,
            vitaminK: 0.0,
            folate: 30.0,
            calcium: 40.0,
            iron: 0.1,
            magnesium: 10.0,
            potassium: 181.0
        ),
        "banana": MicronutrientProfile(
            vitaminA: 3.0,
            vitaminC: 8.7,
            vitaminK: 0.5,
            folate: 20.0,
            calcium: 5.0,
            iron: 0.3,
            magnesium: 27.0,
            potassium: 358.0
        ),
        "avocado": MicronutrientProfile(
            vitaminA: 7.0,
            vitaminC: 10.0,
            vitaminK: 21.0,
            folate: 81.0,
            calcium: 12.0,
            iron: 0.6,
            magnesium: 29.0,
            potassium: 485.0
        ),
        "almond": MicronutrientProfile(
            vitaminA: 0.0,
            vitaminC: 0.0,
            vitaminK: 0.0,
            folate: 44.0,
            calcium: 269.0,
            iron: 3.7,
            magnesium: 270.0,
            potassium: 733.0
        ),
        "chickpea": MicronutrientProfile(
            vitaminA: 3.0,
            vitaminC: 1.3,
            vitaminK: 4.0,
            folate: 172.0,
            calcium: 49.0,
            iron: 2.9,
            magnesium: 48.0,
            potassium: 291.0
        ),
        "lentil": MicronutrientProfile(
            vitaminA: 2.0,
            vitaminC: 1.5,
            vitaminK: 1.7,
            folate: 181.0,
            calcium: 19.0,
            iron: 3.3,
            magnesium: 36.0,
            potassium: 369.0
        ),
        "salmon": MicronutrientProfile(
            vitaminA: 40.0,
            vitaminC: 0.0,
            vitaminK: 0.0,
            folate: 25.0,
            calcium: 9.0,
            iron: 0.3,
            magnesium: 27.0,
            potassium: 363.0
        ),
        "chicken breast": MicronutrientProfile(
            vitaminA: 5.0,
            vitaminC: 0.0,
            vitaminK: 0.0,
            folate: 4.0,
            calcium: 5.0,
            iron: 0.4,
            magnesium: 26.0,
            potassium: 256.0
        ),
        "egg": MicronutrientProfile(
            vitaminA: 160.0,
            vitaminC: 0.0,
            vitaminK: 0.3,
            folate: 44.0,
            calcium: 50.0,
            iron: 1.2,
            magnesium: 10.0,
            potassium: 126.0
        ),
        "eggs": MicronutrientProfile(
            vitaminA: 160.0,
            vitaminC: 0.0,
            vitaminK: 0.3,
            folate: 44.0,
            calcium: 50.0,
            iron: 1.2,
            magnesium: 10.0,
            potassium: 126.0
        ),
        "quinoa": MicronutrientProfile(
            vitaminA: 1.0,
            vitaminC: 0.0,
            vitaminK: 0.0,
            folate: 42.0,
            calcium: 17.0,
            iron: 1.5,
            magnesium: 64.0,
            potassium: 172.0
        )
    ]

    static func lookup(ingredient: String) -> MicronutrientProfile? {
        let normalized = ingredient.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        for (key, profile) in profiles {
            if normalized.contains(key) {
                return profile
            }
        }
        return nil
    }
}
