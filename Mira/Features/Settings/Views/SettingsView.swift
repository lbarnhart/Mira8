import SwiftUI

struct SettingsView: View {
    @AppStorage("selectedHealthFocus") private var selectedHealthFocusIdentifier: String = "generalWellness"
    @AppStorage("dietaryRestrictions") private var dietaryRestrictionsData: Data = Data()
    @State private var dietaryRestrictions: Set<DietaryRestriction> = []
    @State private var showingHealthProfile = false
    @State private var showingDietaryRestrictions = false
    @State private var showingAbout = false
    @State private var showingMore = false

    private var selectedHealthFocus: HealthFocus {
        get { HealthFocus(fromStored: selectedHealthFocusIdentifier) }
        set { selectedHealthFocusIdentifier = newValue.rawValue }
    }

    private var selectedHealthFocusBinding: Binding<HealthFocus> {
        Binding(
            get: { selectedHealthFocus },
            set: { selectedHealthFocusIdentifier = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Profile Section
                    profileSection

                    // More Section - links to additional settings
                    moreSection
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadDietaryRestrictions()
            }
        }
        .sheet(isPresented: $showingHealthProfile) {
            HealthProfileSheet(selectedFocus: selectedHealthFocusBinding)
        }
        .sheet(isPresented: $showingDietaryRestrictions) {
            DietaryRestrictionsSheet(restrictions: $dietaryRestrictions) {
                saveDietaryRestrictions()
            }
        }
        .sheet(isPresented: $showingMore) {
            MoreSettingsSheet(showingAbout: $showingAbout)
        }
        .sheet(isPresented: $showingAbout) {
            AboutSheet()
        }
    }

    private var moreSection: some View {
        SettingsSection(title: "More") {
            SettingsRow(
                icon: "ellipsis.circle.fill",
                iconColor: .textSecondary,
                title: "More Settings",
                subtitle: "Preferences, Privacy, Support",
                action: { showingMore = true }
            )
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

            SettingsRow(
                icon: "leaf.fill",
                iconColor: .success,
                title: "Dietary Restrictions",
                subtitle: dietaryRestrictionsSubtitle,
                action: { showingDietaryRestrictions = true }
            )
        }
    }

    private var preferencesSection: some View {
        SettingsSection(title: "Preferences") {
            SettingsRow(
                icon: "bell.fill",
                iconColor: .warning,
                title: "Notifications",
                subtitle: "Scan reminders, health tips",
                action: {
                    // TODO: Implement notifications settings
                }
            )

            SettingsRow(
                icon: "moon.fill",
                iconColor: .primary,
                title: "Dark Mode",
                subtitle: "Automatic",
                action: {
                    // TODO: Implement dark mode settings
                }
            )

            SettingsRow(
                icon: "textformat.size",
                iconColor: .oceanTeal,
                title: "Text Size",
                subtitle: "Medium",
                action: {
                    // TODO: Implement text size settings
                }
            )
        }
    }

    private var dataPrivacySection: some View {
        SettingsSection(title: "Data & Privacy") {
            SettingsRow(
                icon: "icloud.fill",
                iconColor: .info,
                title: "Sync Data",
                subtitle: "iCloud enabled",
                action: {
                    // TODO: Implement iCloud sync settings
                }
            )

            DestructiveSettingsRow(
                icon: "trash.fill",
                title: "Clear History",
                subtitle: "Remove all scanned products"
            ) {
                // TODO: Implement clear history with confirmation
            }

            SettingsRow(
                icon: "doc.text.fill",
                iconColor: .textSecondary,
                title: "Privacy Policy",
                subtitle: "How we protect your data",
                action: {
                    // TODO: Open privacy policy URL
                }
            )
        }
    }

    private var supportSection: some View {
        SettingsSection(title: "Support") {
            SettingsRow(
                icon: "questionmark.circle.fill",
                iconColor: .info,
                title: "Help Center",
                subtitle: "FAQ and guides",
                action: {
                    // TODO: Open help center URL
                }
            )

            SettingsRow(
                icon: "envelope.fill",
                iconColor: .oceanTeal,
                title: "Contact Us",
                subtitle: "Get support",
                action: {
                    // TODO: Open contact/support email
                }
            )

            SettingsRow(
                icon: "star.fill",
                iconColor: .warning,
                title: "Rate App",
                subtitle: "Share your feedback",
                action: {
                    // TODO: Open App Store rating
                }
            )
        }
    }

