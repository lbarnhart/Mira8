import SwiftUI

/// A reusable filter chip button used in History and Favorites views
struct FilterChipButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .textPrimary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.primaryBlue : Color.backgroundSecondary)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.cardBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack(spacing: Spacing.sm) {
        FilterChipButton(title: "All", isSelected: true) {}
        FilterChipButton(title: "Today", isSelected: false) {}
        FilterChipButton(title: "High Score", isSelected: false) {}
    }
    .padding()
}
