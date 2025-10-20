import SwiftUI

struct IngredientsAnalysisView: View {
    let items: [IngredientItem]
    let rawText: String?

    @State private var showAllIngredients = false
    @State private var showRawText = false
    @State private var selectedIngredient: IngredientItem?

    private var totalCount: Int { items.count }
    private var beneficialItems: [IngredientItem] { items.filter { $0.category == .beneficial }.sorted { $0.position < $1.position } }
    private var neutralItems: [IngredientItem] { items.filter { $0.category == .neutral }.sorted { $0.position < $1.position } }
    private var concerningItems: [IngredientItem] { items.filter { $0.category == .concerning }.sorted { $0.position < $1.position } }
    private var unknownItems: [IngredientItem] { items.filter { $0.category == .unknown }.sorted { $0.position < $1.position } }

    private var concerningPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return (Double(concerningItems.count) / Double(totalCount)) * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            IngredientSummaryCard(
                totalCount: totalCount,
                beneficialCount: beneficialItems.count,
                neutralCount: neutralItems.count,
                concerningCount: concerningItems.count,
                unknownCount: unknownItems.count,
                concerningPercentage: concerningPercentage
            )

            if !concerningItems.isEmpty {
                ConcerningIngredientsSection(
                    items: Array(concerningItems.prefix(5)),
                    onSelect: { selectedIngredient = $0 }
                )
            }

            if beneficialItems.count >= 3 {
                BeneficialHighlightSection(items: Array(beneficialItems.prefix(5)))
            }

            if totalCount > 0 {
                DisclosureGroup(isExpanded: $showAllIngredients) {
                    IngredientCategoryList(
                        groupedItems: groupedByCategory,
                        onSelect: { selectedIngredient = $0 }
                    )
                    .padding(.top, Spacing.sm)
                } label: {
                    Text(showAllIngredients ? "Hide all ingredients" : "Show all \(totalCount) ingredients")
                        .font(.bodyMedium)
                        .foregroundColor(.primaryBlue)
                }
                .padding(.horizontal, Spacing.md)
            }

            if let rawText, !rawText.isEmpty {
                DisclosureGroup(isExpanded: $showRawText) {
                    Text(rawText)
                        .font(.callout)
                        .foregroundColor(.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Spacing.xs)
                } label: {
                    Text(showRawText ? "Hide full ingredient list" : "Full ingredient list")
                        .font(.bodyMedium)
                        .foregroundColor(.primaryBlue)
                }
                .padding(.horizontal, Spacing.md)
            }

            if totalCount == 0 && (rawText?.isEmpty ?? true) {
                MissingIngredientsInfo()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Spacing.md)
        .background(Color.clear)
        .sheet(item: $selectedIngredient) { ingredient in
            IngredientDetailSheet(ingredient: ingredient)
                .presentationDetents([.medium])
        }
    }

    private var groupedByCategory: [(IngredientCategory, [IngredientItem])] {
        [
            (.beneficial, beneficialItems),
            (.concerning, concerningItems),
            (.neutral, neutralItems),
            (.unknown, unknownItems)
        ].compactMap { category, list in
            guard !list.isEmpty else { return nil }
            return (category, list)
        }
    }
}

#Preview {
    let sampleItems = [
        IngredientItem(analysis: IngredientAnalysis(originalName: "whole grain oats", displayName: "Whole Grain Oats", normalizedName: "whole grain oats", category: .beneficial, explanation: "Rich in fiber and supports steady energy.", position: 1)),
        IngredientItem(analysis: IngredientAnalysis(originalName: "sugar", displayName: "Sugar", normalizedName: "sugar", category: .concerning, explanation: "High in added sugars which can spike blood sugar.", position: 2)),
        IngredientItem(analysis: IngredientAnalysis(originalName: "inulin", displayName: "Inulin", normalizedName: "inulin", category: .beneficial, explanation: "Prebiotic fiber that supports gut health.", position: 3)),
        IngredientItem(analysis: IngredientAnalysis(originalName: "natural flavors", displayName: "Natural Flavors", normalizedName: "natural flavors", category: .neutral, explanation: "Common flavoring agents.", position: 4)),
        IngredientItem(analysis: IngredientAnalysis(originalName: "red 40", displayName: "Red 40", normalizedName: "red 40", category: .concerning, explanation: "Artificial dye linked to hyperactivity in sensitive individuals.", position: 7)),
        IngredientItem(analysis: IngredientAnalysis(originalName: "salt", displayName: "Salt", normalizedName: "salt", category: .neutral, explanation: "Adds flavor and preservative qualities.", position: 8))
    ]

    IngredientsAnalysisView(items: sampleItems, rawText: "Whole grain oats, sugar, inulin, natural flavors, red 40, salt")
        .padding()
        .background(Color.backgroundPrimary)
}

// MARK: - Tier 1 Summary

private struct IngredientSummaryCard: View {
    let totalCount: Int
    let beneficialCount: Int
    let neutralCount: Int
    let concerningCount: Int
    let unknownCount: Int
    let concerningPercentage: Double

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Ingredient Summary")
                .font(.title3)
                .fontWeight(.bold)

            Text("\(totalCount) total ingredients")
                .font(.caption)
                .foregroundColor(.textSecondary)

