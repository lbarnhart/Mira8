import SwiftUI
import UIKit
import CoreData

struct ProductDetailView: View {
    private enum PresentedSheet: String, Identifiable {
        case firstScanEducation
        case scoreComparison
        case scoreExplanation

        var id: String { rawValue }
    }

    let barcode: String
    @StateObject private var viewModel = ProductDetailViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var isFavorite = false
    @State private var presentedSheet: PresentedSheet?
    @StateObject private var shoppingListViewModel = ShoppingListViewModel()
    @State private var showAddedToListConfirmation = false

    private var showErrorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.loading.showError },
            set: { _ in viewModel.dismissError() }
        )
    }

    var body: some View {
        mainContent
            .navigationTitle("Product Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: Spacing.md) {
                        // Add to Shopping List Button
                        Button {
                            addToShoppingList()
                        } label: {
                            Image(systemName: isInShoppingList ? "cart.fill" : "cart")
                                .foregroundColor(isInShoppingList ? .scoreExcellent : .gray)
                        }
                        .accessibilityLabel(isInShoppingList ? "Remove from shopping list" : "Add to shopping list")
                        .disabled(viewModel.productData.product == nil)
                        .accessibilityIdentifier("productDetail.shoppingList")

                        // Favorite Button
                        Button {
                            toggleFavorite()
                        } label: {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(isFavorite ? .red : .gray)
                        }
                        .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
                        .accessibilityIdentifier("productDetail.favorite")
                    }
                }
            }
            .overlay(alignment: .bottom) {
                // Confirmation Toast
                if showAddedToListConfirmation {
                    Text("Added to Shopping List")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.scoreExcellent)
                        .cornerRadius(CornerRadius.pill)
                        .shadow(radius: 8)
                        .padding(.bottom, Spacing.xl)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .accessibilityLabel("Product added to shopping list")
                        .accessibilityIdentifier("productDetail.addedToast")
                }
            }
        .onAppear {
            loadFavoriteStatus()
            viewModel.loadProduct(barcode: barcode)
            viewModel.updateHealthFocus(HealthFocus(fromStored: appState.healthFocus))
            viewModel.updateDietaryRestrictions(appState.dietaryRestrictions)
            AppLog.debug("ProductDetailView appeared", category: .general)
        }
        .onChange(of: appState.healthFocus) { newFocus in
            viewModel.updateHealthFocus(HealthFocus(fromStored: newFocus))
        }
        .onChange(of: appState.dietaryRestrictions) { newRestrictions in
            viewModel.updateDietaryRestrictions(newRestrictions)
        }
        .alert("Error", isPresented: showErrorBinding) {
            Button("OK") {
                viewModel.dismissError()
            }
        } message: {
            Text(viewModel.loading.errorMessage ?? "Unknown error occurred")
        }
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .firstScanEducation:
                firstScanEducationSheet
            case .scoreComparison:
                scoreComparisonSheet
            case .scoreExplanation:
                scoreExplanationSheet
            }
        }
        .onChange(of: viewModel.productData.healthScore?.overall) { score in
            // Show first scan education if this is the first time
            let hasSeenFirstScanEducation = UserDefaults.standard.bool(
                forKey: Constants.UserDefaults.hasSeenFirstScanEducation
            )
            if !hasSeenFirstScanEducation, score != nil {
                // Small delay to let the view settle
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if presentedSheet == nil {
                        presentedSheet = .firstScanEducation
                        UserDefaults.standard.set(
                            true,
                            forKey: Constants.UserDefaults.hasSeenFirstScanEducation
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.loading.isLoading {
                    LoadingViewWithMessage(message: "Analyzing product...")
                        .padding()
                } else if let product = viewModel.productData.product {
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
    }

    @ViewBuilder
    private func productContent(_ product: ProductModel) -> some View {
        VStack(spacing: Spacing.xxl) {
            // Product Header
            ProductHeaderView(product: product)

            // Category Context Banner (for foods like cheese, nuts, meat, etc.)
            if let healthScore = viewModel.productData.healthScore,
               let context = CategoryContextProvider.context(for: product, healthScore: healthScore) {
                CategoryContextBanner(context: context)
            }

            // Dietary Restrictions (High Priority)
            if !viewModel.dietary.results.isEmpty || !viewModel.dietary.aiEnhancedResults.isEmpty || viewModel.dietary.isAnalyzingWithAI {
                DietaryRestrictionsSectionView(
                    results: viewModel.dietary.results,
                    analysisResults: viewModel.dietary.aiEnhancedResults,
                    isLoading: viewModel.dietary.isAnalyzingWithAI,
                    isAIEnhanced: viewModel.dietary.isAIEnhanced
                )
            }

            // Health Score Card
            if let healthScore = viewModel.productData.healthScore {
                HealthScoreCardView(
                    healthScore: healthScore,
                    productName: product.name,
                    dataSource: product.dataSource,
                    healthFocus: HealthFocus(fromStored: appState.healthFocus),
                    onShowExplanation: {
                        presentedSheet = .scoreExplanation
                    }
                )

                // Compare Focuses button
                Button {
                    presentedSheet = .scoreComparison
                } label: {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("Compare Health Focuses")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.textTertiary)
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryBlue)
                    .padding(Spacing.md)
                    .background(Color.primaryBlue.opacity(0.08))
                    .cornerRadius(CornerRadius.button)
                }
                .accessibilityIdentifier("productDetail.compareFocuses")
            }

            // What's Good Section (for lower-scoring products)
            if let healthScore = viewModel.productData.healthScore,
               healthScore.overall < 60 {
                PositivesSection(product: product, healthScore: healthScore)
            }

            // Nutrition Breakdown
            NutritionBreakdownView(nutrition: product.nutrition)

            // Ingredients section (progressive disclosure)
            IngredientsAnalysisView(
                items: viewModel.productData.ingredientItems,
                rawText: viewModel.productData.rawIngredientsText
            )

            // Alternatives
            if !viewModel.alternatives.items.isEmpty {
                AlternativesSectionView(
                    alternatives: viewModel.alternatives.items,
                    isLoading: viewModel.alternatives.isLoading,
                    message: viewModel.alternatives.message,
                    healthFocusName: HealthFocus(fromStored: appState.healthFocus).displayName
                )
            }

            // Balance Banner (for lower-scoring products)
            if let healthScore = viewModel.productData.healthScore,
               healthScore.overall < 60 {
                BalanceBanner {
                    appState.selectedTab = Tab.insights.rawValue
                }
            }
        }
        .padding()
    }

    // MARK: - Sheet Content

    @ViewBuilder
    private var firstScanEducationSheet: some View {
        if let product = viewModel.productData.product,
           let healthScore = viewModel.productData.healthScore {
            FirstScanEducationSheet(
                product: product,
                userScore: healthScore,
                userFocus: HealthFocus(fromStored: appState.healthFocus)
            )
        }
    }

    @ViewBuilder
    private var scoreComparisonSheet: some View {
        if let product = viewModel.productData.product {
            ScoreComparisonSheet(
                product: product,
                currentFocus: HealthFocus(fromStored: appState.healthFocus)
            )
        }
    }

    @ViewBuilder
    private var scoreExplanationSheet: some View {
        if let product = viewModel.productData.product,
           let healthScore = viewModel.productData.healthScore {
            WhyThisScoreView(
                healthScore: healthScore,
                productName: product.name,
                healthFocus: HealthFocus(fromStored: appState.healthFocus),
                dataSource: product.dataSource
            )
        }
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

    // MARK: - Shopping List Functions

    private var isInShoppingList: Bool {
        guard let product = viewModel.productData.product else { return false }
        return shoppingListViewModel.items.contains(where: { $0.barcode == product.barcode })
    }

    private func addToShoppingList() {
        guard let product = viewModel.productData.product else { return }

        if isInShoppingList {
            // Remove from list
            if let item = shoppingListViewModel.items.first(where: { $0.barcode == product.barcode }) {
                shoppingListViewModel.removeItem(item)
            }
        } else {
            // Add to list
            shoppingListViewModel.addItem(product)

            // Show confirmation toast
            withAnimation(.easeInOut(duration: 0.3)) {
                showAddedToListConfirmation = true
            }

            // Hide after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showAddedToListConfirmation = false
                }
            }
        }
    }
}

#Preview {
    ProductDetailView(barcode: "1234567890123")
}
