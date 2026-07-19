import SwiftUI

// MARK: - Comparison Mode View

struct ComparisonModeView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var viewModel: ComparisonModeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.comparisonProducts.isEmpty {
                    emptyState
                } else {
                    comparisonContent
                }
            }
            .background(Color.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Compare Products")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityLabel("Close comparison mode")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        viewModel.clearAll()
                    } label: {
                        Text("Clear All")
                    }
                    .disabled(viewModel.comparisonProducts.isEmpty)
                    .accessibilityLabel("Clear all products from comparison")
                    .accessibilityHint("Removes all products from the comparison list")
                }
            }
            .sheet(isPresented: $viewModel.showProductDetail) {
                if let product = viewModel.selectedProduct {
                    ProductDetailView(barcode: product.barcode)
                        .environmentObject(appState)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "scale.3d")
                .font(.system(size: 60))
                .foregroundColor(.textTertiary)
                .accessibilityHidden(true)

            Text("No Products to Compare")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)

            Text("Scan multiple products to see a side-by-side comparison")
                .font(.callout)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxxl)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No products to compare. Scan multiple products to see a side-by-side comparison")
    }

    private var comparisonContent: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Product count and best choice badge
                VStack(spacing: Spacing.md) {
                    Text("Comparing \(viewModel.comparisonProducts.count) Product\(viewModel.comparisonProducts.count == 1 ? "" : "s")")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    Text("Scores reflect \(HealthFocus(fromStored: appState.healthFocus).displayName.lowercased()) priorities.")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)

                    if let bestProduct = viewModel.bestProduct {
                        BestChoiceBadge(product: bestProduct, reason: viewModel.bestChoiceReason)
                    }

                    ComparisonInsightSummary(
                        summary: viewModel.comparisonSummary(for: appState.healthFocus),
                        scoreSpread: viewModel.scoreSpread,
                        metricWins: viewModel.bestProductMetricWins,
                        highlights: viewModel.bestChoiceHighlights
                    )
                }
                .padding(.horizontal, Spacing.screenPadding)

                // Comparison table
                ComparisonTable(
                    products: viewModel.comparisonProducts,
                    healthFocus: appState.healthFocus,
                    onProductTap: { product in
                        viewModel.selectedProduct = product
                        viewModel.showProductDetail = true
                    },
                    onRemove: { product in
                        viewModel.removeProduct(product)
                    }
                )

                // Add more button (max 3 products)
                if viewModel.comparisonProducts.count < 3 {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "plus.circle.fill")
                            Text("Scan Another Product")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.primaryBlue)
                        .cornerRadius(CornerRadius.button)
                    }
                    .padding(.horizontal, Spacing.screenPadding)
                    .accessibilityLabel("Scan another product")
                    .accessibilityHint("Returns to scanner to add another product for comparison. Maximum 3 products.")
                }
            }
            .padding(.vertical, Spacing.lg)
        }
    }
}

// MARK: - Best Choice Badge

private struct BestChoiceBadge: View {
    let product: ProductModel
    let reason: String

    var body: some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "trophy.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                    .accessibilityHidden(true)

                Text("Best Choice")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
            }

            Text(product.name)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)

            Text(reason)
                .font(.caption)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity)
        .background(Color.scoreExcellent.opacity(0.1))
        .cornerRadius(CornerRadius.card)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .strokeBorder(Color.scoreExcellent.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Best choice: \(product.name). \(reason)")
    }
}

private struct ComparisonInsightSummary: View {
    let summary: String
    let scoreSpread: Int
    let metricWins: Int
    let highlights: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(summary)
                .font(.subheadline)
                .foregroundColor(.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if scoreSpread > 0 || metricWins > 0 {
                HStack(spacing: Spacing.sm) {
                    if scoreSpread > 0 {
                        metricCard(title: "Spread", value: "\(scoreSpread) pts")
                    }

                    if metricWins > 0 {
                        metricCard(title: "Metric Wins", value: "\(metricWins)")
                    }
                }
            }

            if !highlights.isEmpty {
                HStack(spacing: Spacing.xs) {
                    ForEach(highlights, id: \.self) { highlight in
                        Text(highlight)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.primaryBlue)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, 6)
                            .background(Color.primaryBlue.opacity(0.1))
                            .cornerRadius(CornerRadius.pill)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.card)
    }

    private func metricCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundColor(.textTertiary)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.sm)
        .background(Color.backgroundPrimary)
        .cornerRadius(CornerRadius.button)
    }
}

// MARK: - Comparison Table

private struct ComparisonTable: View {
    let products: [ProductModel]
    let healthFocus: String
    let onProductTap: (ProductModel) -> Void
    let onRemove: (ProductModel) -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Snapshot")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.textTertiary)

                Text("Scored for \(HealthFocus(fromStored: healthFocus).displayName.lowercased())")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Product headers
            HStack(alignment: .top, spacing: Spacing.sm) {
                // Metric label column
                Color.clear
                    .frame(width: 100)
                    .accessibilityHidden(true)

                // Product columns
                ForEach(products, id: \.barcode) { product in
                    ProductHeaderCard(
                        product: product,
                        onTap: { onProductTap(product) },
                        onRemove: { onRemove(product) }
                    )
                }
            }
            .padding(.horizontal, Spacing.screenPadding)

            Divider()