            HStack(spacing: Spacing.lg) {
                summaryItem(icon: "checkmark.circle.fill", color: IngredientCategory.beneficial.accentColor, value: beneficialCount, label: "Beneficial")
                summaryItem(icon: "exclamationmark.triangle.fill", color: IngredientCategory.concerning.accentColor, value: concerningCount, label: "Concerning")
                summaryItem(icon: "info.circle", color: IngredientCategory.neutral.accentColor, value: neutralCount, label: "Neutral")
            }

            if totalCount > 0 && concerningCount > 0 {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(IngredientCategory.concerning.accentColor)
                        Text(String(format: "%.0f%% concerning ingredients", concerningPercentage))
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }

                    ProgressView(value: Double(concerningCount), total: Double(totalCount))
                        .tint(IngredientCategory.concerning.accentColor)
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.card)
        .padding(.horizontal, Spacing.md)
    }

    private func summaryItem(icon: String, color: Color, value: Int, label: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(value)")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

// MARK: - Tier 2 Priority Section

private struct ConcerningIngredientsSection: View {
    let items: [IngredientItem]
    let onSelect: (IngredientItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Watch Out For")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(IngredientCategory.concerning.accentColor)
                .padding(.horizontal, Spacing.md)

            VStack(spacing: Spacing.sm) {
                ForEach(items) { item in
                    Button {
                        onSelect(item)
                    } label: {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                Image(systemName: IngredientCategory.concerning.iconName)
                                    .foregroundColor(IngredientCategory.concerning.accentColor)
                                Text(item.displayName)
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.textPrimary)
                                Spacer()
                            }

                            HStack(spacing: Spacing.xs) {
                                Text(item.positionText)
                                    .font(.caption)
                                    .foregroundColor(IngredientCategory.concerning.accentColor)
                                if item.isSignificantAmount {
                                    Text("Major amount")
                                        .font(.caption.bold())
                                        .foregroundColor(.orange)
                                } else {
                                    Text("Trace amount")
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                }
                            }

                            if !item.explanation.isEmpty {
                                Text(item.explanation)
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.md)
                        .background(Color.backgroundSecondary)
                        .cornerRadius(CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(IngredientCategory.concerning.accentColor.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.md)
        }
    }
}

private struct NoConcerningIngredientsView: View {
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(IngredientCategory.beneficial.accentColor)
            Text("Great news! We didn't find any concerning ingredients.")
                .font(.callout)
                .foregroundColor(.textPrimary)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.card)
        .padding(.horizontal, Spacing.md)
    }
}

private struct BeneficialHighlightSection: View {
    let items: [IngredientItem]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Notable beneficial ingredients")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(IngredientCategory.beneficial.accentColor)
                .padding(.horizontal, Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(items) { item in
                        Text(item.displayName)
                            .font(.caption)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(IngredientCategory.beneficial.accentColor.opacity(0.12))
                            .foregroundColor(IngredientCategory.beneficial.accentColor)
                            .cornerRadius(CornerRadius.pill)
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
        }
    }
}

// MARK: - Tier 3 Detailed Breakdown

private struct IngredientCategoryList: View {
    let groupedItems: [(IngredientCategory, [IngredientItem])]
    let onSelect: (IngredientItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            ForEach(groupedItems, id: \.0) { category, items in
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: category.iconName)
                            .foregroundColor(category.accentColor)
                        Text(category.displayLabel)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(category.accentColor)
                            .textCase(.uppercase)
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        ForEach(items) { item in
                            Button {
                                onSelect(item)
                            } label: {
                                HStack {
                                    Text(item.displayName)
                                        .font(.body)
                                        .foregroundColor(.textPrimary)
                                    Spacer()
                                    Text(item.positionText)
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                }
                                .padding(.vertical, Spacing.xs)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

private struct MissingIngredientsInfo: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Ingredient information not available")
                .font(.callout)
                .fontWeight(.semibold)

            Text("This often happens with store brands, international products, or newly released items. Check the package or help improve this data on Open Food Facts.")
                .font(.caption)
                .foregroundColor(.textSecondary)

            Link("Help improve this data", destination: URL(string: "https://world.openfoodfacts.org/contribute")!)
                .font(.caption.bold())
                .foregroundColor(.primaryBlue)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.card)
        .padding(.horizontal, Spacing.md)
    }
}

// MARK: - Ingredient Detail Sheet

private struct IngredientDetailSheet: View {
    let ingredient: IngredientItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    header

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(ingredient.category.displayLabel)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(ingredient.accentColor)

                        HStack(spacing: Spacing.xs) {
                            Text(ingredient.positionText)
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            if ingredient.isSignificantAmount {
                                Text("Major component")
                                    .font(.caption.bold())
                                    .foregroundColor(.primaryBlue)
                            }
                        }
                    }

                    if !ingredient.explanation.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Why it matters")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(ingredient.explanation)
                                .font(.body)
                                .foregroundColor(.textSecondary)
                        }
                        .padding()
                        .background(ingredient.accentColor.opacity(0.1))
                        .cornerRadius(CornerRadius.md)
                    }

                    infoBox(title: "Typical use", text: ingredient.typicalUse)
                    infoBox(title: "Health impact", text: ingredient.healthImpact)
                }
                .padding(Spacing.lg)
            }
            .navigationTitle(ingredient.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: ingredient.iconName)
                .foregroundColor(ingredient.accentColor)
                .font(.system(size: 28))
            Text(ingredient.displayName)
                .font(.title2)
                .fontWeight(.bold)
        }
    }

    private func infoBox(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(text)
                .font(.body)
                .foregroundColor(.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
    }
}
