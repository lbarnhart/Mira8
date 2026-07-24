import SwiftUI
import CoreData

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var favoriteStatuses: [String: Bool] = [:]
    @State private var navigationPath: [String] = []

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if viewModel.items.isEmpty {
                    EmptyStateView(
                        title: "No scans yet",
                        subtitle: "Scan a product to start building your history.",
                        systemImage: "tray"
                    )
                    .padding(Spacing.sectionSpacing)
                    .accessibilityIdentifier("history.empty")
                } else {
                    List {
                        // Average Score Header
                        if let avgScore = viewModel.averageRecentScore {
                            Section {
                                AverageScoreHeader(averageScore: avgScore)
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                        }

                        ForEach(sections) { section in
                            sectionView(for: section)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(Color.backgroundPrimary)
                    .padding(.bottom, Size.tabBarHeight)
                    .clipped()
                }
            }
            .navigationTitle("History")
            .alert(
                "Something went wrong",
                isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { _ in viewModel.errorMessage = nil })
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onAppear {
                viewModel.updateCurrentHealthFocus(appState.healthFocus)
                viewModel.fetchHistory()
                loadFavoriteStatuses()
            }
            .onChange(of: appState.healthFocus) { newFocus in
                viewModel.updateCurrentHealthFocus(newFocus)
            }
            .onChange(of: favoriteStatusTrigger) { _ in
                loadFavoriteStatuses()
            }
            .navigationDestination(for: String.self) { barcode in
                ProductDetailView(barcode: barcode)
            }
        }
    }

    // MARK: - Favorites

    private func loadFavoriteStatuses() {
        let context = PersistenceController.shared.container.viewContext
        let barcodes = viewModel.items.map { $0.product.barcode }

        guard !barcodes.isEmpty else { return }

        context.perform {
            let request: NSFetchRequest<ProductEntity> = ProductEntity.fetchRequest()
            request.predicate = NSPredicate(format: "barcode IN %@", barcodes)

            do {
                let entities = try context.fetch(request)
                var statuses: [String: Bool] = [:]

                for entity in entities {
                    if let barcode = entity.barcode {
                        statuses[barcode] = entity.isFavorite
                    }
                }

                DispatchQueue.main.async {
                    self.favoriteStatuses = statuses
                }
            } catch {
                AppLog.error("Failed to load favorite statuses: \(error.localizedDescription)", category: .persistence)
            }
        }
    }

    private func toggleFavorite(_ product: Product) {
        let context = PersistenceController.shared.container.viewContext
        let barcode = product.barcode

        context.perform {
            let request: NSFetchRequest<ProductEntity> = ProductEntity.fetchRequest()
            request.predicate = NSPredicate(format: "barcode == %@", barcode)
            request.fetchLimit = 1

            do {
                guard let entity = try context.fetch(request).first else {
                    AppLog.warning("Product not found for barcode: \(barcode)", category: .persistence)
                    return
                }

                entity.isFavorite.toggle()
                let newStatus = entity.isFavorite

                do {
                    try context.save()
                    let name = entity.name ?? "Unknown"
                    AppLog.debug("Toggled favorite for \(name) to \(newStatus)", category: .persistence)

                    DispatchQueue.main.async {
                        self.favoriteStatuses[barcode] = newStatus
                    }
                } catch {
                    AppLog.error("Failed to save favorite: \(error.localizedDescription)", category: .persistence)
                }
            } catch {
                AppLog.error("Failed to fetch product: \(error.localizedDescription)", category: .persistence)
            }
        }
    }

    private var favoriteStatusTrigger: [String] {
        viewModel.items.map { $0.product.barcode }
    }

    private var sections: [HistorySectionData] {
        let calendar = Calendar.current
        let now = Date()

        var buckets: [String: [HistoryItem]] = [:]

        for item in viewModel.items {
            let title: String
            let date = item.scanDate
            if calendar.isDateInToday(date) {
                title = "Today"
            } else if calendar.isDateInYesterday(date) {
                title = "Yesterday"
            } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
                title = "This Week"
            } else {
                title = "Older"
            }

            var list = buckets[title, default: []]
            list.append(item)
            buckets[title] = list.sorted { $0.scanDate > $1.scanDate }
        }

        let order = ["Today", "Yesterday", "This Week", "Older", "Unknown"]
        return buckets
            .map { HistorySectionData(title: $0.key, items: $0.value) }
            .sorted { lhs, rhs in
                let lhsIndex = order.firstIndex(of: lhs.title) ?? order.count
                let rhsIndex = order.firstIndex(of: rhs.title) ?? order.count
                if lhsIndex == rhsIndex {
                    let lhsDate = lhs.items.first?.scanDate ?? .distantPast
                    let rhsDate = rhs.items.first?.scanDate ?? .distantPast
                    return lhsDate > rhsDate
                }
                return lhsIndex < rhsIndex
            }
    }

    @ViewBuilder
    private func sectionView(for section: HistorySectionData) -> some View {
        Section {
            Text(section.title)
                .font(.headline)
                .foregroundColor(.textPrimary)
                .listRowInsets(
                    EdgeInsets(
                        top: Spacing.lg,
                        leading: Spacing.md,
                        bottom: Spacing.sm,
                        trailing: Spacing.md
                    )
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            ForEach(section.items) { item in
                HistoryRow(
                    item: item,
                    isFavorite: favoriteStatuses[item.product.barcode] ?? false,
                    onSelect: {
                        navigationPath.append(item.product.barcode)
                    },
                    onToggleFavorite: {
                        toggleFavorite(item.product)
                    }
                )
                .accessibilityIdentifier("history.row.\(item.product.barcode)")
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        viewModel.deleteItem(item)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
}

private struct HistorySectionData: Identifiable {
    let title: String
    let items: [HistoryItem]

    var id: String { title }
}

private struct HistoryRow: View {
    let item: HistoryItem
    let isFavorite: Bool
    let onSelect: () -> Void
    let onToggleFavorite: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            Button {
                onToggleFavorite()
            } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.body)
                    .foregroundColor(isFavorite ? .red : .textSubduedAccessible)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onSelect) {
                HStack(alignment: .center, spacing: Spacing.md) {
                    AsyncProductImage(
                        url: item.product.thumbnailURL ?? item.product.imageURL,
                        size: .small,
                        cornerRadius: CornerRadius.button
                    )

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(productName)
                            .font(.body.weight(.semibold))
                            .foregroundColor(.textPrimary)
                            .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)

                        if let brand = productBrand, !brand.isEmpty {
                            Text(brand)
                                .font(.caption)
                                .foregroundColor(.textPrimary)
                        }

                        Text(scanDateString)
                            .font(.caption)
                            .foregroundColor(.textPrimary)

                        #if DEBUG
                        if item.hasHealthFocusChanged {
                            Text("Rescored for \(item.currentHealthFocus)")
                                .font(.caption2)
                                .foregroundColor(.primaryBlue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.primaryBlue.opacity(0.1))
                                .cornerRadius(CornerRadius.pill)
                        }
                        #endif
                    }

                    Spacer()

                    Text("\(item.currentScore)")
                        .font(.headline.weight(.bold))
                        .monospacedDigit()
                        .foregroundColor(Color.scoreColor(for: Double(item.currentScore)))
                        .fixedSize(horizontal: true, vertical: false)
                        .accessibilityLabel("Mira score")
                        .accessibilityValue("\(item.currentScore) out of 100")

                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.textSubduedAccessible)
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, Spacing.sm)
        .accessibilityIdentifier("history.item.\(item.product.barcode)")
    }

    private var productName: String {
        item.product.name
    }

    private var productBrand: String? {
        item.product.brand
    }

    private var scanDateString: String {
        HistoryRow.dateFormatter.string(from: item.scanDate)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

private struct AverageScoreHeader: View {
    let averageScore: Double

    private var scoreColor: Color {
        Color.scoreColor(for: averageScore)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: Spacing.sm) {
                Text("Average Score")
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)

                Spacer()

                Text("\(Int(averageScore.rounded()))")
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                    .foregroundColor(scoreColor)
            }

            Text("Last 30 days")
                .font(.caption)
                .foregroundColor(.textSubduedAccessible)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
    }
}

#Preview {
    HistoryView()
        .environmentObject(AppState())
}
