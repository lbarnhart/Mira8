import SwiftUI
import CoreData

/// Full-page comparison view with two slots: left (current product) and right (selection slot)
/// Right slot starts empty and can be filled by selecting from history or scanning
struct ComparisonPageView: View {
    @ObservedObject var viewModel: ProductComparisonViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var showHistorySelection = false
    @State private var showScanner = false
    
    let currentProduct: ProductModel
    let currentScore: HealthScore
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Text("Compare Products")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        // Spacer for alignment
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.clear)
                        .disabled(true)
                    }
                    .padding()
                    
                    // If both products selected, show winner announcement
                    if let _ = viewModel.secondProduct,
                       let result = viewModel.comparisonResult {
                        winnerAnnouncementBanner(result: result)
                    }
                    
                    // Product comparison slots
                    HStack(spacing: 16) {
                        // Left slot - current product
                        productSlot(
                            product: currentProduct,
                            score: currentScore,
                            isWinner: isProductAWinner()
                        )
                        
                        // Right slot - selection or second product
                        if let secondProduct = viewModel.secondProduct {
                            productSlot(
                                product: secondProduct.product,
                                score: secondProduct.score,
                                isWinner: !isProductAWinner()
                            )
                        } else {
                            emptySlotWithOptions
                        }
                    }
                    .padding()
                    
                    // Nutrition comparison table (only show if both products selected)
                    if let _ = viewModel.secondProduct {
                        nutritionComparisonTable
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showHistorySelection) {
            HistorySelectionView(
                viewModel: viewModel,
                isPresented: $showHistorySelection,
                currentProduct: currentProduct,
                currentScore: currentScore
            )
            .environmentObject(appState)
        }
        .sheet(isPresented: $showScanner, onDismiss: {
            // Only dismiss if a second product wasn't just added
            // If viewModel.secondProduct is set, keep the sheet open momentarily
            if viewModel.secondProduct != nil {
                showScanner = false
            }
        }) {
            ScannerView { result in
                handleScannedProduct(result)
            }
        }
    }
    
    // MARK: - Private Views
    
    private var emptySlotWithOptions: some View {
        VStack(spacing: 16) {
            // "Select a Product" text at top
            Text("Select a Product")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Select from History button
            Button(action: { showHistorySelection = true }) {
                HStack {
                    Image(systemName: "clock.fill")
                    Text("Choose from History")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }

            // Scan New Product button
            Button(action: {
                showScanner = true
            }) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Scan New Product")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.blue)
                .cornerRadius(10)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
        )
    }
    
    private func productSlot(
        product: ProductModel,
        score: HealthScore,
        isWinner: Bool
    ) -> some View {
        VStack(spacing: 12) {
            // Product image
            if let imageURL = product.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: .infinity, height: 120)
                            .clipped()
                    case .failure:
                        Color.gray.opacity(0.2)
                            .frame(height: 120)
                    default:
                        Color.gray.opacity(0.2)
                            .frame(height: 120)
                    }
                }
                .frame(height: 120)
                .cornerRadius(8)
            } else {
                Color.gray.opacity(0.2)
                    .frame(height: 120)
                    .cornerRadius(8)
            }
            
            // Verdict pill
            verdictPill(verdict: score.simplifiedDisplay.verdict)
            
            // Brand
            if let brand = product.brand {
                Text(brand)
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }
            
            // Product name
            Text(product.name)
                .font(.system(size: 14, weight: .semibold))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // View details link
            HStack {
                Text("View details")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.blue)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.blue)
                Spacer()
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(backgroundColorForVerdict(score.simplifiedDisplay.verdict))
        .cornerRadius(12)
    }
    
    private func backgroundColorForVerdict(_ verdict: ScoreVerdict) -> Color {
        switch verdict {
        case .excellent:
            return Color(red: 0.95, green: 0.97, blue: 0.85)  // Light green
        case .good:
            return Color(red: 1.0, green: 0.97, blue: 0.85)   // Light yellow/beige
        case .okay:
            return Color(red: 1.0, green: 0.95, blue: 0.85)   // Light peachy
        case .fair:
            return Color(red: 1.0, green: 0.93, blue: 0.85)   // Light orange
        case .avoid:
            return Color(red: 1.0, green: 0.92, blue: 0.92)   // Light red/pink
        }
    }
    
    private var nutritionComparisonTable: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition Comparison")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            Text("Per serving")
                .font(.system(size: 13))
                .foregroundColor(.textSecondary)
            
            VStack(spacing: 0) {
                nutritionRow(
                    label: "Calories",
                    valueA: Int(currentProduct.nutrition.calories.rounded()),
                    valueB: Int((viewModel.secondProduct?.product.nutrition.calories ?? 0).rounded()),
                    unit: ""
                )
                
                Divider()
                
                nutritionRow(
                    label: "Sugar",
                    valueA: Int(currentProduct.nutrition.sugar.rounded()),
                    valueB: Int((viewModel.secondProduct?.product.nutrition.sugar ?? 0).rounded()),
                    unit: "g"
                )
                
                Divider()
                
                nutritionRow(
                    label: "Fiber",
                    valueA: Int(currentProduct.nutrition.fiber.rounded()),
                    valueB: Int((viewModel.secondProduct?.product.nutrition.fiber ?? 0).rounded()),
                    unit: "g"
                )
                
                Divider()
                
                nutritionRow(
                    label: "Protein",
                    valueA: Int(currentProduct.nutrition.protein.rounded()),
                    valueB: Int((viewModel.secondProduct?.product.nutrition.protein ?? 0).rounded()),
                    unit: "g"
                )
                
                Divider()
                
                nutritionRow(
                    label: "Sodium",
                    valueA: Int(currentProduct.nutrition.sodium.rounded()),
                    valueB: Int((viewModel.secondProduct?.product.nutrition.sodium ?? 0).rounded()),
                    unit: "mg"
                )
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
    
    private func nutritionRow(label: String, valueA: Int, valueB: Int, unit: String) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            let isBetter = isValueBetter(value: valueA, other: valueB, nutrient: label)
            let isEqual = valueA == valueB
            
            // Left value (Product A)
            HStack(spacing: 4) {
                if isBetter && !isEqual {
                    Image(systemName: "arrow.up.and.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.green)
                }
                Text("\(valueA)\(unit)")
                    .font(.system(size: 14, weight: isBetter && !isEqual ? .semibold : .regular))
                    .foregroundColor(isBetter && !isEqual ? .green : .textPrimary)
            }
            .frame(width: 80, alignment: .trailing)
            
            // Right value (Product B)
            Text("\(valueB)\(unit)")
                .font(.system(size: 14, weight: !isBetter && !isEqual ? .semibold : .regular))
                .foregroundColor(!isBetter && !isEqual ? .green : .textPrimary)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, 12)
    }
    
    private func isValueBetter(value: Int, other: Int, nutrient: String) -> Bool {
        // For calories, sugar, sodium - lower is better
        // For fiber, protein - higher is better
        switch nutrient.lowercased() {
        case "calories", "sugar", "sodium":
            return value < other
        default:
            return value > other
        }
    }
    
    private func verdictPill(verdict: ScoreVerdict) -> some View {
        HStack(spacing: 6) {
            Text(verdict.emoji)
                .font(.system(size: 14))
            
            Text(verdict.label.uppercased())
                .font(.system(size: 12, weight: .bold))
        }
        .frame(maxWidth: .infinity)
        .foregroundColor(.white)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(verdictColor(verdict))
        .cornerRadius(20)
    }
    
    private func verdictColor(_ verdict: ScoreVerdict) -> Color {
        switch verdict {
        case .excellent:
            return Color(red: 0.15, green: 0.68, blue: 0.38)  // Green
        case .good:
            return Color(red: 0.95, green: 0.77, blue: 0.06)  // Golden
        case .okay:
            return Color(red: 0.95, green: 0.77, blue: 0.06)  // Yellow
        case .fair:
            return Color(red: 1.0, green: 0.58, blue: 0.0)    // Orange
        case .avoid:
            return Color(red: 0.95, green: 0.26, blue: 0.21)  // Red
        }
    }
    
    private func winnerAnnouncementBanner(result: ComparisonResult) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
                
                Text("\(result.winner.name) is the better choice")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            Text(result.recommendation)
                .font(.system(size: 13))
                .foregroundColor(.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .padding()
    }
    
    private func isProductAWinner() -> Bool {
        guard let result = viewModel.comparisonResult else { return false }
        return result.productA.id == currentProduct.id && result.scoreA.overall > result.scoreB.overall
    }
    
    private func handleScannedProduct(_ scanResult: ScanResult) {
        Task {
            do {
                var apiProduct: APIProduct?
                
                // Try USDA first
                do {
                    let usdaService = USDAService()
                    apiProduct = try await usdaService.searchProductByBarcode(scanResult.barcode)
                } catch {
                    AppLog.warning("USDA lookup failed, trying Open Food Facts...", category: .general)
                    // Fall back to Open Food Facts
                    let offService = OpenFoodFactsService()
                    apiProduct = try await offService.searchProductByBarcode(scanResult.barcode)
                }
                
                guard let product = apiProduct else {
                    throw NetworkError.productNotFound
                }
                
                // Convert to ProductModel
                let productModel = makeProductModel(from: product)
                
                // Calculate health score for the product
                let dietaryRestrictions = appState.dietaryRestrictions.compactMap { DietaryRestriction(rawValue: $0) }
                let score = ScoringEngine.shared.calculateHealthScore(
                    for: productModel,
                    dietaryRestrictions: dietaryRestrictions
                )
                
                // Add as second product to comparison
                viewModel.addSecondProduct(product: productModel, score: score)
                
                // Close the scanner sheet after a brief delay to show the comparison
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showScanner = false
                }
            } catch {
                AppLog.error("Failed to load scanned product: \(error)", category: .general)
                // Close scanner on error
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showScanner = false
                }
            }
        }
    }
}

