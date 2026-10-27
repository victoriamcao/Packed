//
//  SupabaseAuthService.swift
//  Packed
//
//  Real email/password auth against Supabase's GoTrue REST API - no SDK,
//  calling it directly with URLSession to match this app's existing
//  networking style (see WeatherService, ClaudePackingListService).
//

import Foundation

enum SupabaseAuthError: LocalizedError {
    case invalidResponse
    case requestFailed(String)
    case confirmationRequired

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Unexpected response from the server."
        case .requestFailed(let message):
            return message
        case .confirmationRequired:
            return "Account created! Check your email for a confirmation link, then log in."
        }
    }
}

enum SupabaseAuthService {
    private static var authBaseURL: String { "\(SupabaseConfig.projectURL)/auth/v1" }

    static func signUp(email: String, password: String) async throws -> SupabaseSession {
        try await tokenRequest(path: "signup", body: ["email": email, "password": password])
    }

    static func signIn(email: String, password: String) async throws -> SupabaseSession {
        try await tokenRequest(path: "token?grant_type=password", body: ["email": email, "password": password])
    }

    static func refresh(refreshToken: String) async throws -> SupabaseSession {
        try await tokenRequest(path: "token?grant_type=refresh_token", body: ["refresh_token": refreshToken])
    }

    static func updatePassword(newPassword: String, accessToken: String) async throws {
        guard let url = URL(string: "\(authBaseURL)/user") else {
            throw SupabaseAuthError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["password": newPassword])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let message = (json?["msg"] as? String) ?? (json?["message"] as? String) ?? "Couldn't update your password."
            throw SupabaseAuthError.requestFailed(message)
        }
    }

    /// Emails a password reset code. The Supabase "Reset Password" email
    /// template must include {{ .Token }} so the email contains a code the
    /// user can type into the app (see supabase/README.md).
    static func sendPasswordResetCode(email: String) async throws {
        guard let url = URL(string: "\(authBaseURL)/recover") else {
            throw SupabaseAuthError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["email": email])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let message = (json?["msg"] as? String) ?? (json?["message"] as? String) ?? "Couldn't send the reset email. Try again in a minute."
            throw SupabaseAuthError.requestFailed(message)
        }
    }

    /// Trades the emailed reset code for a logged-in session.
    static func verifyRecoveryCode(email: String, code: String) async throws -> SupabaseSession {
        try await tokenRequest(path: "verify", body: ["type": "recovery", "email": email, "token": code])
    }

    /// Permanently deletes the account and all its data, via the
    /// delete-account Edge Function (deleting an auth user needs the
    /// service-role key, which must never be in the app).
    static func deleteAccount(accessToken: String) async throws {
        guard let url = URL(string: "\(SupabaseConfig.projectURL)/functions/v1/delete-account") else {
            throw SupabaseAuthError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = Data("{}".utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let message = (json?["error"] as? String) ?? "Couldn't delete your account. Check your connection and try again."
            throw SupabaseAuthError.requestFailed(message)
        }
    }

    static func signOut(accessToken: String) async {
        guard let url = URL(string: "\(authBaseURL)/logout") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        _ = try? await URLSession.shared.data(for: request)
    }

    private static func tokenRequest(path: String, body: [String: String]) async throws -> SupabaseSession {
        guard let url = URL(string: "\(authBaseURL)/\(path)") else {
            throw SupabaseAuthError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SupabaseAuthError.invalidResponse
        }

        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            let message = (json["error_description"] as? String)
                ?? (json["msg"] as? String)
                ?? (json["message"] as? String)
                ?? "Request failed."
            throw SupabaseAuthError.requestFailed(message)
        }

        // A successful signup with "Confirm email" turned on returns the new
        // user but no session - there's nothing to log in with until the
        // user clicks the emailed confirmation link.
        if json["access_token"] == nil, path == "signup" {
            throw SupabaseAuthError.confirmationRequired
        }

        guard let accessToken = json["access_token"] as? String,
              let refreshToken = json["refresh_token"] as? String,
              let expiresIn = json["expires_in"] as? Double,
              let user = json["user"] as? [String: Any],
              let userId = user["id"] as? String,
              let email = user["email"] as? String else {
            throw SupabaseAuthError.invalidResponse
        }

        return SupabaseSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            userId: userId,
            email: email,
            expiresAt: Date().addingTimeInterval(expiresIn)
        )
    }
}
