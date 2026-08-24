// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import Security

protocol APIKeyStoring {
    func key(for provider: AIProvider) throws -> String?
    func save(_ key: String, for provider: AIProvider) throws
    func deleteKey(for provider: AIProvider) throws
}

struct APIKeyStore: APIKeyStoring {
    static let shared = APIKeyStore()

    private let service: String

    init(service: String = "com.karlperron.contextbrowser.ai-api-keys") {
        self.service = service
    }

    func key(for provider: AIProvider) throws -> String? {
        var query = baseQuery(for: provider)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            throw APIKeyStoreError.keychain(status)
        }
        return key
    }

    func save(_ key: String, for provider: AIProvider) throws {
        let cleaned = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, let data = cleaned.data(using: .utf8) else {
            throw APIKeyStoreError.emptyKey
        }

        var newItem = baseQuery(for: provider)
        newItem[kSecValueData as String] = data
        newItem[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let addStatus = SecItemAdd(newItem as CFDictionary, nil)
        if addStatus == errSecDuplicateItem {
            let changes: [String: Any] = [
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]
            let updateStatus = SecItemUpdate(
                baseQuery(for: provider) as CFDictionary,
                changes as CFDictionary
            )
            guard updateStatus == errSecSuccess else {
                throw APIKeyStoreError.keychain(updateStatus)
            }
            return
        }
        guard addStatus == errSecSuccess else {
            throw APIKeyStoreError.keychain(addStatus)
        }
    }

    func deleteKey(for provider: AIProvider) throws {
        let status = SecItemDelete(baseQuery(for: provider) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw APIKeyStoreError.keychain(status)
        }
    }

    private func baseQuery(for provider: AIProvider) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue
        ]
    }
}

enum APIKeyStoreError: LocalizedError, Equatable {
    case emptyKey
    case keychain(OSStatus)

    var errorDescription: String? {
        switch self {
        case .emptyKey:
            "Paste an API key before saving."
        case .keychain:
            "Context could not access the protected API key in Keychain."
        }
    }
}
