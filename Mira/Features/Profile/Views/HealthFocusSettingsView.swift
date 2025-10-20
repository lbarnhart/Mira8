import SwiftUI

struct HealthFocusSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFocus: String?
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let coreDataManager = CoreDataManager.shared

    var body: some View {
        VStack(spacing: 0) {
            HealthFocusSelectionView(
                selectedFocus: $selectedFocus,
                onSelection: { focus in
                    selectedFocus = focus
                }
            )

            PrimaryButton(
                "Save",
                isFullWidth: true,
                isEnabled: selectedFocus != nil && !isSaving,
                isLoading: isSaving
            ) {
                save()
            }
            .padding(Spacing.screenPadding)
        }
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let current = appState.healthFocus.isEmpty ? "generalWellness" : appState.healthFocus
            selectedFocus = current
        }
        .alert("Unable to save", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func save() {
        guard let selectedFocus else { return }
        isSaving = true

        Task {
            do {
                try coreDataManager.saveUserProfile(
                    healthFocus: selectedFocus,
                    dietaryRestrictions: Array(appState.dietaryRestrictions)
                )

                await MainActor.run {
                    appState.updateOnboardingStatus(
                        healthFocus: selectedFocus,
                        restrictions: appState.dietaryRestrictions,
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
    appState.updateOnboardingStatus(healthFocus: "gutHealth", restrictions: [], completed: true)
    return NavigationStack {
        HealthFocusSettingsView()
            .environmentObject(appState)
    }
}
