import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var dietaryRestrictions: Set<DietaryRestriction> = []
    @State private var showingHealthProfile = false
    @State private var showingDietaryRestrictions = false
    @State private var showingAbout = false
    @State private var showingClearHistoryConfirmation = false
    @State private var showingClearHistoryError = false
    @State private var clearHistoryErrorMessage = ""

    private var selectedHealthFocus: HealthFocus {
        get { HealthFocus(fromStored: appState.healthFocus) }
        set { appState.healthFocus = newValue.rawValue }
    }

    private var selectedHealthFocusBinding: Binding<HealthFocus> {
        Binding(
            get: { selectedHealthFocus },
            set: { appState.healthFocus = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    profileSection
                    dataSection
                    appInfoSection
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.textTertiary)
                    }
                    .accessibilityIdentifier("settings.close")
                }
            }
            .onAppear {
                loadDietaryRestrictions()
            }
            .accessibilityIdentifier("screen.settings")
        }
        .sheet(isPresented: $showingHealthProfile) {
            HealthProfileSheet(selectedFocus: selectedHealthFocusBinding)
        }
        .sheet(isPresented: $showingDietaryRestrictions) {
            DietaryRestrictionsSheet(restrictions: $dietaryRestrictions) {
                saveDietaryRestrictions()
            }
        }
        .sheet(isPresented: $showingAbout) {
            AboutSheet()
        }
        .alert("Clear Scan History?", isPresented: $showingClearHistoryConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                clearScanHistory()
            }
        } message: {
            Text("This removes your saved scan history from this device. Favorites and shopping list items stay intact.")
        }
        .alert("Unable to Clear History", isPresented: $showingClearHistoryError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(clearHistoryErrorMessage)
        }
    }

    private var profileSection: some View {
        SettingsSection(title: "Health Profile") {
            SettingsRow(
                icon: "heart.fill",
                iconColor: .error,
                title: "Health Focus",
                subtitle: selectedHealthFocus.displayName,
                action: { showingHealthProfile = true }
            )
            .accessibilityIdentifier("settings.healthFocus")

            SettingsRow(
                icon: "leaf.fill",
                iconColor: .success,
                title: "Dietary Restrictions",
                subtitle: dietaryRestrictionsSubtitle,
                action: { showingDietaryRestrictions = true }
            )
            .accessibilityIdentifier("settings.dietaryRestrictions")
        }
    }

    private var dataSection: some View {
        SettingsSection(
            title: "Data",
            footer: "Only working data-management actions are shown in the 1.0 settings surface."
        ) {
            DestructiveSettingsRow(
                icon: "trash.fill",
                title: "Clear Scan History",
                subtitle: "Remove saved scan history from this device"
            ) {
                showingClearHistoryConfirmation = true
            }
            .accessibilityIdentifier("settings.clearHistory")
        }
    }

    private var appInfoSection: some View {
        SettingsSection(
            title: "App Info",
            footer: "Legal and support URLs still need to be finalized before App Store submission."
        ) {
            SettingsRow(
                icon: "info.circle.fill",
                iconColor: .textSecondary,
                title: "About Mira",
                subtitle: appVersionDescription,
                action: { showingAbout = true }
            )
            .accessibilityIdentifier("settings.about")
        }
    }

    private var dietaryRestrictionsSubtitle: String {
        if dietaryRestrictions.isEmpty {
            return "None selected"
        } else if dietaryRestrictions.count == 1 {
            return dietaryRestrictions.first?.displayName ?? "None"
        } else {
            return "\(dietaryRestrictions.count) restrictions"
        }
    }

    private var appVersionDescription: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"

        if shortVersion == buildNumber {
            return "Version \(shortVersion)"
        }

        return "Version \(shortVersion) (\(buildNumber))"
    }

    private func loadDietaryRestrictions() {
        dietaryRestrictions = Set(DietaryRestriction.fromStrings(appState.dietaryRestrictions))
    }

    private func saveDietaryRestrictions() {
        appState.dietaryRestrictions = Set(dietaryRestrictions.map(\.rawValue))
    }

    private func clearScanHistory() {
        do {
            try CoreDataManager.shared.clearScanHistory()
        } catch {
            clearHistoryErrorMessage = error.localizedDescription
            showingClearHistoryError = true
        }
    }
}

struct HealthProfileSheet: View {
    @Binding var selectedFocus: HealthFocus
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Spacing.lg) {
            HStack {
                Text("Health Focus")
                    .headlineMediumStyle()

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.textTertiary)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)

            VStack(spacing: Spacing.md) {
                Text("Choose Your Health Focus")
                    .bodyLargeStyle()
                    .multilineTextAlignment(.center)

                Text("This helps us provide personalized recommendations for your health goals.")
                    .bodyMediumStyle()
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.lg)

            VStack(spacing: Spacing.sm) {
                ForEach(HealthFocus.allCases, id: \.self) { focus in
                    Button {
                        selectedFocus = focus
                    } label: {
                        HStack(spacing: Spacing.md) {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text(focus.displayName)
                                    .bodyMediumStyle()
                                    .foregroundColor(.textPrimary)

                                if selectedFocus == focus {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.oceanTeal)
                                        .font(.system(size: 18, weight: .medium))
                                }
                            }

                            Spacer()
                        }
                        .padding(Spacing.md)
                    }
                    .buttonStyle(.plain)
                    .standardCard()
                }
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()

            PrimaryButton("Save", style: .primary) {
                dismiss()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.lg)
        }
        .background(Color.backgroundPrimary.ignoresSafeArea())
    }
}

