import Foundation
import CoreGraphics

struct Constants {
    struct API {
        static let usdaBaseURL = "https://api.nal.usda.gov"
        /// Fallback used only when a key is not supplied in configuration (requests will fail without a real key).
        static let defaultUSDAAPIKey = ""
        static var usdaAPIKey: String { AppConfiguration.shared.usdaAPIKey }
        static let openFoodFactsBaseURL = "https://world.openfoodfacts.org"
        static let requestTimeout: TimeInterval = 10.0
    }

    struct Claude {
        static let baseURL = "https://api.anthropic.com"
        static let messagesPath = "/v1/messages"
        static let apiVersion = "2023-06-01"
        static var apiKey: String { AppConfiguration.shared.claudeAPIKey }
        static let defaultModel = "claude-3-haiku-20240307"
        static let sonnetModel = "claude-sonnet-4-20250514"
        static let requestTimeout: TimeInterval = 30.0
        static let maxTokensDefault = 1024
    }

    struct UserDefaults {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let selectedHealthFocus = "selectedHealthFocus"
        static let dietaryRestrictions = "dietaryRestrictions"
        static let lastSyncDate = "lastSyncDate"
        static let shoppingListItems = "shopping_list_items"
        static let hasSeenFirstScanEducation = "hasSeenFirstScanEducation"
        static let hasSeenBalanceBanner = "hasSeenBalanceBanner"
    }

    struct CoreData {
        static let modelName = "Mira8"
        static let containerName = "Mira8"
    }

    struct UI {
        static let cornerRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 8
        static let animationDuration: Double = 0.3
        static let maxImageCacheSize = 100
    }

    struct Scoring {
        static let maxScore: Double = 100
        static let minScore: Double = 0
        static let excellentThreshold: Double = 80
        static let goodThreshold: Double = 60
        static let fairThreshold: Double = 40
    }
}