            // Comparison rows
            ComparisonRow(
                label: "Score",
                values: products.map { String(format: "%.0f", $0.healthScore) },
                highlightedIndex: bestScoreIndex(products),
                isScore: true
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(scoreAccessibilityLabel(products))

            ComparisonRow(
                label: "Protein",
                values: products.map { nutrientString($0.nutrition.protein) },
                highlightedIndex: bestNutrientIndex(products, keyPath: \.protein, higherIsBetter: true)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(nutrientAccessibilityLabel("Protein", products: products, keyPath: \.protein))

            ComparisonRow(
                label: "Fiber",
                values: products.map { nutrientString($0.nutrition.fiber) },
                highlightedIndex: bestNutrientIndex(products, keyPath: \.fiber, higherIsBetter: true)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(nutrientAccessibilityLabel("Fiber", products: products, keyPath: \.fiber))

            ComparisonRow(
                label: "Sugar",
                values: products.map { nutrientString($0.nutrition.sugar) },
                highlightedIndex: bestNutrientIndex(products, keyPath: \.sugar, higherIsBetter: false)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(nutrientAccessibilityLabel("Sugar", products: products, keyPath: \.sugar))

            ComparisonRow(
                label: "Sodium",
                values: products.map { sodiumString($0.nutrition.sodium) },
                highlightedIndex: bestNutrientIndex(products, keyPath: \.sodium, higherIsBetter: false)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(sodiumAccessibilityLabel(products))

            ComparisonRow(
                label: "Calories",
                values: products.map { calorieString($0.nutrition.calories) },
                highlightedIndex: bestNutrientIndex(products, keyPath: \.calories, higherIsBetter: false)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(nutrientAccessibilityLabel("Calories", products: products, keyPath: \.calories))
        }
    }

    // MARK: - Helpers

    private func bestScoreIndex(_ products: [ProductModel]) -> Int? {
        guard !products.isEmpty else { return nil }
        return products.enumerated().max(by: { $0.element.healthScore < $1.element.healthScore })?.offset
    }

    private func bestNutrientIndex(_ products: [ProductModel], keyPath: KeyPath<ProductNutrition, Double>, higherIsBetter: Bool) -> Int? {
        guard !products.isEmpty else { return nil }

        if higherIsBetter {
            return products.enumerated().max(by: { $0.element.nutrition[keyPath: keyPath] < $1.element.nutrition[keyPath: keyPath] })?.offset
        } else {
            return products.enumerated().min(by: { $0.element.nutrition[keyPath: keyPath] < $1.element.nutrition[keyPath: keyPath] })?.offset
        }
    }

    private func nutrientString(_ value: Double) -> String {
        return String(format: "%.1fg", value)
    }

    private func calorieString(_ value: Double) -> String {
        return String(format: "%.0f", value)
    }

    private func sodiumString(_ grams: Double) -> String {
        String(format: "%.0fmg", grams * 1_000)
    }

    // MARK: - Accessibility Labels

    private func scoreAccessibilityLabel(_ products: [ProductModel]) -> String {
        let scores = products.enumerated().map { index, product in
            "Product \(index + 1): \(String(format: "%.0f", product.healthScore)) points"
        }.joined(separator: ", ")
        return "Scores: \(scores)"
    }

    private func nutrientAccessibilityLabel(_ nutrientName: String, products: [ProductModel], keyPath: KeyPath<ProductNutrition, Double>) -> String {
        let values = products.enumerated().map { index, product in
            let value = product.nutrition[keyPath: keyPath]
            return "Product \(index + 1): \(nutrientString(value))"
        }.joined(separator: ", ")
        return "\(nutrientName): \(values)"
    }

    private func sodiumAccessibilityLabel(_ products: [ProductModel]) -> String {
        let values = products.enumerated().map { index, product in
            "Product \(index + 1): \(sodiumString(product.nutrition.sodium))"
        }.joined(separator: ", ")
        return "Sodium: \(values)"
    }
}

// MARK: - Product Header Card

private struct ProductHeaderCard: View {
    let product: ProductModel
    let onTap: () -> Void
    let onRemove: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: Spacing.xs) {
                // Remove button
                HStack {
                    Spacer()
                    Button {
                        onRemove()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.textTertiary)
                    }
                    .accessibilityLabel("Remove \(product.name) from comparison")
                }

                // Product image placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(Color.backgroundSecondary)
                        .frame(width: 60, height: 60)

                    Image(systemName: "cube.box.fill")
                        .font(.title2)
                        .foregroundColor(.textTertiary)
                }
                .accessibilityHidden(true)

                // Product name
                Text(product.name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(Int(product.healthScore.rounded()))")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Color.scoreColor(for: product.healthScore))
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.sm)
            .background(Color.cardBackground)
            .cornerRadius(CornerRadius.card)
        }
        .accessibilityLabel(product.name)
        .accessibilityHint("Double tap to view full product details")
    }
}

// MARK: - Comparison Row

private struct ComparisonRow: View {
    let label: String
    let values: [String]
    let highlightedIndex: Int?
    var isScore: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            // Metric label
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.textSecondary)
                .frame(width: 100, alignment: .leading)
                .accessibilityHidden(true)

            // Values for each product
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                Text(value)
                    .font(highlightedIndex == index ? .callout.weight(.bold) : .callout)
                    .foregroundColor(
                        highlightedIndex == index
                            ? (isScore ? Color.scoreColor(for: Double(value) ?? 0) : Color.scoreExcellent)
                            : Color.textPrimary
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xs)
                    .background(highlightedIndex == index ? Color.scoreExcellent.opacity(0.1) : Color.clear)
                    .cornerRadius(CornerRadius.xs)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, Spacing.screenPadding)
    }
}

// MARK: - Preview

#Preview {
    ComparisonModeView(appState: AppState(), viewModel: ComparisonModeViewModel())
}