struct DietaryRestrictionsSheet: View {
    @Binding var restrictions: Set<DietaryRestriction>
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                VStack(spacing: Spacing.md) {
                    Text("Select Dietary Restrictions")
                        .headlineMediumStyle()
                        .multilineTextAlignment(.center)

                    Text("We'll flag products that don't match your dietary needs.")
                        .bodyMediumStyle()
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Spacing.lg)

                VStack(spacing: Spacing.sm) {
                    ForEach(DietaryRestriction.allCases, id: \.self) { restriction in
                        Button {
                            if restrictions.contains(restriction) {
                                restrictions.remove(restriction)
                            } else {
                                restrictions.insert(restriction)
                            }
                        } label: {
                            HStack(spacing: Spacing.md) {
                                Text(restriction.displayName)
                                    .bodyMediumStyle()
                                    .foregroundColor(.textPrimary)

                                Spacer()

                                if restrictions.contains(restriction) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.oceanTeal)
                                        .font(.system(size: 16, weight: .medium))
                                }
                            }
                            .padding(Spacing.md)
                        }
                        .buttonStyle(.plain)
                        .standardCard()
                    }
                }

                Spacer()

                PrimaryButton("Save") {
                    onSave()
                    dismiss()
                }
                .padding(.horizontal, Spacing.lg)
            }
            .padding(.horizontal, Spacing.lg)
            .navigationTitle("Dietary Restrictions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss
    private let configuration = AppConfiguration.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 80, weight: .light))
                            .foregroundColor(.oceanTeal)

                        Text("Mira")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)

                        Text("Smart Food Scanner")
                            .bodyLargeStyle()
                            .foregroundColor(.textSecondary)

                        Text(appVersionDescription)
                            .captionMediumStyle()
                            .foregroundColor(.textTertiary)
                    }
                    .padding(.top, Spacing.xl)

                    VStack(spacing: Spacing.md) {
                        Text("About Mira")
                            .headlineSmallStyle()
                            .foregroundColor(.textPrimary)

                        Text("Mira helps you make informed food choices by analyzing nutritional content, ingredients, and processing levels. Get personalized health scores and discover better alternatives.")
                            .bodyMediumStyle()
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: Spacing.sm) {
                        Text("Powered by")
                            .captionMediumStyle()
                            .foregroundColor(.textTertiary)

                        Text("USDA FoodData Central\nOpen Food Facts")
                            .captionMediumStyle()
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    if !resourceLinks.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Support & Privacy")
                                .headlineSmallStyle()
                                .foregroundColor(.textPrimary)

                            VStack(spacing: Spacing.sm) {
                                ForEach(resourceLinks) { link in
                                    Link(destination: link.url) {
                                        HStack(spacing: Spacing.md) {
                                            Image(systemName: link.icon)
                                                .foregroundColor(.primaryBlue)
                                                .frame(width: 20)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(link.title)
                                                    .bodyMediumStyle()
                                                    .foregroundColor(.textPrimary)

                                                if let subtitle = link.subtitle {
                                                    Text(subtitle)
                                                        .captionMediumStyle()
                                                        .foregroundColor(.textSecondary)
                                                }
                                            }

                                            Spacer()

                                            Image(systemName: "arrow.up.right")
                                                .font(.caption)
                                                .foregroundColor(.textTertiary)
                                        }
                                        .padding(Spacing.md)
                                        .background(Color.backgroundSecondary)
                                        .cornerRadius(CornerRadius.card)
                                    }
                                }
                            }
                        }
                    }

#if DEBUG
                    if resourceLinks.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Release Setup Needed")
                                .headlineSmallStyle()
                                .foregroundColor(.textPrimary)

                            Text("Add privacy, terms, help, and support contact values to Configuration.plist before App Store submission.")
                                .bodyMediumStyle()
                                .foregroundColor(.textSecondary)
                        }
                        .padding(Spacing.md)
                        .background(Color.backgroundSecondary)
                        .cornerRadius(CornerRadius.card)
                    }
#endif
                }
                .padding(.horizontal, Spacing.lg)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var appVersionDescription: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"

        if shortVersion == buildNumber {
            return "Version \(shortVersion)"
        }

        return "Version \(shortVersion) (\(buildNumber))"
    }

    private var resourceLinks: [AboutResourceLink] {
        [
            AboutResourceLink(
                title: "Privacy Policy",
                subtitle: "Required for App Store distribution",
                icon: "lock.doc",
                url: configuration.privacyPolicyURL
            ),
            AboutResourceLink(
                title: "Terms of Service",
                subtitle: "Review how Mira should be used",
                icon: "doc.text",
                url: configuration.termsOfServiceURL
            ),
            AboutResourceLink(
                title: "Help Center",
                subtitle: "Troubleshooting and FAQs",
                icon: "questionmark.circle",
                url: configuration.helpCenterURL
            ),
            AboutResourceLink(
                title: "Contact Support",
                subtitle: configuration.supportEmailAddress,
                icon: "envelope",
                url: configuration.supportEmailURL
            )
        ]
        .compactMap { $0 }
    }
}

private struct AboutResourceLink: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let icon: String
    let url: URL

    init?(title: String, subtitle: String?, icon: String, url: URL?) {
        guard let url else { return nil }
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.url = url
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
