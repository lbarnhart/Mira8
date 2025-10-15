import SwiftUI

struct DietaryRestrictionsView: View {
    @Binding var selectedRestrictions: Set<String>
    let onToggle: (String) -> Void
    let onSkip: () -> Void

    private let options = DietaryRestrictionOption.all

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Any dietary restrictions?")
                    .font(.title2.bold())
                    .foregroundColor(.textPrimary)

                Text("Select all that apply so we can flag products that may not fit.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: Spacing.xs) {
                ForEach(options) { option in
                    PressableCard(style: .minimal, action: {
                        if option.id == "none" {
                            onToggle("none")
                        } else {
                            onToggle(option.id)
                        }
                    }) {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: option.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primaryBlue)
                                .frame(width: 28, height: 28)
                                .background(Color.primaryBlue.opacity(0.12))
                                .cornerRadius(CornerRadius.button)

                            Text(option.title)
                                .font(.body.weight(.semibold))
                                .foregroundColor(.textPrimary)

                            Spacer()

                            let isSelected = option.id == "none" ? selectedRestrictions.isEmpty : selectedRestrictions.contains(option.id)

                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isSelected ? .primaryBlue : .textTertiary)
                                .font(.system(size: 18))
                        }
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.card)
                                .fill(Color.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.card)
                                .stroke(
                                    outlineColor(for: option.id),
                                    lineWidth: 1
                                )
                        )
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.screenPadding)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func outlineColor(for optionId: String) -> Color {
        if optionId == "none" {
            return selectedRestrictions.isEmpty ? .primaryBlue : .clear
        }
        return selectedRestrictions.contains(optionId) ? .primaryBlue : .clear
    }
}

#Preview {
    DietaryRestrictionsView(selectedRestrictions: .constant(["vegan", "glutenFree"])) { _ in } onSkip: {}
        .background(Color.backgroundPrimary)
}
