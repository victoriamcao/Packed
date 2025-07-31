import Foundation
import SwiftUI

class UserData: ObservableObject {
    @Published var name: String = ""
    @Published var username: String = ""
    @Published var isLoggedIn: Bool = false
    
    init() {
        loadAuthState()
    }
    
    func login(name: String, username: String) {
        self.name = name
        self.username = username
        self.isLoggedIn = true
        saveAuthState()
    }
    
    func logout() {
        name = ""
        username = ""
        isLoggedIn = false
        clearAuthState()
    }
    
    private func saveAuthState() {
        UserDefaults.standard.set(name, forKey: "userName")
        UserDefaults.standard.set(username, forKey: "userUsername")
        UserDefaults.standard.set(isLoggedIn, forKey: "isLoggedIn")
    }
    
    private func loadAuthState() {
        name = UserDefaults.standard.string(forKey: "userName") ?? ""
        username = UserDefaults.standard.string(forKey: "userUsername") ?? ""
        isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
    }
    
    private func clearAuthState() {
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "userUsername")
        UserDefaults.standard.removeObject(forKey: "isLoggedIn")
    }
}
