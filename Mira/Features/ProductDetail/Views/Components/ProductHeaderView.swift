import SwiftUI

/// Displays the product image, name, brand, and barcode
struct ProductHeaderView: View {
    let product: ProductModel

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            AsyncProductImage(
                url: product.imageURL ?? product.thumbnailURL,
                size: .medium,
                cornerRadius: CornerRadius.md
            )
            .onAppear {
                AppLog.debug("ProductDetailView image URL: \(product.imageURL ?? "nil") | thumb: \(product.thumbnailURL ?? "nil")", category: .general)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(product.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.leading)

                if let brand = product.brand, !brand.isEmpty {
                    Text(brand)
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                }

                Text("Barcode: \(product.barcode)")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
}

#Preview {
    ProductHeaderView(
        product: ProductModel(
            id: UUID(),
            name: "Organic Oat Milk",
            brand: "Oatly",
            category: "Beverages",
            categorySlug: nil,
            barcode: "1234567890123",
            nutrition: ProductNutrition(
                calories: 120,
                protein: 3,
                carbohydrates: 16,
                fat: 5,
                fiber: 2,
                sugar: 7,
                sodium: 0.1,
                cholesterol: 0,
                servingSize: "240ml"
            ),
            ingredients: ["Oat Base", "Water", "Rapeseed Oil"],
            additives: [],
            processingLevel: .processed,
            dietaryFlags: [],
            imageURL: nil,
            thumbnailURL: nil,
            healthScore: 75,
            createdAt: Date(),
            updatedAt: Date(),
            isCached: false,
            rawIngredientsText: nil
        )
    )
    .padding()
}
