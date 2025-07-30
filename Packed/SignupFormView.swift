//
//  SignupFormView.swift
//  Packed
//
//  Created by Scholar on 7/30/25.
//

import SwiftUI

struct SignupFormView: View {
    @ObservedObject var userData: UserData
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var errorMessage = ""
    @State private var canSignUp = false
    
    init(userData: UserData) {
        self.userData = userData
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Create Account")
                    .font(.largeTitle)
                    .bold()
                
                TextField("Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .onChange(of: name) { _ in
                        validateForm()
                    }
                
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .autocapitalization(.none)
                    .onChange(of: email) { _ in
                        validateForm()
                    }
                TextField("Username", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .autocapitalization(.none)
                    .onChange(of: username) { _ in
                        validateForm()
                    }
                
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .onChange(of: password) { _ in
                        validateForm()
                    }
                
                // Password requirements
                VStack(alignment: .leading, spacing: 8) {
                    RequirementView(met: password.count >= 8, text: "8+ characters")
                    RequirementView(met: hasNumber(password), text: "Contains number")
                    RequirementView(met: hasSpecialCharacter(password), text: "Special character (!@#$%^&*)")
                }
                .padding(.horizontal)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: signUpUser) {
                    Text("Sign Up")
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(canSignUp ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .disabled(!canSignUp)
            }
            .padding()
            .navigationDestination(isPresented: .constant(userData.name != "" && errorMessage.isEmpty)) {
                ProfileView(userData: userData)
            }
        }
    }
    
    private func validateForm() {
        let nameValid = !name.isEmpty
        let emailValid = !email.isEmpty && email.contains("@")
        let usernameValid = !username.isEmpty
        let passwordValid = isPasswordValid(password)
        canSignUp = nameValid && emailValid && passwordValid
    }
    
    private func signUpUser() {
        errorMessage = ""
        
        guard !name.isEmpty else {
            errorMessage = "Please enter your name"
            return
        }
        
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }
        
        guard email.contains("@") else {
            errorMessage = "Please enter a valid email"
            return
        }
        guard !username.isEmpty else {
            errorMessage = "Please enter your username"
            return
        }
        guard isPasswordValid(password) else {
            errorMessage = "Password doesn't meet requirements"
            return
        }
        
        userData.name = name
    }
    
    private func isPasswordValid(_ password: String) -> Bool {
        password.count >= 8 && hasNumber(password) && hasSpecialCharacter(password)
    }
    
    private func hasNumber(_ string: String) -> Bool {
        string.rangeOfCharacter(from: .decimalDigits) != nil
    }
    
    private func hasSpecialCharacter(_ string: String) -> Bool {
        string.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*")) != nil
    }
}

private struct RequirementView: View {
    let met: Bool
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: met ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(met ? .green : .red)
            Text(text)
                .font(.caption)
                .foregroundColor(met ? .green : .red)
        }
    }
}

#Preview {
    SignupFormView(userData: UserData())
}
