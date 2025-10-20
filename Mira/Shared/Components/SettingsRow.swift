import SwiftUI

// MARK: - Settings Row Component
struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let accessoryType: SettingsAccessoryType
    let action: (() -> Void)?

    init(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        accessoryType: SettingsAccessoryType = .chevron,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.accessoryType = accessoryType
        self.action = action
    }

    var body: some View {
        Button(action: action ?? {}) {
            HStack(spacing: Spacing.md) {
                iconView

                contentView

                Spacer()

                accessoryView
            }
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: Size.iconContainerMD, height: Size.iconContainerMD)

            Image(systemName: icon)
                .font(.system(size: Size.iconSM, weight: .medium))
                .foregroundColor(iconColor)
        }
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .bodyMediumStyle()
                .foregroundColor(.textPrimary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .captionMediumStyle()
                    .foregroundColor(.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var accessoryView: some View {
        switch accessoryType {
        case .chevron:
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.textTertiary)

        case .toggle(let isOn, let action):
            Toggle("", isOn: Binding(
                get: { isOn },
                set: { _ in action() }
            ))
            .labelsHidden()

        case .badge(let text, let color):
            Text(text)
                .captionSmallStyle()
                .foregroundColor(.textOnDark)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(color)
                .cornerRadius(CornerRadius.pill)

        case .value(let text):
            Text(text)
                .captionMediumStyle()
                .foregroundColor(.textTertiary)

        case .none:
            EmptyView()
        }
    }
}

// MARK: - Settings Accessory Type
enum SettingsAccessoryType {
    case chevron
    case toggle(isOn: Bool, action: () -> Void)
    case badge(text: String, color: Color)
    case value(text: String)
    case none
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String?
    let footer: String?
    let content: () -> Content

    init(
        title: String? = nil,
        footer: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.footer = footer
        self.content = content
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            if let title = title {
                SectionHeader(title: title)
            }

            VStack(spacing: Spacing.sm) {
                content()
            }
            .standardCard()

            if let footer = footer {
                SectionFooter(text: footer)
            }
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .headlineSmallStyle()
                .foregroundColor(.textPrimary)

            Spacer()
        }
    }
}

// MARK: - Section Footer
struct SectionFooter: View {
    let text: String

    var body: some View {
        HStack {
            Text(text)
                .captionMediumStyle()
                .foregroundColor(.textTertiary)

            Spacer()
        }
        .padding(.horizontal, Spacing.sm)
    }
}

// MARK: - Destructive Settings Row
struct DestructiveSettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let action: () -> Void

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }

    var body: some View {
        SettingsRow(
            icon: icon,
            iconColor: .error,
            title: title,
            subtitle: subtitle,
            accessoryType: .chevron,
            action: action
        )
    }
}

// MARK: - Settings Row with Disclosure
struct DisclosureSettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let action: () -> Void

    init(
        icon: String,
        iconColor: Color,
        title: String,
        value: String,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.value = value
        self.action = action
    }

    var body: some View {
        SettingsRow(
            icon: icon,
            iconColor: iconColor,
            title: title,
            accessoryType: .value(text: value),
            action: action
        )
    }
}

// MARK: - Toggle Settings Row
struct ToggleSettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool

    init(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        isOn: Binding<Bool>
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }

    var body: some View {
        SettingsRow(
            icon: icon,
            iconColor: iconColor,
            title: title,
            subtitle: subtitle,
            accessoryType: .toggle(isOn: isOn) {
                isOn.toggle()
            }
        )
    }
}

// MARK: - Preview
private struct SettingsRowPreview: View {
    @State private var previewDarkMode = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                SettingsSection(title: "Preferences") {
                    SettingsRow(
                        icon: "bell.fill",
                        iconColor: .warning,
                        title: "Notifications",
                        subtitle: "Scan reminders, health tips"
                    ) {
                        #if DEBUG
                        print("Notifications tapped")
                        #endif
                    }

                    ToggleSettingsRow(
                        icon: "moon.fill",
                        iconColor: .primary,
                        title: "Dark Mode",
                        isOn: $previewDarkMode
                    )

                    DisclosureSettingsRow(
                        icon: "textformat.size",
                        iconColor: .oceanTeal,
                        title: "Text Size",
                        value: "Medium"
                    ) {
                        #if DEBUG
                        print("Text size tapped")
                        #endif
                    }
                }

                SettingsSection(
                    title: "Danger Zone",
                    footer: "This action cannot be undone."
                ) {
                    DestructiveSettingsRow(
                        icon: "trash.fill",
                        title: "Clear All Data",
                        subtitle: "Remove all scanned products"
                    ) {
                        #if DEBUG
                        print("Clear data tapped")
                        #endif
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    SettingsRowPreview()
}
