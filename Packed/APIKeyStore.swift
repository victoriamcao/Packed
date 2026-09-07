//
//  APIKeyStore.swift
//  Packed
//
//  Stores the user's own Anthropic API key in the Keychain so the smart
//  packing list feature can call the Claude API without shipping a key
//  inside the app binary.
//

import Foundation

enum APIKeyStore {
    private static let service = "com.packed.anthropic"
    private static let account = "apiKey"

    static func load() -> String? {
        KeychainStore.load(service: service, account: account)
    }

    @discardableResult
    static func save(_ key: String) -> Bool {
        KeychainStore.save(key, service: service, account: account)
    }

    @discardableResult
    static func clear() -> Bool {
        KeychainStore.clear(service: service, account: account)
    }
}
