import SwiftUI

struct ShoppingListView: View {
    @StateObject private var viewModel = ShoppingListViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var showShareSheet = false
    @State private var shareText = ""
    @State private var selectedProductBarcode: String?
    @State private var showProductDetail = false

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.items.isEmpty {
                    emptyState
                } else {
                    listContent
                }
            }
            .background(Color.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Shopping List")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            shareText = viewModel.shareList()
                            showShareSheet = true
                        } label: {
                            Label("Share List", systemImage: "square.and.arrow.up")
                        }

                        Divider()

                        Button(role: .destructive) {
                            viewModel.clearCheckedItems()
                        } label: {
                            Label("Clear Checked", systemImage: "checkmark.circle")
                        }
                        .disabled(viewModel.stats.checkedItems == 0)

                        Button(role: .destructive) {
                            viewModel.clearAllItems()
                        } label: {
                            Label("Clear All", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .accessibilityLabel("More options")
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ActivityViewController(activityItems: [shareText])
            }
            .sheet(isPresented: $showProductDetail) {
                if let barcode = selectedProductBarcode {
                    ProductDetailView(barcode: barcode)
                        .environmentObject(appState)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundColor(.textTertiary)
                .accessibilityHidden(true)

            Text("Your List is Empty")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)

            Text("Scan products and add them to your shopping list for easy tracking")
                .font(.callout)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxxl)

            Button {
                appState.selectedTab = Tab.scan.rawValue
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "barcode.viewfinder")
                    Text("Start Scanning")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.md)
                .background(Color.primaryBlue)
                .cornerRadius(CornerRadius.button)
            }
            .padding(.top, Spacing.md)
            .accessibilityLabel("Start scanning products")
            .accessibilityHint("Switches to scanner tab to add products to your list")
            .accessibilityIdentifier("shoppingList.startScanning")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("shoppingList.empty")
    }

    // MARK: - List Content

    private var listContent: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Statistics Card
                ShoppingListStatsCard(stats: viewModel.stats)
                    .padding(.horizontal, Spacing.screenPadding)
                    .padding(.top, Spacing.md)

                // Filters and Sort
                HStack(spacing: Spacing.md) {
                    // Filter Picker
                    Picker("Filter", selection: $viewModel.filterOption) {
                        ForEach(ShoppingListViewModel.FilterOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Filter shopping list")

                    // Sort Menu
                    Menu {
                        ForEach(ShoppingListViewModel.SortOption.allCases, id: \.self) { option in
                            Button {
                                viewModel.sortOption = option
                            } label: {
                                HStack {
                                    Text(option.rawValue)
                                    if viewModel.sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundColor(.primaryBlue)
                            .padding(Spacing.sm)
                            .background(Color.primaryBlue.opacity(0.1))
                            .cornerRadius(CornerRadius.xs)
                    }
                    .accessibilityLabel("Sort by \(viewModel.sortOption.rawValue)")
                    .accessibilityHint("Double tap to change sort order")
                }
                .padding(.horizontal, Spacing.screenPadding)

                // Item List
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(viewModel.filteredItems) { item in
                        ShoppingListItemRow(
                            item: item,
                            onToggle: {
                                viewModel.toggleItemChecked(item)
                            },
                            onTap: {
                                selectedProductBarcode = item.barcode
                                showProductDetail = true
                            },
                            onDelete: {
                                viewModel.removeItem(item)
                            }
                        )
                        .accessibilityIdentifier("shoppingList.item.\(item.barcode)")
                    }
                }
                .padding(.horizontal, Spacing.screenPadding)
                .padding(.bottom, Spacing.xxxl)
            }
        }
    }
}

// MARK: - Statistics Card

private struct ShoppingListStatsCard: View {
    let stats: ShoppingListStats

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(stats.totalItems) Items")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)

                    Text("\(stats.uncheckedItems) remaining")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                // Average Score Badge
                VStack(spacing: 2) {
                    Text("\(Int(stats.averageScore.rounded()))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.scoreColor(for: stats.averageScore))

                    Text("Avg Score")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
                .padding(Spacing.sm)
                .background(Color.scoreColor(for: stats.averageScore).opacity(0.1))
                .cornerRadius(CornerRadius.sm)
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.scoreExcellent)
                        .frame(
                            width: geometry.size.width * (stats.completionPercentage / 100),
                            height: 8
                        )
                }
            }
            .frame(height: 8)

            // Completion Text
            HStack {
                Text("\(Int(stats.completionPercentage))% Complete")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                Spacer()

                Text("\(stats.checkedItems)/\(stats.totalItems) checked")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            // Score Distribution
            if stats.totalItems > 0 {
                Divider()

                HStack(spacing: Spacing.md) {
                    ScoreDistributionBadge(
                        count: stats.scoreDistribution.excellent,
                        label: "Excellent",
                        color: .scoreExcellent
                    )

                    ScoreDistributionBadge(
                        count: stats.scoreDistribution.good,
                        label: "Good",
                        color: .scoreGood
                    )

                    ScoreDistributionBadge(
                        count: stats.scoreDistribution.fair,
                        label: "Fair",
                        color: .scoreFair
                    )

                    ScoreDistributionBadge(
                        count: stats.scoreDistribution.poor,
                        label: "Poor",
                        color: .scorePoor
                    )
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.card)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Shopping list statistics: \(stats.totalItems) items, average score \(Int(stats.averageScore.rounded())), \(Int(stats.completionPercentage))% complete")
    }
}

// MARK: - Score Distribution Badge

private struct ScoreDistributionBadge: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.callout)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(label)
                .font(.caption2)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xs)
        .background(color.opacity(0.1))
        .cornerRadius(CornerRadius.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) \(label) items")
    }
}

// MARK: - Shopping List Item Row

private struct ShoppingListItemRow: View {
    let item: ShoppingListItem
    let onToggle: () -> Void
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        let brandDescription = item.brand.map { ", \($0)" } ?? ""

        HStack(spacing: Spacing.md) {
            // Checkbox
            Button {
                onToggle()
            } label: {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(item.isChecked ? .scoreExcellent : .textTertiary)
            }
            .accessibilityLabel(item.isChecked ? "Checked" : "Unchecked")
            .accessibilityHint("Double tap to \(item.isChecked ? "uncheck" : "check") this item")

            // Content
            Button {
                onTap()
            } label: {
                HStack(spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.productName)
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundColor(item.isChecked ? .textSecondary : .textPrimary)
                            .strikethrough(item.isChecked)

                        if let brand = item.brand {
                            Text(brand)
                                .font(.caption)
                                .foregroundColor(.textTertiary)
                        }
                    }

                    Spacer()

                    // Score Badge
                    Text("\(Int(item.healthScore.rounded()))")
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundColor(Color.scoreColor(for: item.healthScore))
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 4)
                        .background(Color.scoreColor(for: item.healthScore).opacity(0.15))
                        .cornerRadius(CornerRadius.pill)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(item.productName)\(brandDescription), score \(Int(item.healthScore.rounded()))")
            .accessibilityHint("Double tap to view product details")

            // Delete Button
            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.error)
                    .padding(Spacing.xs)
            }
            .accessibilityLabel("Delete \(item.productName)")
        }
        .padding(Spacing.md)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.card)
        .accessibilityIdentifier("shoppingList.row.\(item.barcode)")
    }
}

// MARK: - Activity View Controller

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    ShoppingListView()
        .environmentObject(AppState())
}
