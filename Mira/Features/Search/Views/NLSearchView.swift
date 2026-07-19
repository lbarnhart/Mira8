import SwiftUI

/// Natural language product search view
struct NLSearchView: View {
    @StateObject private var viewModel = NLSearchViewModel()
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar

                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        if viewModel.isParsing {
                            parsingIndicator
                        }

                        if let parsed = viewModel.parsedQuery, !parsed.filters.isEmpty {
                            filterChips(parsed: parsed)
                        }

                        if viewModel.isLoading && !viewModel.isParsing {
                            loadingView
                        } else if let error = viewModel.errorMessage {
                            errorView(error)
                        } else if viewModel.results.isEmpty && viewModel.query.isEmpty {
                            suggestionsView
                        } else if viewModel.results.isEmpty && !viewModel.query.isEmpty {
                            noResultsView
                        } else {
                            resultsView
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    sortMenu
                }
            }
            .onAppear {
                viewModel.configure(
                    healthFocus: HealthFocus(fromStored: appState.healthFocus),
                    restrictions: appState.dietaryRestrictions
                )
            }
            .onChange(of: appState.healthFocus) { newValue in
                viewModel.configure(
                    healthFocus: HealthFocus(fromStored: newValue),
                    restrictions: appState.dietaryRestrictions
                )
            }
            .onChange(of: appState.dietaryRestrictions) { newValue in
                viewModel.configure(
                    healthFocus: HealthFocus(fromStored: appState.healthFocus),
                    restrictions: newValue
                )
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textTertiary)

            TextField("Try \"high protein vegan snacks\"...", text: $viewModel.query)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit {
                    viewModel.search()
                }

            if !viewModel.query.isEmpty {
                Button {
                    viewModel.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.textTertiary)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
        .padding(.horizontal)
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Filter Chips

    @ViewBuilder
    private func filterChips(parsed: ParsedQuery) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("Filters")
                    .font(.caption)
                    .foregroundColor(.textTertiary)

                Spacer()

                if parsed.confidence >= 0.7 {
                    Label("Confident", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(parsed.filters.activeFiltersAsChips(), id: \.self) { chip in
                        SearchFilterTag(text: chip)
                    }
                }
            }

            if !parsed.interpretation.isEmpty {
                Text("Understood: \(parsed.interpretation)")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .italic()
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Parsing Indicator

    private var parsingIndicator: some View {
        HStack(spacing: Spacing.sm) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Understanding your search...")
                .font(.callout)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
            Text("Finding products...")
                .font(.callout)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text("Search failed")
                .font(.headline)

            Text(error)
                .font(.callout)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                viewModel.search()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - No Results View

    private var noResultsView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.textTertiary)

            Text("No products found")
                .font(.headline)

            Text("Try adjusting your search or removing some filters for \(HealthFocus(fromStored: appState.healthFocus).displayName.lowercased()).")
                .font(.callout)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Suggestions View

    private var suggestionsView: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Recent searches
            if !viewModel.recentSearches.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text("Recent")
                            .font(.headline)
                            .foregroundColor(.textPrimary)

                        Spacer()

                        Button("Clear") {
                            viewModel.clearRecentSearches()
                        }
                        .font(.caption)
                        .foregroundColor(.primaryBlue)
                    }

                    ForEach(viewModel.recentSearches, id: \.self) { search in
                        RecentSearchRow(
                            query: search,
                            onTap: { viewModel.searchWithSuggestion(search) },
                            onDelete: { viewModel.removeRecentSearch(search) }
                        )
                    }
                }
            }

            // Suggested searches
            VStack(alignment: .leading, spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Suggestions")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Text("Personalized for \(HealthFocus(fromStored: appState.healthFocus).displayName.lowercased())")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                ForEach(viewModel.suggestedQueries, id: \.self) { suggestion in
                    Button {
                        viewModel.searchWithSuggestion(suggestion)
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.primaryBlue)
                            Text(suggestion)
                                .foregroundColor(.textPrimary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.textTertiary)
                        }
                        .padding(Spacing.sm)
                        .background(Color.backgroundSecondary)
                        .cornerRadius(CornerRadius.sm)
                    }
                }
            }
        }
    }

    // MARK: - Results View

    private var resultsView: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if let topResult = viewModel.results.first {
                NavigationLink(destination: ProductDetailView(barcode: topResult.product.barcode)) {
                    topResultSpotlight(topResult)
                }
                .buttonStyle(.plain)
            }

            Text("\(viewModel.results.count) results")
                .font(.caption)
                .foregroundColor(.textTertiary)

            LazyVStack(spacing: Spacing.md) {
                ForEach(Array(viewModel.results.dropFirst())) { result in
                    NavigationLink(destination: ProductDetailView(barcode: result.product.barcode)) {
                        SearchResultCard(
                            result: result,
                            currentFocus: HealthFocus(fromStored: appState.healthFocus)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func topResultSpotlight(_ result: NLSearchResult) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Label("Best Match for \(HealthFocus(fromStored: appState.healthFocus).displayName)", systemImage: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primaryBlue)

                Spacer()

                Text("\(Int(result.healthScore.overall.rounded()))")
                    .font(.title3.bold())
                    .foregroundColor(scoreColor(result.healthScore.overall))
            }

            Text(result.product.name)
                .font(.headline)
                .foregroundColor(.textPrimary)
                .lineLimit(2)

            Text(topResultReason(for: result))
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if !result.matchedFilters.isEmpty {
                HStack(spacing: Spacing.xs) {
                    ForEach(result.matchedFilters.prefix(3), id: \.self) { filter in
                        SearchFilterTag(text: filter)
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.primaryBlue.opacity(0.12), Color.oceanTeal.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(CornerRadius.card)
    }

    // MARK: - Sort Menu

    private var sortMenu: some View {
        Menu {
            ForEach(SortOption.allCases, id: \.self) { option in
                Button {
                    viewModel.sortOption = option
                } label: {
                    HStack {
                        Text(option.displayName)
                        if viewModel.sortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .foregroundColor(.primaryBlue)
        }
    }

    private func topResultReason(for result: NLSearchResult) -> String {
        if let reason = result.healthScore.topReasons.first, !reason.isEmpty {
            return reason
        }

        if !result.matchedFilters.isEmpty {
            return "Matches \(result.matchedFilters.prefix(2).joined(separator: " and ")) for your search."
        }

        return "\(result.healthScore.verdict.message) for \(HealthFocus(fromStored: appState.healthFocus).displayName.lowercased())."
    }

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 80...100: return .scoreExcellent
        case 60..<80: return .scoreGood
        case 40..<60: return .scoreFair
        default: return .scorePoor
        }
    }
}

// MARK: - Supporting Views

struct SearchFilterTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 4)
            .background(Color.primaryBlue.opacity(0.12))
            .foregroundColor(.primaryBlue)
            .cornerRadius(CornerRadius.sm)
    }
}

struct RecentSearchRow: View {
    let query: String
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Button(action: onTap) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.textTertiary)
                    Text(query)
                        .foregroundColor(.textPrimary)
                    Spacer()
                }
            }

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
        }
        .padding(Spacing.sm)
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.sm)
    }
}

