import SwiftUI

struct ProductDetailTabsView: View {
    let product: ProductModel
    let healthScore: HealthScore?
    let dietaryRestrictions: Set<String>
    let ingredientItems: [IngredientItem]
    let rawIngredientsText: String?
    
    @State private var selectedTab: Tab = .overview
    
    enum Tab: String, CaseIterable {
        case overview = "Overview"
        case nutrition = "Nutrition"
        case ingredients = "Ingredients"
    }
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            // Tab Selector
            Picker("Tabs", selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Tab Content
            switch selectedTab {
            case .overview:
                ProductOverviewView(
                    product: product,
                    healthScore: healthScore,
                    dietaryRestrictions: dietaryRestrictions
                )
                .transition(.opacity)
                
            case .nutrition:
                ProductNutritionView(nutrition: product.nutrition)
                    .transition(.opacity)
                
            case .ingredients:
                ProductIngredientsView(
                    ingredientItems: ingredientItems,
                    rawIngredientsText: rawIngredientsText
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }
}
