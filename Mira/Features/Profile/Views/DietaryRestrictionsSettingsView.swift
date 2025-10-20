import SwiftUI

struct DietaryRestrictionsSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedRestrictions: Set<String> = []
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let coreDataManager = CoreDataManager.shared

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                DietaryRestrictionsView(
                    selectedRestrictions: $selectedRestrictions,
                    onToggle: toggleRestriction,
                    onSkip: {
                        selectedRestrictions.removeAll()
                    }
                )
            }

            PrimaryButton(
                "Save",
                isFullWidth: true,
                isEnabled: !isSaving,
                isLoading: isSaving
            ) {
                save()
            }
            .padding(Spacing.screenPadding)
        }
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") {
                    dismiss()
                }
            }
        }
        .onAppear {
            selectedRestrictions = appState.dietaryRestrictions
        }
        .alert("Unable to save", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func toggleRestriction(_ restriction: String) {
        if restriction == "none" {
            selectedRestrictions.removeAll()
            return
        }

        if selectedRestrictions.contains(restriction) {
            selectedRestrictions.remove(restriction)
        } else {
            selectedRestrictions.insert(restriction)
        }
    }

    private func save() {
        isSaving = true

        Task {
            do {
                try coreDataManager.saveUserProfile(
                    healthFocus: appState.healthFocus,
                    dietaryRestrictions: Array(selectedRestrictions)
                )

                await MainActor.run {
                    appState.updateOnboardingStatus(
                        healthFocus: appState.healthFocus,
                        restrictions: selectedRestrictions,
                        completed: true
                    )
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    let appState = AppState()
    appState.updateOnboardingStatus(healthFocus: "gutHealth", restrictions: ["vegan"], completed: true)
    return NavigationStack {
        DietaryRestrictionsSettingsView()
            .environmentObject(appState)
    }
}
