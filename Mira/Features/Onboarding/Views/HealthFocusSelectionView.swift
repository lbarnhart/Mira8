import SwiftUI

struct HealthFocusSelectionView: View {
    @Binding var selectedFocus: String?
    let onSelection: (String) -> Void

    private let options = HealthFocusOption.all
    @State private var expandedOption: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("What's your health focus?")
                        .font(.title2.bold())
                        .foregroundColor(.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    Text("Pick the goal that best matches what you're working toward. Tap to see examples.")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, Spacing.screenPadding)

                VStack(spacing: Spacing.sm) {
                    ForEach(options) { option in
                        VStack(spacing: 0) {
                            // Main selection card
                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    if expandedOption == option.id {
                                        expandedOption = nil
                                    } else {
                                        expandedOption = option.id
                                        onSelection(option.id)
                                    }
                                }
                            } label: {
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
                                    .accessibilityHidden(true)

                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text(option.title)
                                                .font(.headline)
                                                .foregroundColor(.textPrimary)

                                            Spacer()

                                            Image(systemName: selectedFocus == option.id ? "largecircle.fill.circle" : "circle")
                                                .foregroundColor(selectedFocus == option.id ? .primaryBlue : .textTertiary)
                                                .accessibilityHidden(true)
                                        }

                                        Text(option.description)
                                            .font(.caption)
                                            .foregroundColor(.textSecondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(Spacing.md)
                            }
                            .background(Color.cardBackground)
                            .cornerRadius(CornerRadius.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.card)
                                    .stroke(
                                        selectedFocus == option.id ? Color.primaryBlue : Color.cardBorder,
                                        lineWidth: selectedFocus == option.id ? 2 : 1
                                    )
                            )
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(option.title), \(option.description)")
                            .accessibilityHint(selectedFocus == option.id ? "Selected. Double tap to see example comparison." : "Double tap to select and see example comparison.")
                            .accessibilityAddTraits(selectedFocus == option.id ? [.isButton, .isSelected] : .isButton)

                            // Interactive preview (expands when tapped)
                            if expandedOption == option.id {
                                InteractiveHealthFocusPreview(selectedFocus: option.id)
                                    .padding(.top, Spacing.sm)
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .scale.combined(with: .opacity)
                                    ))
                            }
                        }
                        .padding(.horizontal, Spacing.screenPadding)
                    }
                }
            }
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.xxxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Interactive Preview Component

private struct InteractiveHealthFocusPreview: View {
    let selectedFocus: String

    // Example product data for demonstration
    private let exampleProduct = ExampleProduct(
        name: "Greek Yogurt (Plain, Low-Fat)",
        scores: [
            "gutHealth": 85,
            "heartHealth": 78,
            "proteinFocus": 92,
            "weightLoss": 74,
            "generalWellness": 80
        ]
    )

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack(spacing: Spacing.xs) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(.primaryBlue)
                    .accessibilityHidden(true)

                Text("How personalization works")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            Divider()

            // Example product
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Example: \(exampleProduct.name)")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                // Your score (selected focus)
                if let yourScore = exampleProduct.scores[selectedFocus] {
                    ScoreComparisonRow(
                        label: "Your score",
                        score: yourScore,
                        isHighlighted: true,
                        focusName: focusName(for: selectedFocus)
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Your \(focusName(for: selectedFocus)) score: \(yourScore) out of 100")
                    .accessibilityHint("This is how this product scores for your selected health focus")
                }

                // Comparison scores (other focuses)
                Text("Other health focuses see:")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .padding(.top, Spacing.xs)
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: Spacing.xs) {
                    ForEach(otherFocuses, id: \.self) { focus in
                        if let score = exampleProduct.scores[focus] {
                            ScoreComparisonRow(
                                label: focusName(for: focus),
                                score: score,
                                isHighlighted: false,
                                focusName: focusName(for: focus)
                            )
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(focusName(for: focus)) score: \(score) out of 100")
                        }
                    }
                }
            }

            // Educational message
            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: "info.circle.fill")
                    .font(.caption)
                    .foregroundColor(.info)
                    .accessibilityHidden(true)

                Text("Different health goals prioritize different nutrients. Your score is personalized to what matters most for your focus.")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Spacing.sm)
            .background(Color.info.opacity(0.05))
            .cornerRadius(CornerRadius.sm)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Information: Different health goals prioritize different nutrients. Your score is personalized to what matters most for your focus.")
        }
        .padding(Spacing.md)
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.card)
    }

    private var otherFocuses: [String] {
        exampleProduct.scores.keys.filter { $0 != selectedFocus }.sorted()
    }

    private func focusName(for id: String) -> String {
        HealthFocusOption.option(for: id)?.title ?? id
    }
}

// MARK: - Score Comparison Row

private struct ScoreComparisonRow: View {
    let label: String
    let score: Int
    let isHighlighted: Bool
    let focusName: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Text(label)
                .font(isHighlighted ? .callout.weight(.semibold) : .caption)
                .foregroundColor(isHighlighted ? .textPrimary : .textSecondary)
                .frame(width: 100, alignment: .leading)

            // Score badge
            Text("\(score)")
                .font(isHighlighted ? .callout.weight(.bold) : .caption.weight(.medium))
                .foregroundColor(isHighlighted ? Color.scoreColor(for: Double(score)) : .textSecondary)
                .frame(width: 32, alignment: .trailing)

            // Visual bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: isHighlighted ? 8 : 6)

                    // Filled portion
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            isHighlighted
                                ? Color.scoreColor(for: Double(score))
                                : Color.gray.opacity(0.4)
                        )
                        .frame(
                            width: geometry.size.width * CGFloat(score) / 100.0,
                            height: isHighlighted ? 8 : 6
                        )
                }
            }
            .frame(height: isHighlighted ? 8 : 6)
            .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
        .background(isHighlighted ? Color.primaryBlue.opacity(0.05) : Color.clear)
        .cornerRadius(CornerRadius.xs)
    }
}

// MARK: - Example Product Model

private struct ExampleProduct {
    let name: String
    let scores: [String: Int]
}

#Preview("Default Selection") {
    HealthFocusSelectionView(selectedFocus: .constant("gutHealth")) { _ in }
        .background(Color.backgroundPrimary)
}

#Preview("With Preview Expanded") {
    ScrollView {
        InteractiveHealthFocusPreview(selectedFocus: "gutHealth")
            .padding()
    }
    .background(Color.backgroundPrimary)
}
