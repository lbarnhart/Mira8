import SwiftUI

// MARK: - Search Bar Component
struct SearchBar: View {
    @Binding var searchText: String
    let placeholder: String
    let showClearButton: Bool

    init(
        searchText: Binding<String>,
        placeholder: String = "Search...",
        showClearButton: Bool = true
    ) {
        self._searchText = searchText
        self.placeholder = placeholder
        self.showClearButton = showClearButton
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            searchField

            if showClearButton && !searchText.isEmpty {
                clearButton
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textTertiary)
                .font(.system(size: Size.iconSM))

            TextField(placeholder, text: $searchText)
                .bodyMediumStyle()
                .submitLabel(.search)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(.backgroundSecondary)
        .cornerRadius(CornerRadius.sm)
    }

    private var clearButton: some View {
        Button("Clear") {
            searchText = ""
        }
        .captionMediumStyle()
        .foregroundColor(.oceanTeal)
    }
}

// MARK: - Animated Search Bar
struct AnimatedSearchBar: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    let placeholder: String

    @FocusState private var isTextFieldFocused: Bool

    init(
        searchText: Binding<String>,
        isSearching: Binding<Bool>,
        placeholder: String = "Search..."
    ) {
        self._searchText = searchText
        self._isSearching = isSearching
        self.placeholder = placeholder
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            searchField

            if isSearching {
                cancelButton
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSearching)
        .onChange(of: isTextFieldFocused) { newValue in
            withAnimation(.easeInOut(duration: 0.2)) {
                isSearching = newValue
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textTertiary)
                .font(.system(size: Size.iconSM))

            TextField(placeholder, text: $searchText)
                .bodyMediumStyle()
                .focused($isTextFieldFocused)
                .submitLabel(.search)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(.backgroundSecondary)
        .cornerRadius(CornerRadius.sm)
    }

    private var cancelButton: some View {
        Button("Cancel") {
            searchText = ""
            isTextFieldFocused = false
            withAnimation(.easeInOut(duration: 0.2)) {
                isSearching = false
            }
        }
        .bodyMediumStyle()
        .foregroundColor(.oceanTeal)
    }
}

// MARK: - Preview
private struct SearchBarPreview: View {
    @State private var previewSearchText1 = ""
    @State private var previewSearchText2 = ""
    @State private var previewIsSearching = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            SearchBar(
                searchText: $previewSearchText1,
                placeholder: "Search products..."
            )

            AnimatedSearchBar(
                searchText: $previewSearchText2,
                isSearching: $previewIsSearching,
                placeholder: "Search with animation..."
            )
        }
        .padding()
    }
}

#Preview {
    SearchBarPreview()
}
