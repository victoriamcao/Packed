//
//  LoginFormView.swift
//  Packed
//
//  Created by Scholar on 7/30/25.
//

import SwiftUI

struct LoginFormView: View {
    @ObservedObject var userData: UserData
    @EnvironmentObject var navigator: AppNavigator
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoggingIn = false
    @State private var showingForgotPassword = false

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 20) {
                Text("Log In")
                    .font(.largeTitle)
                    .bold()
                    .accessibilityAddTraits(.isHeader)

                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .keyboardType(.emailAddress)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)
                    .padding(.horizontal)

                HStack {
                    Spacer()
                    Button("Forgot password?") {
                        showingForgotPassword = true
                    }
                    .font(.footnote)
                    .foregroundColor(Color.lightBlue)
                }
                .padding(.horizontal)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button(action: loginUser) {
                    Text(isLoggingIn ? "Logging In..." : "Log In")
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(!email.isEmpty && !password.isEmpty ? Color.lightBlue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .disabled(email.isEmpty || password.isEmpty || isLoggingIn)

                Button {
                    navigator.push(.signup)
                } label: {
                    HStack {
                        Text("Don't have an account? Sign up")
                            .foregroundColor(Color.lightBlue)
                        Image(systemName: "chevron.right")
                            .font(.callout)
                            .foregroundColor(Color.lightBlue)
                            .accessibilityHidden(true)
                    }
                }
            }
            .padding()
            .padding(.bottom, 60)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            BottomNavBar(current: .profile)
        }
        .background(Color("appBackground").ignoresSafeArea())
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView(userData: userData, initialEmail: email) {
                navigator.go(to: .profile)
            }
        }
    }

    private func loginUser() {
        errorMessage = ""
        isLoggingIn = true
        Task {
            do {
                try await userData.login(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
                navigator.go(to: .profile)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoggingIn = false
        }
    }
}

#Preview {
    LoginFormView(userData: UserData())
        .environmentObject(AppNavigator())
}
