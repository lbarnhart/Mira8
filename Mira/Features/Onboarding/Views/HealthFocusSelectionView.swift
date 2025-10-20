import SwiftUI

struct HealthFocusSelectionView: View {
    @Binding var selectedFocus: String?
    let onSelection: (String) -> Void

    private let options = HealthFocusOption.all

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("What's your health focus?")
                    .font(.title2.bold())
                    .foregroundColor(.textPrimary)

                Text("Pick the goal that best matches what you're working toward.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Spacing.screenPadding)

            VStack(spacing: Spacing.sm) {
                ForEach(options) { option in
                    PressableCard(style: .standard, action: {
                        onSelection(option.id)
                    }) {
                        HStack(alignment: .center, spacing: Spacing.md) {
                            ZStack {
                                if option.isSystemIcon {
                                    Image(systemName: option.icon)
                                        .font(.system(size: 22))
                                        .foregroundColor(option.tint)
                                } else {
                                    Image(option.icon)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 24, height: 24)
                                }
                            }
                            .frame(width: 40, height: 40)
                            .background(option.tint.opacity(0.12))
                            .cornerRadius(CornerRadius.button)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(option.title)
                                        .font(.headline)
                                        .foregroundColor(.textPrimary)

                                    Spacer()

                                    Image(systemName: selectedFocus == option.id ? "largecircle.fill.circle" : "circle")
                                        .foregroundColor(selectedFocus == option.id ? .primaryBlue : .textTertiary)
                                }

                                Text(option.description)
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.card)
                            .stroke(
                                selectedFocus == option.id ? Color.primaryBlue : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .padding(.horizontal, Spacing.screenPadding)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, Spacing.xl)
    }
}

#Preview {
    HealthFocusSelectionView(selectedFocus: .constant("gutHealth")) { _ in }
        .background(Color.backgroundPrimary)
}
