import Foundation

/// Centralized configuration loader for environment-specific secrets and toggles.
struct AppConfiguration {
    static let shared = AppConfiguration()

    private enum ConfigurationKey: String {
        case usdaAPIKey = "USDAAPIKey"
        case claudeAPIKey = "ClaudeAPIKey"
        case privacyPolicyURL = "PrivacyPolicyURL"
        case termsOfServiceURL = "TermsOfServiceURL"
        case helpCenterURL = "HelpCenterURL"
        case supportEmail = "SupportEmail"
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

    private func url(for key: ConfigurationKey) -> URL? {
        guard let value = string(for: key) else { return nil }
        return URL(string: value)
    }

    private func fallbackValue(for key: ConfigurationKey) -> String? {
        #if DEBUG
        switch key {
        case .usdaAPIKey:
            return Constants.API.defaultUSDAAPIKey
        case .claudeAPIKey:
            return nil
        case .privacyPolicyURL,
             .termsOfServiceURL,
             .helpCenterURL,
             .supportEmail:
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

    var usdaAPIKey: String {
        value(for: .usdaAPIKey) ?? Constants.API.defaultUSDAAPIKey
    }

    var claudeAPIKey: String {
        #if !DEBUG
        // Provider API keys must never be distributed in an App Store binary.
        return ""
        #else
        return value(for: .claudeAPIKey) ?? ""
        #endif
    }

    var privacyPolicyURL: URL? {
        url(for: .privacyPolicyURL)
    }

    var termsOfServiceURL: URL? {
        url(for: .termsOfServiceURL)
    }

    var helpCenterURL: URL? {
        url(for: .helpCenterURL)
    }

    var supportEmailAddress: String? {
        string(for: .supportEmail)
    }

    var supportEmailURL: URL? {
        guard let email = supportEmailAddress else { return nil }
        return URL(string: "mailto:\(email)")
    }
}
