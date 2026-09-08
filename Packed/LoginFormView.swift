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

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 20) {
                Text("Log In")
                    .font(.largeTitle)
                    .bold()

                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button(action: loginUser) {
                    Text(isLoggingIn ? "Logging In..." : "Log In")
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(!email.isEmpty && !password.isEmpty ? Color.blue : Color.gray)
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
                            .foregroundColor(Color.blue)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .padding(.bottom, 60)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            BottomNavBar(current: .profile)
        }
        .background(Color("appBackground").ignoresSafeArea())
    }

    private func loginUser() {
        errorMessage = ""
        isLoggingIn = true
        Task {
            do {
                try await userData.login(email: email, password: password)
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
