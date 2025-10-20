import SwiftUI

struct FavoritesView: View {
    @StateObject private var viewModel = FavoritesViewModel()
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.favorites.isEmpty {
                    EmptyStateView(
                        title: "No favorites yet",
                        subtitle: "Tap the heart icon on products to save your favorites.",
                        systemImage: "heart"
                    )
                    .padding(Spacing.sectionSpacing)
                } else {
                    List {
                        ForEach(viewModel.favorites) { product in
                            NavigationLink {
                                ProductDetailView(barcode: product.barcode)
                            } label: {
                                FavoriteProductCard(
                                    product: product,
                                    onRemoveFavorite: {
                                        viewModel.removeFavorite(product)
                                    }
                                )
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.removeFavorite(product)
                                } label: {
                                    Label("Remove", systemImage: "heart.slash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(Color.backgroundPrimary)
                }
            }
            .navigationTitle("Favorites")
            .alert(
                "Something went wrong",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { _ in viewModel.errorMessage = nil }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onAppear {
                viewModel.fetchFavorites()
            }
        }
    }
}

private struct FavoriteProductCard: View {
    let product: Product
    let onRemoveFavorite: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            AsyncProductImage(
                url: product.thumbnailURL ?? product.imageURL,
                size: .small,
                cornerRadius: CornerRadius.button
            )

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(product.name)
                    .font(.body.weight(.semibold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)

                if let brand = product.brand, !brand.isEmpty {
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                if let lastScanned = product.lastScanned {
                    Text("Last scanned: \(formatDate(lastScanned))")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
            }

            Spacer()

            Button {
                onRemoveFavorite()
            } label: {
                Image(systemName: "heart.fill")
                    .font(.title3)
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, Spacing.sm)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    FavoritesView()
        .environmentObject(AppState())
}
