import SwiftUI

// MARK: - Modern Primary Button Component
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    let style: MiraButtonStyle
    let size: ButtonSize
    let isFullWidth: Bool
    let isEnabled: Bool
    let isLoading: Bool
    let icon: String?

    init(
        _ title: String,
        style: MiraButtonStyle = .primary,
        size: ButtonSize = .medium,
        isFullWidth: Bool = false,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.isFullWidth = isFullWidth
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                // Loading indicator
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                }
                // Icon
                else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize, weight: .medium))
                }

                // Title
                if !isLoading || !title.isEmpty {
                    Text(title)
                        .font(size.font)
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(effectiveForegroundColor)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(effectiveBackgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.button)
                    .stroke(effectiveBorderColor, lineWidth: style.borderWidth)
            )
            .cornerRadius(CornerRadius.button)
            .shadow(
                color: shouldShowShadow ? .cardShadow : .clear,
                radius: 4,
                x: 0,
                y: 2
            )
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.6)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }

    private var effectiveBackgroundColor: Color {
        if !isEnabled {
            return .buttonSecondary
        }
        return style.backgroundColor
    }

    private var effectiveForegroundColor: Color {
        if !isEnabled {
            return .textTertiary
        }
        return style.foregroundColor
    }

    private var effectiveBorderColor: Color {
        if !isEnabled {
            return .clear
        }
        return style.borderColor
    }

    private var shouldShowShadow: Bool {
        isEnabled && (style == .primary || style == .destructive)
    }
}

// MARK: - Icon Button Component
struct IconButton: View {
    let icon: String
    let action: () -> Void
    let style: MiraButtonStyle
    let size: ButtonSize
    let isEnabled: Bool

    init(
        icon: String,
        style: MiraButtonStyle = .ghost,
        size: ButtonSize = .medium,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.style = style
        self.size = size
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size.iconSize, weight: .medium))
                .foregroundColor(isEnabled ? style.foregroundColor : .textTertiary)
                .frame(width: size.height, height: size.height)
                .background(isEnabled ? style.backgroundColor : .buttonSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.button)
                        .stroke(
                            isEnabled ? style.borderColor : .clear,
                            lineWidth: style.borderWidth
                        )
                )
                .cornerRadius(CornerRadius.button)
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    let size: CGFloat
    let isEnabled: Bool

    init(
        icon: String,
        size: CGFloat = 56,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundColor(.textOnDark)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(isEnabled ? .primaryGradient : LinearGradient(gradient: Gradient(colors: [.buttonSecondary]), startPoint: .top, endPoint: .bottom))
                )
                .shadow(
                    color: isEnabled ? .cardShadow : .clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
        .disabled(!isEnabled)
        .scaleEffect(isEnabled ? 1.0 : 0.9)
        .opacity(isEnabled ? 1.0 : 0.6)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

// MARK: - Button Group Component
struct ButtonGroup: View {
    let buttons: [ButtonGroupItem]
    let axis: Axis
    let spacing: CGFloat

    init(
        buttons: [ButtonGroupItem],
        axis: Axis = .horizontal,
        spacing: CGFloat = Spacing.sm
    ) {
        self.buttons = buttons
        self.axis = axis
        self.spacing = spacing
    }

    var body: some View {
        if axis == .horizontal {
            HStack(spacing: spacing) {
                buttonContent
            }
        } else {
            VStack(spacing: spacing) {
                buttonContent
            }
        }
    }

    @ViewBuilder
    private var buttonContent: some View {
        ForEach(Array(buttons.enumerated()), id: \.offset) { index, button in
            PrimaryButton(
                button.title,
                style: button.style,
                size: button.size,
                isFullWidth: axis == .vertical,
                isEnabled: button.isEnabled,
                icon: button.icon,
                action: button.action
            )
        }
    }
}

struct ButtonGroupItem {
    let title: String
    let style: MiraButtonStyle
    let size: ButtonSize
    let isEnabled: Bool
    let icon: String?
    let action: () -> Void

    init(
        title: String,
        style: MiraButtonStyle = .secondary,
        size: ButtonSize = .medium,
        isEnabled: Bool = true,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.isEnabled = isEnabled
        self.icon = icon
        self.action = action
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: Spacing.xxl) {
            // Button Styles
            Text("Button Styles")
                .headlineMediumStyle()

            VStack(spacing: Spacing.md) {
                PrimaryButton("Primary Button", style: .primary) {}
                PrimaryButton("Secondary Button", style: .secondary) {}
                PrimaryButton("Outline Button", style: .outline) {}
                PrimaryButton("Ghost Button", style: .ghost) {}
                PrimaryButton("Destructive Button", style: .destructive) {}
            }

            // Button Sizes
            Text("Button Sizes")
                .headlineMediumStyle()

            VStack(spacing: Spacing.md) {
                PrimaryButton("Small Button", size: .small) {}
                PrimaryButton("Medium Button", size: .medium) {}
                PrimaryButton("Large Button", size: .large) {}
            }

            // Buttons with Icons
            Text("Buttons with Icons")
                .headlineMediumStyle()

            VStack(spacing: Spacing.md) {
                PrimaryButton("Scan Product", icon: "barcode.viewfinder") {}
                PrimaryButton("Loading...", style: .secondary, isLoading: true) {}
                PrimaryButton("Save Changes", style: .primary, icon: "checkmark") {}
            }

            // Icon Buttons
            Text("Icon Buttons")
                .headlineMediumStyle()

            HStack(spacing: Spacing.md) {
                IconButton(icon: "heart", style: .ghost) {}
                IconButton(icon: "share", style: .secondary) {}
                IconButton(icon: "bookmark", style: .outline) {}
                IconButton(icon: "trash", style: .destructive) {}
            }

            // Floating Action Button
            Text("Floating Action Button")
                .headlineMediumStyle()

            FloatingActionButton(icon: "plus") {}

            // Button Groups
            Text("Button Groups")
                .headlineMediumStyle()

            ButtonGroup(buttons: [
                ButtonGroupItem(title: "Cancel", style: .ghost) {},
                ButtonGroupItem(title: "Save", style: .primary) {}
            ])

            ButtonGroup(
                buttons: [
                    ButtonGroupItem(title: "Option 1", style: .outline) {},
                    ButtonGroupItem(title: "Option 2", style: .outline) {},
                    ButtonGroupItem(title: "Option 3", style: .primary) {}
                ],
                axis: .vertical
            )
        }
        .padding()
    }
}