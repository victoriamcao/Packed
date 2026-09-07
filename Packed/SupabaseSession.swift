//
//  SupabaseSession.swift
//  Packed
//
//  The logged-in user's auth tokens, persisted in the Keychain so the
//  session survives app relaunches.
//

import Foundation

struct SupabaseSession: Codable {
    let accessToken: String
    let refreshToken: String
    let userId: String
    let email: String
    let expiresAt: Date
}

enum SupabaseSessionStore {
    private static let service = "com.packed.supabase"
    private static let account = "session"

    static func load() -> SupabaseSession? {
        guard let json = KeychainStore.load(service: service, account: account),
              let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(SupabaseSession.self, from: data)
    }

    static func save(_ session: SupabaseSession) {
        guard let data = try? JSONEncoder().encode(session),
              let json = String(data: data, encoding: .utf8) else { return }
        KeychainStore.save(json, service: service, account: account)
    }

    static func clear() {
        KeychainStore.clear(service: service, account: account)
    }
}
