import Security
import Foundation
import SwiftUI

class UserData: ObservableObject {
    // Basic Auth Properties
    @Published var name: String = ""
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var phoneNumber: String = ""
    @Published var website: String = ""
    @Published var isLoggedIn: Bool = false
    
    // Password handling (would be hashed in real implementation)
    private var password: String = ""
    
    init() {
        loadAuthState()
    }
    
    // Enhanced login with all profile information
    func login(name: String, username: String, email: String = "", password: String = "") {
        self.name = name
        self.username = username
        self.email = email
        self.password = password
        self.isLoggedIn = true
        saveAuthState()
    }
    
    // Profile update function
    func updateProfile(name: String, email: String, username: String) {
        self.name = name
        self.email = email
       
        saveAuthState()
    }
    
    // Password change function
    func changePassword(newPassword: String) {
        self.password = newPassword
        saveAuthState()
    }
    
    func logout() {
        name = ""
        username = ""
        email = ""
        
        password = ""
        isLoggedIn = false
        clearAuthState()
    }
    
    // MARK: - Persistence Methods
    
    private func saveAuthState() {
        UserDefaults.standard.set(name, forKey: "userName")
        UserDefaults.standard.set(username, forKey: "userUsername")
        UserDefaults.standard.set(email, forKey: "userEmail")
        UserDefaults.standard.set(isLoggedIn, forKey: "isLoggedIn")
        // Note: In a real app, you would never store password in UserDefaults
        // This is just for demonstration
        UserDefaults.standard.set(password, forKey: "userPassword")
    }
    
    private func loadAuthState() {
        name = UserDefaults.standard.string(forKey: "userName") ?? ""
        username = UserDefaults.standard.string(forKey: "userUsername") ?? ""
        email = UserDefaults.standard.string(forKey: "userEmail") ?? ""
        isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        password = UserDefaults.standard.string(forKey: "userPassword") ?? ""
    }
    
    private func clearAuthState() {
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "userUsername")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        
        UserDefaults.standard.removeObject(forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "userPassword")
    }
    
    
    func validateCurrentPassword(_ password: String) -> Bool {
        return self.password == password
    }
}
