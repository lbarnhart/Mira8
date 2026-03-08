import Foundation
import Combine

/// Typed tab identifiers to avoid hardcoded index magic numbers.
enum Tab: Int, CaseIterable {
    case scan = 0
    case search = 1
    case insights = 2
    case history = 3
    case shoppingList = 4
    case profile = 5
}

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    private let userDefaults: UserDefaults

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            userDefaults.set(hasCompletedOnboarding, forKey: Constants.UserDefaults.hasCompletedOnboarding)
        }
    }

    @Published var healthFocus: String {
        didSet {
            userDefaults.set(healthFocus, forKey: Constants.UserDefaults.selectedHealthFocus)
        }
    }

    @Published var dietaryRestrictions: Set<String> {
        didSet {
            let sanitized = AppState.sanitizeRestrictions(dietaryRestrictions)
            if sanitized != dietaryRestrictions {
                dietaryRestrictions = sanitized
                return
            }

            let sortedRestrictions = Array(sanitized).sorted()
            userDefaults.set(sortedRestrictions, forKey: Constants.UserDefaults.dietaryRestrictions)
        }
    }

    @Published var selectedTab: Int = 0

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        let savedFocus = userDefaults.string(forKey: Constants.UserDefaults.selectedHealthFocus) ?? ""
        let savedRestrictions = userDefaults.array(forKey: Constants.UserDefaults.dietaryRestrictions) as? [String] ?? []
        let sanitizedRestrictions = AppState.sanitizeRestrictions(Set(savedRestrictions))

        self.hasCompletedOnboarding = userDefaults.bool(forKey: Constants.UserDefaults.hasCompletedOnboarding)
        self.healthFocus = savedFocus
        self.dietaryRestrictions = sanitizedRestrictions
    }

    func updateOnboardingStatus(healthFocus: String, restrictions: Set<String>, completed: Bool) {
        hasCompletedOnboarding = completed
        self.healthFocus = healthFocus
        self.dietaryRestrictions = restrictions
    }

    private static func sanitizeRestrictions(_ restrictions: Set<String>) -> Set<String> {
        restrictions.compactMap { identifier in
            let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalized = trimmed.lowercased()

            guard !normalized.isEmpty, normalized != "none" else {
                return nil
            }

            return trimmed
        }
        .reduce(into: Set<String>()) { result, value in
            result.insert(value)
        }
    }
}
