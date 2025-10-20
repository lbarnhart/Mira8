import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var selectedHealthFocus: String?
    @Published var selectedRestrictions: Set<String> = []
    @Published var showErrorAlert = false
    @Published var errorMessage: String?

    private let coreDataManager: CoreDataManager
    private let userDefaults: UserDefaults

    init(
        coreDataManager: CoreDataManager = .shared,
        userDefaults: UserDefaults = .standard
    ) {
        self.coreDataManager = coreDataManager
        self.userDefaults = userDefaults

        if userDefaults.bool(forKey: Constants.UserDefaults.hasCompletedOnboarding) {
            selectedHealthFocus = userDefaults.string(forKey: Constants.UserDefaults.selectedHealthFocus)
            if let storedRestrictions = userDefaults.array(forKey: Constants.UserDefaults.dietaryRestrictions) as? [String] {
                selectedRestrictions = Set(storedRestrictions)
            }
        }
    }

    func selectHealthFocus(_ focus: String) {
        selectedHealthFocus = focus
    }

    func toggleRestriction(_ restriction: String) {
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

    func skipRestrictions() {
        selectedRestrictions.removeAll()
    }

    func completeOnboarding(appState: AppState) {
        let focus = selectedHealthFocus ?? "generalWellness"
        let restrictions = selectedRestrictions

        do {
            try coreDataManager.saveUserProfile(healthFocus: focus, dietaryRestrictions: Array(restrictions))
            userDefaults.set(true, forKey: Constants.UserDefaults.hasCompletedOnboarding)
            userDefaults.set(focus, forKey: Constants.UserDefaults.selectedHealthFocus)
            userDefaults.set(Array(restrictions), forKey: Constants.UserDefaults.dietaryRestrictions)

            appState.updateOnboardingStatus(healthFocus: focus, restrictions: restrictions, completed: true)
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    func skipOnboarding(appState: AppState) {
        selectedHealthFocus = selectedHealthFocus ?? "generalWellness"
        selectedRestrictions.removeAll()
        completeOnboarding(appState: appState)
    }
}
