import SwiftUI

struct ProductIngredientsView: View {
    let ingredientItems: [IngredientItem]
    let rawIngredientsText: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Ingredients")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            
            IngredientsAnalysisView(
                items: ingredientItems,
                rawText: rawIngredientsText
            )
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.md)
        .shadow(color: .cardShadow, radius: 4, x: 0, y: 2)
    }
}
