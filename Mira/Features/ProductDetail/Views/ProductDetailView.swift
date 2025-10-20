import SwiftUI
import UIKit
import CoreData

struct ProductDetailView: View {
    let barcode: String
    @StateObject private var viewModel = ProductDetailViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var isFavorite = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    LoadingViewWithMessage(message: "Analyzing product...")
                        .padding()
                } else if let product = viewModel.product {
                    productContent(product)
                } else {
                    EmptyStateView(
                        title: "Product Not Found",
                        subtitle: "We couldn't find information for this barcode. Try a different product.",
                        systemImage: "exclamationmark.triangle",
                        actionButtonTitle: "Try Again"
                    ) {
                        viewModel.loadProduct(barcode: barcode)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Product Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(isFavorite ? .red : .gray)
                }
            }
        }
        .onAppear {
            loadFavoriteStatus()
            viewModel.loadProduct(barcode: barcode)
            viewModel.updateHealthFocus(mapHealthFocus(appState.healthFocus))
            viewModel.updateDietaryRestrictions(appState.dietaryRestrictions)
            AppLog.debug("ProductDetailView appeared", category: .general)
        }
        .onChange(of: appState.healthFocus) { newFocus in
            viewModel.updateHealthFocus(mapHealthFocus(newFocus))
        }
        .onChange(of: appState.dietaryRestrictions) { newRestrictions in
            viewModel.updateDietaryRestrictions(newRestrictions)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.dismissError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error occurred")
        }
    }

    @ViewBuilder
    private func productContent(_ product: ProductModel) -> some View {
        VStack(spacing: Spacing.xxl) {
            // Product Header
            productHeader(product)

            // Dietary Restrictions (High Priority)
            if !viewModel.dietaryRestrictionResults.isEmpty {
                dietaryRestrictionsSection
            }

            // Health Score Card
            if let healthScore = viewModel.healthScore {
                healthScoreCard(healthScore)
            }

            // Nutrition Breakdown
            nutritionBreakdown(product.nutrition)

            // Score Breakdown Section
            if let healthScore = viewModel.healthScore {
                ScoreBreakdownView(healthScore: healthScore)
            }

            // Score Adjustments Section
            if let healthScore = viewModel.healthScore, !healthScore.adjustments.isEmpty {
                ScoreAdjustmentsView(adjustments: healthScore.adjustments)
            }

            // Ingredients section (progressive disclosure)
            IngredientsAnalysisView(
                items: viewModel.ingredientItems,
                rawText: viewModel.rawIngredientsText
            )

            // Alternatives
            if !viewModel.alternatives.isEmpty {
                alternativesSection()
            }
        }
        .padding()
    }

    private var dietaryRestrictionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Dietary Restrictions")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)

            VStack(spacing: Spacing.sm) {
                ForEach(viewModel.dietaryRestrictionResults) { result in
                    DietaryRestrictionBadge(result: result)
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
    }

    private func productHeader(_ product: ProductModel) -> some View {
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

    private func healthScoreCard(_ healthScore: HealthScore) -> some View {
        VStack(spacing: Spacing.md) {
            // Title
            HStack {
                Text("Health Score")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }

            HStack(alignment: .top, spacing: Spacing.lg) {
                // Left column: Overall score (just gauge and focus pill)
                VStack(spacing: Spacing.sm) {
                    // Score gauge (score shown inside donut)
                    ScoreGauge(score: healthScore.overall, size: 100)

                    // Focus pill
                    Text(healthScore.focus.displayName)
                        .font(.caption)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.primaryBlue.opacity(0.12))
                        .foregroundColor(.primaryBlue)
                        .cornerRadius(CornerRadius.pill)
                }

                // Right side: Component scores grid (no weight badges)
                VStack(spacing: Spacing.sm) {
                    // Get top 4 components to display
                    let topComponents = Array(healthScore.breakdown.prefix(4))

                    ForEach(topComponents, id: \.componentName) { component in
                        componentScoreRow(component)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            // Bottom section - spans full width
            VStack(spacing: Spacing.sm) {
                // Microcopy hints
                if let bestArea = healthScore.breakdown.max(by: { $0.rawScore < $1.rawScore }),
                   let weakArea = healthScore.breakdown.min(by: { $0.rawScore < $1.rawScore }) {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        if bestArea.rawScore >= 70 {
                            Text("Best area: \(bestArea.componentName)")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        if weakArea.rawScore < 70 {
                            Text("Needs attention: \(weakArea.componentName)")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Narrative copy in disclosure group
                DisclosureGroup("Why this matters") {
                    Text(healthScore.explanation)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .padding(.top, Spacing.xs)
                }
                .font(.caption)
                .foregroundColor(.textPrimary)
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.card)
    }

    /// Component score row for the right-side grid (no weight badge)
    private func componentScoreRow(_ component: ComponentBreakdown) -> some View {
        HStack(spacing: Spacing.xs) {
            // Label
            Text(component.componentName)
                .font(.caption)
                .foregroundColor(.textSecondary)
                .lineLimit(1)

            Spacer()

            // Score value (color-coded)
            Text("\(Int(component.rawScore))")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color.scoreColor(for: component.rawScore))
        }
        .padding(.vertical, Spacing.xxs)
    }

    private func nutritionBreakdown(_ nutrition: ProductNutrition) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition Facts")
                .font(.title3)
                .fontWeight(.semibold)

            HStack {
                Text("Serving Size:")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Text(nutrition.servingSize)
                    .font(.caption)
                    .foregroundColor(.textPrimary)
            }

            VStack(spacing: 8) {
                nutritionRow("Calories", value: nutrition.calories, unit: "")
                nutritionRow("Protein", value: nutrition.protein, unit: "g")
                nutritionRow("Carbohydrates", value: nutrition.carbohydrates, unit: "g")
                nutritionRow("Fat", value: nutrition.fat, unit: "g")
                nutritionRow("Fiber", value: nutrition.fiber, unit: "g")
                nutritionRow("Sugar", value: nutrition.sugar, unit: "g")
                nutritionRow("Sodium", value: nutrition.sodium, unit: "g")
                nutritionRow("Cholesterol", value: nutrition.cholesterol * 1000, unit: "mg", precision: 0)
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }

    private func nutritionRow(_ name: String, value: Double, unit: String, precision: Int = 1) -> some View {
        let formattedValue = String(format: "%.*f", precision, value)

        return HStack {
            Text(name)
                .font(.bodyMedium)
                .foregroundColor(.textPrimary)

            Spacer()

            Text("\(formattedValue)\(unit)")
                .font(.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
        }
    }

    private func legacyIngredientsFallback(_ product: ProductModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "leaf")
                    .foregroundColor(.primaryBlue)
                Text("Ingredients")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(product.ingredients, id: \.self) { ingredient in
                    Text("• \\(ingredient)")
                        .font(.bodyMedium)
                        .foregroundColor(.textPrimary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }

    private func alternativesSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Better Alternatives")
                .font(.title3)
                .fontWeight(.semibold)

            if viewModel.isLoadingAlternatives {
                LoadingView()
            } else if let message = viewModel.alternativesMessage {
                EmptyStateView(
                    title: "No Alternatives Yet",
                    subtitle: message,
                    systemImage: "lightbulb"
                )
                .padding(.vertical, Spacing.sm)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(viewModel.alternatives.enumerated()), id: \.offset) { index, alt in
                        AlternativeProductCard(alternative: alt, rank: index + 1)
                    }
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }

    // MARK: - Favorites

    private func loadFavoriteStatus() {
        let context = PersistenceController.shared.container.viewContext
        let currentBarcode = barcode

        context.perform {
            let request: NSFetchRequest<ProductEntity> = ProductEntity.fetchRequest()
            request.predicate = NSPredicate(format: "barcode == %@", currentBarcode)
            request.fetchLimit = 1

            do {
                if let entity = try context.fetch(request).first {
                    let status = entity.isFavorite
                    DispatchQueue.main.async {
                        self.isFavorite = status
                    }
                }
            } catch {
                AppLog.error("Failed to load favorite status: \(error.localizedDescription)", category: .persistence)
            }
        }
    }

    private func toggleFavorite() {
        let context = PersistenceController.shared.container.viewContext
        let currentBarcode = barcode

        context.perform {
            let request: NSFetchRequest<ProductEntity> = ProductEntity.fetchRequest()
            request.predicate = NSPredicate(format: "barcode == %@", currentBarcode)
            request.fetchLimit = 1

            do {
                guard let entity = try context.fetch(request).first else {
                    AppLog.warning("Product not found for barcode: \(currentBarcode)", category: .persistence)
                    return
                }

                entity.isFavorite.toggle()
                let newStatus = entity.isFavorite

                do {
                    try context.save()
                    AppLog.debug("Updated favorite status for \(entity.name ?? "Unknown") -> \(newStatus)", category: .persistence)

                    DispatchQueue.main.async {
                        self.isFavorite = newStatus
                    }
                } catch {
                    AppLog.error("Failed to save favorite: \(error.localizedDescription)", category: .persistence)
                }
            } catch {
                AppLog.error("Failed to fetch product for favorites: \(error.localizedDescription)", category: .persistence)
            }
        }
    }
}

private func mapHealthFocus(_ string: String) -> HealthFocus {
    switch string {
    case "gutHealth", "gut_health": return .gutHealth
    case "weightLoss", "weight_loss": return .weightLoss
    case "proteinFocus", "protein_focus": return .proteinFocus
    case "heartHealth", "heart_health": return .heartHealth
    case "generalWellness", "general_wellness": return .generalWellness
    default: return .generalWellness
    }
}

#Preview {
    ProductDetailView(barcode: "1234567890123")
}
