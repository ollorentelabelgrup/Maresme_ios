import Foundation
import Security

enum KeychainError: Error {
    case saveFailed(OSStatus)
    case deleteFailed(OSStatus)
    case unknown
}

enum KeychainService {
    // MARK: - Token

    nonisolated static func saveToken(_ token: String) throws {
        let data = Data(token.utf8)
        try save(data: data, account: Config.Keychain.tokenAccount)
    }

    nonisolated static func getToken() -> String? {
        guard let data = read(account: Config.Keychain.tokenAccount) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    nonisolated static func deleteToken() throws {
        try delete(account: Config.Keychain.tokenAccount)
    }

    nonisolated static func hasToken() -> Bool {
        getToken() != nil
    }

    // MARK: - Private primitives
    // All marked nonisolated so they can be called from nonisolated public methods
    // without crossing into @MainActor (which is the default isolation for this project).

    private nonisolated static func save(data: Data, account: String) throws {
        let query: [CFString: Any] = [
            kSecClass:          kSecClassGenericPassword,
            kSecAttrService:    Config.Keychain.service,
            kSecAttrAccount:    account,
            kSecValueData:      data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.saveFailed(status) }
    }

    private nonisolated static func read(account: String) -> Data? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: Config.Keychain.service,
            kSecAttrAccount: account,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    private nonisolated static func delete(account: String) throws {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: Config.Keychain.service,
            kSecAttrAccount: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}
