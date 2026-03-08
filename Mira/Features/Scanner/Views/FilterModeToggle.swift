import SwiftUI

/// Toggle switch for enabling/disabling dietary filter mode in scanner
struct FilterModeToggle: View {
    @Binding var isFilterModeEnabled: Bool
    let activeRestrictions: [DietaryRestriction]

    var body: some View {
        VStack(spacing: 0) {
            // Toggle row
            HStack(spacing: Spacing.sm) {
                Image(systemName: isFilterModeEnabled ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .font(.title3)
                    .foregroundColor(isFilterModeEnabled ? .primaryBlue : .white)

                Text("Filter Mode")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Spacer()

                Toggle("", isOn: $isFilterModeEnabled)
                    .labelsHidden()
                    .tint(.primaryBlue)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)

            // Active filters indicator (when enabled)
            if isFilterModeEnabled && !activeRestrictions.isEmpty {
                Divider()
                    .background(Color.white.opacity(0.2))

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Active filters:")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.8))
                        .textCase(.uppercase)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.xs) {
                            ForEach(activeRestrictions, id: \.self) { restriction in
                                DietaryFilterBadge(restriction: restriction)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }

            // Empty state (when enabled but no restrictions selected)
            if isFilterModeEnabled && activeRestrictions.isEmpty {
                Divider()
                    .background(Color.white.opacity(0.2))

                HStack(spacing: Spacing.sm) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.orange)

                    Text("No dietary restrictions selected. Go to Settings to add filters.")
                        .font(.caption)
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
        }
    }
}

// MARK: - Dietary Filter Badge

private struct DietaryFilterBadge: View {
    let restriction: DietaryRestriction

    var body: some View {
        Text(restriction.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.primaryBlue)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 4)
            .background(Color.primaryBlue.opacity(0.15))
            .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.xl) {
        // Filter mode disabled
        FilterModeToggle(
            isFilterModeEnabled: .constant(false),
            activeRestrictions: [.vegan, .glutenFree]
        )

        // Filter mode enabled with restrictions
        FilterModeToggle(
            isFilterModeEnabled: .constant(true),
            activeRestrictions: [.vegan, .glutenFree, .dairyFree]
        )

        // Filter mode enabled without restrictions
        FilterModeToggle(
            isFilterModeEnabled: .constant(true),
            activeRestrictions: []
        )

        Spacer()
    }
    .background(Color.backgroundPrimary)
}
