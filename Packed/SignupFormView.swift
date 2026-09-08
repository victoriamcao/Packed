//
//  SignupFormView.swift
//  Packed
//
//  Created by Scholar on 7/30/25.
//

import SwiftUI

struct SignupFormView: View {
    @ObservedObject var userData: UserData
    @EnvironmentObject var navigator: AppNavigator
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var errorMessage = ""
    @State private var canSignUp = false
    @State private var emailValid = false
    @State private var showEmailError = false
    @State private var isSigningUp = false

    
    init(userData: UserData) {
        self.userData = userData
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 20) {
                Text("Create Account")
                    .font(.largeTitle)
                    .bold()
                
                // Name Field
                TextField("Full Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .onChange(of: name) { _ in
                        validateForm()
                    }
                
                // Email Field with enhanced validation
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                        .autocapitalization(.none)
                        .onChange(of: email) { newValue in
                            emailValid = isValidEmail(newValue)
                            validateForm()
                            showEmailError = !newValue.isEmpty && !emailValid
                        }
                    
                    if showEmailError {
                        Text("Please enter a valid email (example@domain.com)")
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal, 5)
                    }
                }
                
                // Username Field
                TextField("Username", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .autocapitalization(.none)
                    .onChange(of: username) { _ in
                        validateForm()
                    }
                
                // Password Field
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .onChange(of: password) { _ in
                        validateForm()
                    }
                
                // Validation Requirements
                VStack(alignment: .leading, spacing: 8) {
                    // Password Requirements
                    Text("Password Requirements:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    RequirementView(met: PasswordPolicy.hasMinimumLength(password), text: "8+ characters")
                    RequirementView(met: PasswordPolicy.hasNumber(password), text: "Contains number")
                    RequirementView(met: PasswordPolicy.hasSpecialCharacter(password), text: "Special character (!@#$%^&*)")
                    
                    // Email Validation Indicator
                    if !email.isEmpty {
                        RequirementView(met: emailValid, text: "Valid email format")
                    }
                    
                    // Username Requirement
                    if !username.isEmpty {
                        RequirementView(met: username.count >= 4, text: "Username 4+ characters")
                    }
                }
                .padding(.horizontal)
                
                // General Error Message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                // Sign Up Button
                Button(action: signUpUser) {
                    Text(isSigningUp ? "Creating Account..." : "Sign Up")
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(canSignUp ? Color.lightBlue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .disabled(!canSignUp || isSigningUp)

                // Navigation to Login
                Button {
                    navigator.push(.login)
                } label: {
                    HStack {
                        Text("I already have an account")
                            .foregroundColor(Color.blue)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.top, 10)

            
            }
            .padding()
            .padding(.bottom, 60)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            BottomNavBar(current: .profile)
        }
        .background(Color("appBackground").ignoresSafeArea())
    }

    private func validateForm() {
        let nameValid = !name.isEmpty
        let usernameValid = !username.isEmpty && username.count >= 4
        let passwordValid = PasswordPolicy.isValid(password)
        canSignUp = nameValid && emailValid && usernameValid && passwordValid
    }
    
    private func signUpUser() {
        errorMessage = ""
        
        // Validate all fields
        guard !name.isEmpty else {
            errorMessage = "Please enter your full name"
            return
        }
        
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }
        
        guard emailValid else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        guard !username.isEmpty else {
            errorMessage = "Please choose a username"
            return
        }
        
        guard username.count >= 4 else {
            errorMessage = "Username must be at least 4 characters"
            return
        }
        
        guard PasswordPolicy.isValid(password) else {
            errorMessage = "Password doesn't meet all requirements"
            return
        }

        isSigningUp = true
        Task {
            do {
                try await userData.signUp(name: name, username: username, email: email, password: password)
                navigator.go(to: .profile)
            } catch {
                errorMessage = error.localizedDescription
            }
            isSigningUp = false
        }
    }
    
    // Improved email validation
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// Reusable Requirement View - shows a checkmark/x that flips red -> green
// live as the requirement becomes met. Shared with ChangePasswordView.
struct RequirementView: View {
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
        .animation(.easeInOut(duration: 0.2), value: met)
    }
}

#Preview {
    SignupFormView(userData: UserData())
        .environmentObject(AppNavigator())
}