struct SearchResultCard: View {
    let result: NLSearchResult
    let currentFocus: HealthFocus

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Product image
            if let urlString = result.product.thumbnailURL ?? result.product.imageURL,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        productInitialsPlaceholder
                    default:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(width: 60, height: 60)
                .cornerRadius(CornerRadius.sm)
            } else {
                productInitialsPlaceholder
                    .frame(width: 60, height: 60)
                    .cornerRadius(CornerRadius.sm)
            }

            // Product info
            VStack(alignment: .leading, spacing: 4) {
                Text(result.product.name)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)

                if let brand = result.product.brand {
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                // Matched filters
                if !result.matchedFilters.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(result.matchedFilters.prefix(3), id: \.self) { filter in
                            Text(filter)
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.scoreExcellent.opacity(0.12))
                                .foregroundColor(.scoreExcellent)
                                .cornerRadius(4)
                        }
                    }
                }

                Text(explanationText)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            // Health score
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(result.healthScore.overall.rounded()))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor(result.healthScore.overall))

                Text("score")
                    .font(.caption2)
                    .foregroundColor(.textTertiary)

                Text(result.healthScore.verdict.label)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(scoreColor(result.healthScore.overall))
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
    }

    private var productInitialsPlaceholder: some View {
        ZStack {
            Color.primaryBlue.opacity(0.12)
            VStack(spacing: 2) {
                Image(systemName: categoryIcon)
                    .font(.system(size: 18))
                    .foregroundColor(.primaryBlue)
                Text(productInitials)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryBlue)
                    .lineLimit(1)
            }
        }
    }

    private var productInitials: String {
        let words = result.product.name
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        let initials = words.prefix(2).compactMap { $0.first }.map { String($0).uppercased() }
        return initials.joined()
    }

    private var categoryIcon: String {
        let category = (result.product.category ?? "").lowercased()
        if category.contains("beverage") || category.contains("drink") || category.contains("juice") {
            return "cup.and.saucer.fill"
        } else if category.contains("snack") || category.contains("chip") || category.contains("cracker") {
            return "takeoutbag.and.cup.and.straw.fill"
        } else if category.contains("cereal") || category.contains("breakfast") || category.contains("grain") {
            return "sun.horizon.fill"
        } else if category.contains("dairy") || category.contains("milk") || category.contains("yogurt") {
            return "drop.fill"
        } else if category.contains("meat") || category.contains("poultry") || category.contains("chicken") {
            return "fork.knife"
        } else if category.contains("fruit") || category.contains("vegetable") || category.contains("produce") {
            return "leaf.fill"
        } else if category.contains("bread") || category.contains("baked") || category.contains("bakery") {
            return "birthday.cake.fill"
        } else {
            return "cart.fill"
        }
    }

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 80...100: return .scoreExcellent
        case 60..<80: return .scoreGood
        case 40..<60: return .scoreFair
        default: return .scorePoor
        }
    }

    private var explanationText: String {
        if let reason = result.healthScore.topReasons.first, !reason.isEmpty {
            return reason
        }

        if !result.matchedFilters.isEmpty {
            return "Strong match for \(currentFocus.displayName.lowercased()) and your search filters."
        }

        return result.healthScore.verdict.message
    }
}

// MARK: - SearchFilters Extension

extension SearchFilters {
    func activeFiltersAsChips() -> [String] {
        var chips: [String] = []

        if let min = proteinMin { chips.append("Protein ≥\(Int(min))g") }
        if let max = caloriesMax { chips.append("≤\(Int(max)) cal") }
        if let max = sugarMax { chips.append("Sugar ≤\(Int(max))g") }
        if let min = fiberMin { chips.append("Fiber ≥\(Int(min))g") }
        if let max = sodiumMax { chips.append("Sodium ≤\(Int(max))mg") }
        if let max = carbsMax { chips.append("Carbs ≤\(Int(max))g") }
        if let max = fatMax { chips.append("Fat ≤\(Int(max))g") }

        for restriction in dietaryRestrictions {
            chips.append(restriction.capitalized.replacingOccurrences(of: "_", with: " "))
        }

        for category in categories {
            chips.append(category.capitalized)
        }

        return chips
    }
}


#Preview {
    NLSearchView()
        .environmentObject(AppState.shared)
}
