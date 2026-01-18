import SwiftUI

/// Button to enable/manage product comparison mode
/// Shows when comparison is active and provides quick actions
struct ComparisonModeButton: View {
    @ObservedObject var viewModel: ProductComparisonViewModel
    @EnvironmentObject private var appState: AppState
    let currentProduct: ProductModel?
    let currentScore: HealthScore?
    @Environment(\.dismiss) var dismiss
    @State private var showComparisonPage = false
    
    var body: some View {
        Group {
            if viewModel.comparisonMode {
                // Show active comparison state
                activeComparisonButton
            } else {
                // Show "Compare" button
                compareButton
            }
        }
    }
    
    private var compareButton: some View {
        Button(action: { 
            showComparisonPage = true
            // Clear previous comparison state to start fresh
            viewModel.clearComparison()
        }) {
            HStack {
                Image(systemName: "arrow.left.arrow.right")
                Text("Compare")
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(20)
        }
        .disabled(currentProduct == nil || currentScore == nil)
        .sheet(isPresented: $showComparisonPage) {
            if let product = currentProduct, let score = currentScore {
                ComparisonPageView(
                    viewModel: viewModel,
                    currentProduct: product,
                    currentScore: score
                )
                .environmentObject(appState)
            }
        }
    }
    
    private var activeComparisonButton: some View {
        VStack(spacing: 12) {
            // Status banner
            HStack(spacing: 8) {
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .foregroundColor(.blue)
                
                if let first = viewModel.firstProduct {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Comparing with:")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text(first.product.name)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.clearComparison()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding(12)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            
            // Quick comparison verdict
            if let _ = currentProduct,
               let score = currentScore,
               let isBetter = viewModel.isBetterThanFirst(score: score.overall) {
                HStack {
                    Image(systemName: isBetter ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isBetter ? .green : .red)
                    
                    Text(isBetter ? "This option is better" : "Previous option is better")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isBetter ? .green : .red)
                    
                    Spacer()
                }
                .padding(12)
                .background(isBetter ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Actions
            HStack(spacing: 12) {
                Button(action: {
                    if let product = currentProduct, let score = currentScore {
                        viewModel.compareWithCurrent(product: product, score: score)
                    }
                }) {
                    HStack {
                        Image(systemName: "chart.bar.doc.horizontal")
                        Text("Full Comparison")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .disabled(currentProduct == nil || currentScore == nil)
                
                Button(action: {
                    if let product = currentProduct, let score = currentScore {
                        viewModel.useAsFirstProduct(product: product, score: score)
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Use This")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                .disabled(currentProduct == nil || currentScore == nil)
            }
        }
    }
}

// MARK: - Environment Key
private struct ComparisonSelectionModeKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var comparisonSelectionMode: Bool {
        get { self[ComparisonSelectionModeKey.self] }
        set { self[ComparisonSelectionModeKey.self] = newValue }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Not in comparison mode
        ComparisonModeButton(
            viewModel: ProductComparisonViewModel(),
            currentProduct: nil,
            currentScore: nil
        )
        
        // In comparison mode
        ComparisonModeButton(
            viewModel: {
                let vm = ProductComparisonViewModel()
                return vm
            }(),
            currentProduct: nil,
            currentScore: nil
        )
    }
    .padding()
    .environmentObject(AppState())
}

// MARK: - Mock Data for Preview

extension ProductModel {
    static var mockYogurt: ProductModel {
        ProductModel(
            id: UUID(),
            name: "Greek Yogurt",
            brand: "Healthy Brand",
            category: "Yogurt",
            categorySlug: "yogurt",
            barcode: "12345",
            nutrition: ProductNutrition(
                calories: 100,
                protein: 10,
                carbohydrates: 6,
                fat: 0,
                saturatedFat: 0,
                fiber: 0,
                sugar: 4,
                sodium: 0.05,
                servingSize: "100g"
            ),
            ingredients: ["Milk", "Live cultures"],
            additives: [],
            processingLevel: .processed,
            dietaryFlags: [],
            healthScore: 85,
            createdAt: Date(),
            updatedAt: Date(),
            isCached: false,
            nutriScore: "A"
        )
    }
    
    static var mockIceCream: ProductModel {
        ProductModel(
            id: UUID(),
            name: "Premium Ice Cream",
            brand: "Sweet Brand",
            category: "Dessert",
            categorySlug: "ice-cream",
            barcode: "67890",
            nutrition: ProductNutrition(
                calories: 250,
                protein: 3,
                carbohydrates: 30,
                fat: 14,
                saturatedFat: 9,
                fiber: 0,
                sugar: 24,
                sodium: 0.08,
                servingSize: "100g"
            ),
            ingredients: ["Milk", "Sugar", "Cream"],
            additives: [],
            processingLevel: .processed,
            dietaryFlags: [],
            healthScore: 35,
            createdAt: Date(),
            updatedAt: Date(),
            isCached: false,
            nutriScore: "D"
        )
    }
}

extension HealthScore {
    static func mock(score: Double) -> HealthScore {
        let verdict = ScoreVerdict(score: score)
        return HealthScore(
            rawScore: score,
            overall: score,
            tier: .good,
            grade: ScoreGrade(score: score),
            explanation: "Mock score",
            confidence: .high,
            confidenceWarning: nil,
            confidenceRange: 0...100,
            rawPositivePoints: 20,
            rawNegativePoints: 10,
            weightedPositivePoints: 20,
            weightedNegativePoints: 10,
            contributions: [],
            breakdown: [],
            adjustments: [],
            topReasons: [],
            uxMessages: [],
            components: .empty,
            scoringResult: nil,
            verdict: verdict,
            simplifiedDisplay: SimplifiedScoreDisplay(
                score: score,
                verdict: verdict,
                topFactors: ["Mock factor"],
                categoryContext: nil
            ),
            categoryPercentile: nil,
            categoryRank: nil,
            nutriScoreVerdict: .unknown
        )
    }
}



