import SwiftUI

struct HealthFocusOption: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let isSystemIcon: Bool
    let tint: Color

    static let all: [HealthFocusOption] = [
        HealthFocusOption(
            id: "generalWellness",
            title: "General Wellness",
            description: "Balanced nutrition guidance for everyday healthy habits.",
            icon: "stethoscope",
            isSystemIcon: true,
            tint: .primaryBlue
        ),
        HealthFocusOption(
            id: "gutHealth",
            title: "Gut Health",
            description: "Support digestion and improve microbiome balance.",
            icon: "circle.hexagongrid.fill",
            isSystemIcon: true,
            tint: .mint
        ),
        HealthFocusOption(
            id: "heartHealth",
            title: "Heart Health",
            description: "Optimized for cardiovascular health. Prioritizes low cholesterol, high fiber, and heart-healthy fats.",
            icon: "heart.fill",
            isSystemIcon: true,
            tint: .error
        ),
        HealthFocusOption(
            id: "proteinFocus",
            title: "Protein Focus",
            description: "Highlight higher-protein choices to fuel your body.",
            icon: "figure.strengthtraining.traditional",
            isSystemIcon: true,
            tint: .purple
        ),
        HealthFocusOption(
            id: "weightLoss",
            title: "Weight Loss",
            description: "Prioritize lower calories and smarter portion sizes.",
            icon: "figure.walk",
            isSystemIcon: true,
            tint: .orange
        )
    ]

    static func option(for id: String) -> HealthFocusOption? {
        all.first { $0.id == id }
    }
}

struct DietaryRestrictionOption: Identifiable, Equatable {
    let id: String
    let title: String
    let icon: String

    static let all: [DietaryRestrictionOption] = [
        DietaryRestrictionOption(id: "vegan", title: "Vegan", icon: "leaf.fill"),
        DietaryRestrictionOption(id: "vegetarian", title: "Vegetarian", icon: "carrot"),
        DietaryRestrictionOption(id: "glutenFree", title: "Gluten-Free", icon: "circle.grid.cross.fill"),
        DietaryRestrictionOption(id: "dairyFree", title: "Dairy-Free", icon: "waterbottle.fill"),
        DietaryRestrictionOption(id: "nutFree", title: "Nut-Free", icon: "circle.hexagongrid.circle.fill"),
        DietaryRestrictionOption(id: "none", title: "None", icon: "checkmark.circle")
    ]
}
