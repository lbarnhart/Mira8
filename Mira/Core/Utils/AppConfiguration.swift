import Foundation

/// Centralized configuration loader for environment-specific secrets and toggles.
struct AppConfiguration {
    static let shared = AppConfiguration()
    private static var hasWarnedMissingUSDAKey = false

    private enum ConfigurationKey: String {
        case instacartClientID = "InstacartClientID"
        case instacartClientSecret = "InstacartClientSecret"
        case instacartRedirectURI = "InstacartRedirectURI"
        case amazonAssociateTag = "AmazonAssociateTag"
        case usdaAPIKey = "USDAAPIKey"
    }

    private let values: [String: Any]
    private init(bundle: Bundle = .main) {
        if let url = bundle.url(forResource: "Configuration", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
           let dictionary = plist as? [String: Any] {
            values = dictionary
        } else {
            values = [:]
#if DEBUG
            AppLog.info("Configuration.plist not found. Falling back to debug defaults where available.", category: .configuration)
#else
            AppLog.warning("Configuration.plist missing. Sensitive configuration values are empty.", category: .configuration)
#endif
        }
    }

    private func string(for key: ConfigurationKey) -> String? {
        guard let rawValue = values[key.rawValue] as? String else { return nil }
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func infoValue(for key: ConfigurationKey) -> String? {
        switch key {
        case .usdaAPIKey:
            if let raw = Bundle.main.object(forInfoDictionaryKey: "USDA_API_KEY") as? String {
                let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }
            return nil
        default:
            return nil
        }
    }

    private func fallbackValue(for key: ConfigurationKey) -> String? {
        #if DEBUG
        switch key {
        case .instacartRedirectURI:
            return Constants.Instacart.defaultRedirectURI
        case .usdaAPIKey:
            return Constants.API.defaultUSDAAPIKey
        case .instacartClientID, .instacartClientSecret, .amazonAssociateTag:
            return nil
        }
        #else
        return nil
        #endif
    }

    private func value(for key: ConfigurationKey) -> String? {
        switch key {
        case .usdaAPIKey:
            return infoValue(for: key) ?? string(for: key) ?? fallbackValue(for: key)
        default:
            return string(for: key) ?? fallbackValue(for: key)
        }
    }

    var instacartClientID: String {
        value(for: .instacartClientID) ?? ""
    }

    var instacartClientSecret: String {
        value(for: .instacartClientSecret) ?? ""
    }

    var instacartRedirectURI: String {
        value(for: .instacartRedirectURI) ?? Constants.Instacart.defaultRedirectURI
    }

    var amazonAssociateTag: String {
        value(for: .amazonAssociateTag) ?? ""
    }

    var usdaAPIKey: String {
        let value = value(for: .usdaAPIKey) ?? Constants.API.defaultUSDAAPIKey
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !Self.hasWarnedMissingUSDAKey {
            Self.hasWarnedMissingUSDAKey = true
            AppLog.warning("USDA API key is not configured. Requests to FoodData Central will fail until a key is provided.", category: .configuration)
        }
        return value
    }
}