    private var appInfoSection: some View {
        SettingsSection(title: "App Info") {
            SettingsRow(
                icon: "info.circle.fill",
                iconColor: .textSecondary,
                title: "About Mira",
                subtitle: "Version 1.0.0",
                action: { showingAbout = true }
            )

            SettingsRow(
                icon: "doc.fill",
                iconColor: .textSecondary,
                title: "Terms of Service",
                subtitle: "Legal information",
                action: {
                    // TODO: Open terms of service URL
                }
            )
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


    private func loadDietaryRestrictions() {
        if let decoded = try? JSONDecoder().decode(Set<DietaryRestriction>.self, from: dietaryRestrictionsData) {
            dietaryRestrictions = decoded
        }
    }

    private func saveDietaryRestrictions() {
        if let encoded = try? JSONEncoder().encode(dietaryRestrictions) {
            dietaryRestrictionsData = encoded
        }
    }
}

// MARK: - Sheet Views
struct HealthProfileSheet: View {
    @Binding var selectedFocus: HealthFocus
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Header with close button
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

                                // Active icon in place of description
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

struct MoreSettingsSheet: View {
    @Binding var showingAbout: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Preferences Section
                    preferencesSection

                    // Data & Privacy Section
                    dataPrivacySection

                    // Support Section
                    supportSection

                    // App Info
                    appInfoSection
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var preferencesSection: some View {
        SettingsSection(title: "Preferences") {
            SettingsRow(
                icon: "bell.fill",
                iconColor: .warning,
                title: "Notifications",
                subtitle: "Scan reminders, health tips",
                action: {
                    // TODO: Implement notifications settings
                }
            )

            SettingsRow(
                icon: "moon.fill",
                iconColor: .primary,
                title: "Dark Mode",
                subtitle: "Automatic",
                action: {
                    // TODO: Implement dark mode settings
                }
            )

            SettingsRow(
                icon: "textformat.size",
                iconColor: .oceanTeal,
                title: "Text Size",
                subtitle: "Medium",
                action: {
                    // TODO: Implement text size settings
                }
            )
        }
    }

    private var dataPrivacySection: some View {
        SettingsSection(title: "Data & Privacy") {
            SettingsRow(
                icon: "icloud.fill",
                iconColor: .info,
                title: "Sync Data",
                subtitle: "iCloud enabled",
                action: {
                    // TODO: Implement iCloud sync settings
                }
            )

            DestructiveSettingsRow(
                icon: "trash.fill",
                title: "Clear History",
                subtitle: "Remove all scanned products"
            ) {
                // TODO: Implement clear history with confirmation
            }

            SettingsRow(
                icon: "doc.text.fill",
                iconColor: .textSecondary,
                title: "Privacy Policy",
                subtitle: "How we protect your data",
                action: {
                    // TODO: Open privacy policy URL
                }
            )
        }
    }

    private var supportSection: some View {
        SettingsSection(title: "Support") {
            SettingsRow(
                icon: "questionmark.circle.fill",
                iconColor: .info,
                title: "Help Center",
                subtitle: "FAQ and guides",
                action: {
                    // TODO: Open help center URL
                }
            )

            SettingsRow(
                icon: "envelope.fill",
                iconColor: .oceanTeal,
                title: "Contact Us",
                subtitle: "Get support",
                action: {
                    // TODO: Open contact/support email
                }
            )

            SettingsRow(
                icon: "star.fill",
                iconColor: .warning,
                title: "Rate App",
                subtitle: "Share your feedback",
                action: {
                    // TODO: Open App Store rating
                }
            )
        }
    }

    private var appInfoSection: some View {
        SettingsSection(title: "App Info") {
            SettingsRow(
                icon: "info.circle.fill",
                iconColor: .textSecondary,
                title: "About Mira",
                subtitle: "Version 1.0.0",
                action: {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingAbout = true
                    }
                }
            )

            SettingsRow(
                icon: "doc.fill",
                iconColor: .textSecondary,
                title: "Terms of Service",
                subtitle: "Legal information",
                action: {
                    // TODO: Open terms of service URL
                }
            )
        }
    }
}

struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // App Icon and Name
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

                        Text("Version 1.0.0")
                            .captionMediumStyle()
                            .foregroundColor(.textTertiary)
                    }
                    .padding(.top, Spacing.xl)

                    // Description
                    VStack(spacing: Spacing.md) {
                        Text("About Mira")
                            .headlineSmallStyle()
                            .foregroundColor(.textPrimary)

                        Text("Mira helps you make informed food choices by analyzing nutritional content, ingredients, and processing levels. Get personalized health scores and discover better alternatives.")
                            .bodyMediumStyle()
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    // Credits
                    VStack(spacing: Spacing.sm) {
                        Text("Powered by")
                            .captionMediumStyle()
                            .foregroundColor(.textTertiary)

                        Text("USDA FoodData Central\nOpen Food Facts")
                            .captionMediumStyle()
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
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
}

#Preview {
    SettingsView()
}
