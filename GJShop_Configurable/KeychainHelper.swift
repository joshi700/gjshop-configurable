//
//  KeychainHelper.swift
//  GJShop_Configurable
//

import Foundation
import Security

// Minimal Keychain wrapper for the gateway API password (FR-09.2 / NFR-04).
enum KeychainHelper {
    private static let service = "com.gauravjoshi.GJShop-Configurable"
    private static let account = "apiPassword"

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    static func savePassword(_ password: String) {
        deletePassword()
        guard !password.isEmpty, let data = password.data(using: .utf8) else { return }

        var query = baseQuery
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        SecItemAdd(query as CFDictionary, nil)
    }

    static func loadPassword() -> String {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let password = String(data: data, encoding: .utf8) else {
            return ""
        }
        return password
    }

    static func deletePassword() {
        SecItemDelete(baseQuery as CFDictionary)
    }
}
