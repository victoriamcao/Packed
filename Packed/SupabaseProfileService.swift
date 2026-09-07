//
//  SupabaseProfileService.swift
//  Packed
//
//  The `profiles` table holds account info beyond what Supabase Auth
//  itself stores (name, chosen username), keyed by the auth user's id.
//

import Foundation

struct SupabaseProfile: Decodable {
    let id: String
    let name: String?
    let username: String?
}

enum SupabaseProfileService {
    static func fetchProfile(userId: String, accessToken: String) async throws -> SupabaseProfile? {
        guard var components = URLComponents(string: "\(SupabaseConfig.projectURL)/rest/v1/profiles") else {
            throw SupabaseAuthError.invalidResponse
        }
        components.queryItems = [
            URLQueryItem(name: "id", value: "eq.\(userId)"),
            URLQueryItem(name: "select", value: "*")
        ]
        guard let url = components.url else { throw SupabaseAuthError.invalidResponse }

        var request = URLRequest(url: url)
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let profiles = try JSONDecoder().decode([SupabaseProfile].self, from: data)
        return profiles.first
    }

    static func upsertProfile(userId: String, name: String, username: String, accessToken: String) async throws {
        guard let url = URL(string: "\(SupabaseConfig.projectURL)/rest/v1/profiles") else {
            throw SupabaseAuthError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("resolution=merge-duplicates,return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "id": userId,
            "name": name,
            "username": username
        ])

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw SupabaseAuthError.requestFailed("Couldn't save your profile.")
        }
    }
}
