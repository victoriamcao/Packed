//
//  LoginFormView.swift
//  Packed
//
//  Created by Scholar on 7/30/25.
//

import SwiftUI

struct LoginFormView: View {
    @ObservedObject var userData: UserData
    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showPasswordError = false
    
    init(userData: UserData) {
        self.userData = userData
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Log In")
                    .font(.largeTitle)
                    .bold()
                
                TextField("Username", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                if showPasswordError {
                    Text("Please use the right password")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: {
                    if validateLogin() {
                        userData.login(username: username) // This triggers persistent login
                    }
                }) {
                    Text("Log In")
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(!username.isEmpty && !password.isEmpty ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .disabled(username.isEmpty || password.isEmpty)
            }
            .padding()
            .navigationDestination(isPresented: .constant(userData.isLoggedIn && errorMessage.isEmpty)) {
                ProfileView(userData: userData)
            }
        }
    }
    
    private func validateLogin() -> Bool {
        errorMessage = ""
        showPasswordError = false
        
        guard !username.isEmpty else {
            errorMessage = "Please enter your username"
            return false
        }
        
        guard !password.isEmpty else {
            errorMessage = "Please enter your password"
            return false
        }
        
        // Simple validation - replace with real authentication
        let validUsers = [
            "john": "password123",
            "sarah": "mypass456",
            "alex": "hello789"
        ]
        
        if let correctPassword = validUsers[username.lowercased()] {
            if password == correctPassword {
                return true // Successful login
            } else {
                showPasswordError = true
                return false
            }
        } else {
            errorMessage = "Username not found"
            return false
        }
    }
}

#Preview {
    LoginFormView(userData: UserData())
}
