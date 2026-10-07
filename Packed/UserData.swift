import Foundation
import SwiftUI

enum UserDataError: LocalizedError {
    case notLoggedIn

    var errorDescription: String? {
        switch self {
        case .notLoggedIn:
            return "Please log in to do that."
        }
    }
}

@MainActor
class UserData: ObservableObject {
    @Published var name: String = ""
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var isLoggedIn: Bool = false

    private var session: SupabaseSession?

    var currentUserId: String? { session?.userId }

    init() {
        if let saved = SupabaseSessionStore.load() {
            session = saved
            email = saved.email
            isLoggedIn = true
            Task { await loadProfile() }
        }
    }

    // MARK: - Auth

    func signUp(name: String, username: String, email: String, password: String) async throws {
        let newSession = try await SupabaseAuthService.signUp(email: email, password: password)
        session = newSession
        SupabaseSessionStore.save(newSession)
        self.email = newSession.email
        isLoggedIn = true

        try await SupabaseProfileService.upsertProfile(
            userId: newSession.userId,
            name: name,
            username: username,
            accessToken: newSession.accessToken
        )
        self.name = name
        self.username = username
    }

    func login(email: String, password: String) async throws {
        let newSession = try await SupabaseAuthService.signIn(email: email, password: password)
        session = newSession
        SupabaseSessionStore.save(newSession)
        self.email = newSession.email
        isLoggedIn = true
        await loadProfile()
    }

    func logout() {
        if let session {
            Task { await SupabaseAuthService.signOut(accessToken: session.accessToken) }
        }
        clearLocalSession()
    }

    private func clearLocalSession() {
        session = nil
        name = ""
        username = ""
        email = ""
        isLoggedIn = false
        SupabaseSessionStore.clear()
        PhotoCache.removeAll()
    }

    /// Permanently deletes the account and everything in it on the server,
    /// then signs out on this device.
    func deleteAccount() async throws {
        let token = try await validAccessToken()
        try await SupabaseAuthService.deleteAccount(accessToken: token)
        Log.auth.notice("Account deleted")
        clearLocalSession()
    }

    // MARK: - Password reset

    func sendPasswordResetCode(email: String) async throws {
        try await SupabaseAuthService.sendPasswordResetCode(email: email)
    }

    /// Verifies the emailed code (which logs the user in), then sets the new password.
    func resetPassword(email: String, code: String, newPassword: String) async throws {
        let newSession = try await SupabaseAuthService.verifyRecoveryCode(email: email, code: code)
        session = newSession
        SupabaseSessionStore.save(newSession)
        self.email = newSession.email
        isLoggedIn = true
        try await SupabaseAuthService.updatePassword(newPassword: newPassword, accessToken: newSession.accessToken)
        await loadProfile()
    }

    func updateProfile(name: String, username: String) async throws {
        let token = try await validAccessToken()
        guard let userId = session?.userId else { throw UserDataError.notLoggedIn }
        try await SupabaseProfileService.upsertProfile(userId: userId, name: name, username: username, accessToken: token)
        self.name = name
        self.username = username
    }

    /// Verifies the current password by attempting to sign in with it, then
    /// updates to the new one.
    func changePassword(currentPassword: String, newPassword: String) async throws {
        _ = try await SupabaseAuthService.signIn(email: email, password: currentPassword)
        let token = try await validAccessToken()
        try await SupabaseAuthService.updatePassword(newPassword: newPassword, accessToken: token)
    }

    private func loadProfile() async {
        guard let token = try? await validAccessToken(), let userId = session?.userId else { return }
        if let profile = try? await SupabaseProfileService.fetchProfile(userId: userId, accessToken: token) {
            name = profile.name ?? ""
            username = profile.username ?? ""
        }
    }

    // MARK: - Session

    /// A valid (non-expired) access token, refreshing it first if needed.
    /// Throws (and logs out) if there's no session or the refresh fails.
    func validAccessToken() async throws -> String {
        guard let current = session else { throw UserDataError.notLoggedIn }

        if current.expiresAt > Date().addingTimeInterval(30) {
            return current.accessToken
        }

        do {
            let refreshed = try await SupabaseAuthService.refresh(refreshToken: current.refreshToken)
            session = refreshed
            SupabaseSessionStore.save(refreshed)
            return refreshed.accessToken
        } catch {
            Log.auth.error("Session refresh failed, logging out: \(error.localizedDescription, privacy: .public)")
            logout()
            throw UserDataError.notLoggedIn
        }
    }
}
