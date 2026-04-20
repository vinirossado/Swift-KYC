import Foundation
import IdentityKitCore

/// Secure storage for session tokens using the iOS Keychain.
///
/// Uses `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` so tokens
/// are available after first unlock but not backed up or migrated
/// to other devices — appropriate for transient verification sessions.
public final class KeychainStore: Sendable {

    private let service: String

    public init(service: String = "com.identitykit.sdk") {
        self.service = service
    }

    /// Saves a value for the given key.
    @discardableResult
    public func save(key: String, data: Data) -> Bool {
        // Delete any existing item first to avoid errSecDuplicateItem.
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Saves a string value for the given key.
    @discardableResult
    public func save(key: String, string: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return save(key: key, data: data)
    }

    /// Reads data for the given key.
    public func read(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    /// Reads a string value for the given key.
    public func readString(key: String) -> String? {
        guard let data = read(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Deletes the value for the given key.
    @discardableResult
    public func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// Deletes all items for this service.
    @discardableResult
    public func deleteAll() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
