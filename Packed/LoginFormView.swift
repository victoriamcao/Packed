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
    
    // Simple fake user database for demo
    private let validUsers = [
        "john": ("John Doe", "password123"),
        "sarah": ("Sarah Smith", "mypass456"),
        "alex": ("Alex Johnson", "hello789")
    ]
    
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
                
                Button(action: loginUser) {
                    Text("Log In")
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(!username.isEmpty && !password.isEmpty ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .disabled(username.isEmpty || password.isEmpty)
                Button(action: loginUser) {
                    HStack {
                        Text("Forgot Password")
                            .foregroundColor(Color.blue)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .navigationDestination(isPresented: .constant(userData.isLoggedIn)) {
                ProfileView(userData: userData)
            }
        }
    }
    
    private func loginUser() {
        errorMessage = ""
        
        guard !username.isEmpty else {
            errorMessage = "Please enter your username"
            return
        }
        
        guard !password.isEmpty else {
            errorMessage = "Please enter your password"
            return
        }
        
        if let user = validUsers[username.lowercased()] {
            if password == user.1 {
                // Successful login
                userData.login(name: user.0, username: username.lowercased())
            } else {
                errorMessage = "Please use the right password"
            }
        } else {
            errorMessage = "Username not found. Please check your username or create an account."
        }
    }
}

#Preview {
    LoginFormView(userData: UserData())
}
