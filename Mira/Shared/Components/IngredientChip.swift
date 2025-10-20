import SwiftUI

struct IngredientChip: View {
    let item: IngredientItem
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: item.iconName)
                    .foregroundColor(item.accentColor)
                Text(item.displayName)
                    .font(.bodyMedium)
                    .foregroundColor(.textPrimary)
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }

            if isExpanded {
                Text(item.explanation)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.leading)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .background(item.backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .stroke(item.accentColor.opacity(0.4), lineWidth: 1)
        )
        .cornerRadius(CornerRadius.card)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        IngredientChip(
            item: IngredientItem(
                analysis: IngredientAnalysis(
                    originalName: "inulin",
                    displayName: "Inulin",
                    normalizedName: "inulin",
                    category: .beneficial,
                    explanation: "A prebiotic fiber that feeds helpful gut bacteria.",
                    position: 1
                )
            ),
            isExpanded: .constant(false)
        )

        IngredientChip(
            item: IngredientItem(
                analysis: IngredientAnalysis(
                    originalName: "high fructose corn syrup",
                    displayName: "High Fructose Corn Syrup",
                    normalizedName: "high fructose corn syrup",
                    category: .concerning,
                    explanation: "A highly processed sweetener linked to metabolic issues when consumed in excess.",
                    position: 3
                )
            ),
            isExpanded: .constant(true)
        )
    }
    .padding()
    .background(Color.backgroundPrimary)
}
