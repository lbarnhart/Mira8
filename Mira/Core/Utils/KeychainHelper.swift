import Foundation
import Security

/// Minimal Keychain helper built on top of the `kSecClassGenericPassword` APIs.
/// Stores opaque blobs (e.g. encoded tokens). Thread-safe through the Security framework.
final class KeychainHelper {
    static let shared = KeychainHelper()

    private init() {}

    private var service: String {
        Bundle.main.bundleIdentifier ?? "com.mira.app"
    }

    func set(_ data: Data, for key: String) throws {
        var query: [String: Any] = baseQuery(for: key)

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
            ]
            let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.unhandled(status: updateStatus)
            }
        case errSecItemNotFound:
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unhandled(status: addStatus)
            }
        default:
            throw KeychainError.unhandled(status: status)
        }
    }

    func data(for key: String) throws -> Data? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            if let data = item as? Data {
                return data
            }
            return nil
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unhandled(status: status)
        }
    }

    func delete(_ key: String) throws {
        let query = baseQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.unhandled(status: status)
        }
    }

    private func baseQuery(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }
}

enum KeychainError: Error, LocalizedError {
    case unhandled(status: OSStatus)

    var errorDescription: String? {
        switch self {
        case .unhandled(let status):
            if let description = SecCopyErrorMessageString(status, nil) as String? {
                return description
            }
            return "Keychain error (status: \(status))"
        }
    }
}
