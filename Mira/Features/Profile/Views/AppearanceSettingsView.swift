import SwiftUI

/// User preference for app color scheme
enum AppColorScheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// User preference for text size
enum AppTextSize: String, CaseIterable, Identifiable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    case extraLarge = "Extra Large"
    
    var id: String { rawValue }
    
    var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .extraLarge: return .xLarge
        }
    }
}

struct AppearanceSettingsView: View {
    @AppStorage("appColorScheme") private var colorScheme: AppColorScheme = .system
    @AppStorage("appTextSize") private var textSize: AppTextSize = .medium
    
    var body: some View {
        List {
            // MARK: - Color Scheme Section
            Section {
                ForEach(AppColorScheme.allCases) { scheme in
                    Button {
                        colorScheme = scheme
                    } label: {
                        HStack {
                            Label {
                                Text(scheme.rawValue)
                                    .foregroundColor(.textPrimary)
                            } icon: {
                                Image(systemName: iconName(for: scheme))
                                    .foregroundColor(.primaryBlue)
                            }
                            
                            Spacer()
                            
                            if colorScheme == scheme {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.primaryBlue)
                                    .font(.body.weight(.semibold))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Appearance")
            } footer: {
                Text("Choose how Mira looks. System uses your device's appearance setting.")
            }
            
            // MARK: - Text Size Section
            Section {
                ForEach(AppTextSize.allCases) { size in
                    Button {
                        textSize = size
                    } label: {
                        HStack {
                            Text(size.rawValue)
                                .foregroundColor(.textPrimary)
                                .font(previewFont(for: size))
                            
                            Spacer()
                            
                            if textSize == size {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.primaryBlue)
                                    .font(.body.weight(.semibold))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Text Size")
            } footer: {
                Text("Adjust the text size throughout the app for better readability.")
            }
            
            // MARK: - Preview Section
            Section {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Preview")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    
                    Text("This is how text will appear in the app with your current settings.")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                    
                    Text("Product Name")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text("Brand Name")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
                .padding(.vertical, Spacing.sm)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func iconName(for scheme: AppColorScheme) -> String {
        switch scheme {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    private func previewFont(for size: AppTextSize) -> Font {
        switch size {
        case .small: return .caption
        case .medium: return .body
        case .large: return .title3
        case .extraLarge: return .title2
        }
    }
}

#Preview {
    NavigationStack {
        AppearanceSettingsView()
    }
}