// MARK: - History Selection View

struct HistorySelectionView: View {
    @ObservedObject var viewModel: ProductComparisonViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var historyItems: [HistoryItemData] = []
    @State private var isLoading = true
    
    var isPresented: Binding<Bool>?
    let currentProduct: ProductModel
    let currentScore: HealthScore
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(historyItems) { item in
                    Button(action: {
                        selectProduct(item)
                    }) {
                        HStack(spacing: 12) {
                            if let imageURL = item.imageURL, !imageURL.isEmpty, let url = URL(string: imageURL) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 50, height: 50)
                                            .clipped()
                                            .cornerRadius(8)
                                    default:
                                        Color.gray.opacity(0.2)
                                            .frame(width: 50, height: 50)
                                            .cornerRadius(8)
                                    }
                                }
                            } else {
                                Color.gray.opacity(0.2)
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(8)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                    .lineLimit(2)
                                
                                if let brand = item.brand {
                                    Text(brand)
                                        .font(.system(size: 12))
                                        .foregroundColor(.textSecondary)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Select Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                    }
                }
            }
            .onAppear {
                loadHistory()
            }
        }
    }
    
    private func loadHistory() {
        let context = PersistenceController.shared.container.viewContext
        context.performAndWait {
            let request: NSFetchRequest<ProductEntity> = ProductEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "lastScanned", ascending: false)]
            
            do {
                let entities = try context.fetch(request)
                let items = entities.compactMap { entity -> HistoryItemData? in
                    guard let name = entity.name,
                          let barcode = entity.barcode else { return nil }
                    
                    // Decode nutritional data from JSON blob
                    var nutrition = NutritionalData()
                    if let data = entity.nutritionalData {
                        if let decoded = try? JSONDecoder().decode(NutritionalData.self, from: data) {
                            nutrition = decoded
                        }
                    }
                    
                    return HistoryItemData(
                        id: UUID(),
                        name: name,
                        brand: entity.brand,
                        barcode: barcode,
                        imageURL: entity.imageURL,
                        calories: nutrition.calories,
                        protein: nutrition.protein,
                        carbohydrates: nutrition.carbohydrates,
                        fat: nutrition.fat,
                        saturatedFat: nutrition.saturatedFat,
                        fiber: nutrition.fiber,
                        sugar: nutrition.sugar,
                        sodium: nutrition.sodium,
                        cholesterol: nutrition.cholesterol,
                        servingSize: entity.servingSize ?? "100g"
                    )
                }
                
                DispatchQueue.main.async {
                    self.historyItems = items
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func selectProduct(_ item: HistoryItemData) {
        let productModel = ProductModel(
            id: UUID(),
            name: item.name,
            brand: item.brand,
            category: nil,
            categorySlug: nil,
            barcode: item.barcode,
            nutrition: ProductNutrition(
                calories: item.calories,
                protein: item.protein,
                carbohydrates: item.carbohydrates,
                fat: item.fat,
                saturatedFat: item.saturatedFat,
                fiber: item.fiber,
                sugar: item.sugar,
                sodium: item.sodium,
                cholesterol: item.cholesterol,
                servingSize: item.servingSize
            ),
            ingredients: [],
            additives: [],
            processingLevel: .unknown,
            dietaryFlags: [],
            imageURL: item.imageURL,
            healthScore: 0.0, // Placeholder, will be updated by ScoringEngine
            createdAt: Date(),
            updatedAt: Date(),
            isCached: false,
            nutriScore: nil
        )
        
        let dietaryRestrictions = appState.dietaryRestrictions.compactMap { DietaryRestriction(rawValue: $0) }
        let score = ScoringEngine.shared.calculateHealthScore(
            for: productModel,
            dietaryRestrictions: dietaryRestrictions
        )
        
        // First, ensure the current product is set as the first product
        if viewModel.firstProduct == nil {
            viewModel.startComparison(product: currentProduct, score: currentScore)
        }
        
        // Then add the selected product as the second product
        viewModel.addSecondProduct(product: productModel, score: score)
        dismiss()
    }
}

// MARK: - Helper Models

struct HistoryItemData: Identifiable {
    let id: UUID
    let name: String
    let brand: String?
    let barcode: String
    let imageURL: String?
    let calories: Double
    let protein: Double
    let carbohydrates: Double
    let fat: Double
    let saturatedFat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let cholesterol: Double
    let servingSize: String
}

// MARK: - Helper Functions

private func makeProductModel(from apiProduct: APIProduct) -> ProductModel {
    let id = UUID()
    let name = apiProduct.name
    let brand = apiProduct.brand
    let category = apiProduct.category
    let categorySlug = apiProduct.categorySlug
    let barcode = apiProduct.barcode
    let nutrition = ProductNutrition(
        calories: apiProduct.nutritionalData.calories,
        protein: apiProduct.nutritionalData.protein,
        carbohydrates: apiProduct.nutritionalData.carbohydrates,
        fat: apiProduct.nutritionalData.fat,
        saturatedFat: apiProduct.nutritionalData.saturatedFat,
        fiber: apiProduct.nutritionalData.fiber,
        sugar: apiProduct.nutritionalData.sugar,
        sodium: apiProduct.nutritionalData.sodium,
        cholesterol: apiProduct.nutritionalData.cholesterol,
        servingSize: apiProduct.servingSizeDisplay ?? "100g"
    )
    let ingredients = apiProduct.ingredients
    let additives: [String] = []  // APIProduct doesn't have additives
    let processingLevel = apiProduct.processingLevel ?? .unknown
    let dietaryFlags: [DietaryRestriction] = []  // APIProduct doesn't have dietary flags
    let imageURL = apiProduct.imageURL
    let healthScore = 0.0
    let createdAt = Date()
    let updatedAt = Date()
    let isCached = false
    let nutriScore = apiProduct.nutriScore
    
    return ProductModel(
        id: id,
        name: name,
        brand: brand,
        category: category,
        categorySlug: categorySlug,
        barcode: barcode,
        nutrition: nutrition,
        ingredients: ingredients,
        additives: additives,
        processingLevel: processingLevel,
        dietaryFlags: dietaryFlags,
        imageURL: imageURL,
        healthScore: healthScore,
        createdAt: createdAt,
        updatedAt: updatedAt,
        isCached: isCached,
        nutriScore: nutriScore
    )
}
