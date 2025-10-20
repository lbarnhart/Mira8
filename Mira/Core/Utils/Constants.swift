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

    struct Amazon {
        /// Register for the Amazon Associates program and provide your tracking ID here using Configuration.plist.
        static var associateID: String { AppConfiguration.shared.amazonAssociateTag }
        static let baseURL = "https://www.amazon.com"
        static let searchPath = "/s"
        static let searchQueryKey = "k"
        static let affiliateTagKey = "tag"
        static let trackingParameters: [URLQueryItem] = [
            URLQueryItem(name: "linkCode", value: "osi1"),
            URLQueryItem(name: "language", value: "en_US"),
            URLQueryItem(name: "ref", value: "as_li_ss_tl")
        ]
    }

    struct Instacart {
        static let defaultRedirectURI = "mira8://instacart-callback"
        /// Generate credentials from the Instacart Connect dashboard and supply them via Configuration.plist.
        static var clientID: String { AppConfiguration.shared.instacartClientID }
        static var clientSecret: String { AppConfiguration.shared.instacartClientSecret }
        static var redirectURI: String { AppConfiguration.shared.instacartRedirectURI }
        static let apiBaseURL = "https://connect.instacart.com/v1"
        static let authorizationURL = "https://connect.instacart.com/oauth2/authorize"
        static let tokenURL = "https://connect.instacart.com/oauth2/token"
    }

    struct UserDefaults {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let selectedHealthFocus = "selectedHealthFocus"
        static let dietaryRestrictions = "dietaryRestrictions"
        static let lastSyncDate = "lastSyncDate"
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
