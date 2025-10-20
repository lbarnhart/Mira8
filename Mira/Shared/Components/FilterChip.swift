import SwiftUI

// MARK: - Filter Chip Component
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    init(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .captionLargeStyle()
                .foregroundColor(foregroundColor)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(backgroundColor)
                .cornerRadius(CornerRadius.pill)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    private var foregroundColor: Color {
        isSelected ? .textOnDark : .textSecondary
    }

    private var backgroundColor: Color {
        isSelected ? .oceanTeal : .backgroundSecondary
    }
}

// MARK: - Filter Chip Group
struct FilterChipGroup<T: Hashable>: View {
    let items: [T]
    let selectedItem: T
    let displayName: (T) -> String
    let onSelection: (T) -> Void

    init(
        items: [T],
        selectedItem: T,
        displayName: @escaping (T) -> String,
        onSelection: @escaping (T) -> Void
    ) {
        self.items = items
        self.selectedItem = selectedItem
        self.displayName = displayName
        self.onSelection = onSelection
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(items, id: \.self) { item in
                    FilterChip(
                        title: displayName(item),
                        isSelected: selectedItem == item
                    ) {
                        onSelection(item)
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
    }
}

// MARK: - Multi-Select Filter Chip
struct MultiSelectFilterChip: View {
    let title: String
    let isSelected: Bool
    let count: Int?
    let action: () -> Void

    init(
        title: String,
        isSelected: Bool,
        count: Int? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isSelected = isSelected
        self.count = count
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Text(title)
                    .captionLargeStyle()
                    .foregroundColor(foregroundColor)

                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.textOnDark)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.error)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(backgroundColor)
            .cornerRadius(CornerRadius.pill)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.pill)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    private var foregroundColor: Color {
        isSelected ? .oceanTeal : .textSecondary
    }

    private var backgroundColor: Color {
        isSelected ? .oceanTeal.opacity(0.1) : .backgroundSecondary
    }

    private var borderColor: Color {
        isSelected ? .oceanTeal : .clear
    }

    private var borderWidth: CGFloat {
        isSelected ? 1 : 0
    }
}

// MARK: - Filter Chip with Icon
struct IconFilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    init(
        title: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(foregroundColor)

                Text(title)
                    .captionLargeStyle()
                    .foregroundColor(foregroundColor)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(backgroundColor)
            .cornerRadius(CornerRadius.pill)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    private var foregroundColor: Color {
        isSelected ? .textOnDark : .textSecondary
    }

    private var backgroundColor: Color {
        isSelected ? .oceanTeal : .backgroundSecondary
    }
}

// MARK: - Filter Bar Component
struct FilterBar<T: Hashable>: View {
    let title: String?
    let items: [T]
    let selectedItem: T
    let displayName: (T) -> String
    let onSelection: (T) -> Void

    init(
        title: String? = nil,
        items: [T],
        selectedItem: T,
        displayName: @escaping (T) -> String,
        onSelection: @escaping (T) -> Void
    ) {
        self.title = title
        self.items = items
        self.selectedItem = selectedItem
        self.displayName = displayName
        self.onSelection = onSelection
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let title = title {
                HStack {
                    Text(title)
                        .bodySmallStyle()
                        .foregroundColor(.textSecondary)

                    Spacer()
                }
                .padding(.horizontal, Spacing.lg)
            }

            FilterChipGroup(
                items: items,
                selectedItem: selectedItem,
                displayName: displayName,
                onSelection: onSelection
            )
        }
    }
}

// MARK: - Preview
private struct FilterChipPreview: View {
    @State private var previewSelectedFilter = "All"

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Single chip
            FilterChip(title: "All", isSelected: true) {}

            // Chip group
            let filters = ["All", "Recent", "Favorites", "High Score"]

            FilterChipGroup(
                items: filters,
                selectedItem: previewSelectedFilter,
                displayName: { $0 }
            ) { filter in
                previewSelectedFilter = filter
            }

            // Multi-select chip
            MultiSelectFilterChip(
                title: "Dietary",
                isSelected: true,
                count: 3
            ) {}

            // Icon chip
            IconFilterChip(
                title: "Healthy",
                icon: "heart.fill",
                isSelected: false
            ) {}
        }
        .padding()
    }
}

#Preview {
    FilterChipPreview()
}
