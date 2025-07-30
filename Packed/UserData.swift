import Foundation
import SwiftUI

class UserData: ObservableObject {
    @Published var name: String = ""
    @Published var isLoggedIn: Bool = false
    
    init() {
        loadAuthState()
    }
    
    func login(username: String) {
        name = username
        isLoggedIn = true
        saveAuthState()
    }
    
    func logout() {
        name = ""
        isLoggedIn = false
        clearAuthState()
    }
    
    // Save to UserDefaults
    private func saveAuthState() {
        UserDefaults.standard.set(name, forKey: "username")
        UserDefaults.standard.set(isLoggedIn, forKey: "isLoggedIn")
    }
    
    // Load from UserDefaults
    private func loadAuthState() {
        name = UserDefaults.standard.string(forKey: "username") ?? ""
        isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
    }
    
    // Clear saved state
    private func clearAuthState() {
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "isLoggedIn")
    }
}
