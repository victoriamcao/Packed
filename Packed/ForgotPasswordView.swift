//
//  ForgotPasswordView.swift
//  Packed
//
//  Two steps, all in the app: enter your email to get a 6-digit code,
//  then enter the code plus a new password. Logs you in when it works.
//

import SwiftUI

struct ForgotPasswordView: View {
    @ObservedObject var userData: UserData
    var initialEmail: String = ""
    var onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var code = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var codeSent = false
    @State private var isWorking = false
    @State private var errorMessage = ""

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canReset: Bool {
        code.count >= 6 && PasswordPolicy.isValid(newPassword) && newPassword == confirmPassword
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .disabled(codeSent)
                    if !codeSent {
                        Button(isWorking ? "Sending..." : "Email Me a Reset Code") {
                            Task { await sendCode() }
                        }
                        .disabled(trimmedEmail.isEmpty || isWorking)
                    }
                } footer: {
                    if !codeSent {
                        Text("We'll email you a 6-digit code to reset your password.")
                    }
                }

                if codeSent {
                    Section {
                        TextField("6-digit code", text: $code)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                        SecureField("New Password", text: $newPassword)
                            .textContentType(.newPassword)
                        SecureField("Confirm New Password", text: $confirmPassword)
                            .textContentType(.newPassword)
                    } header: {
                        Text("Check your email")
                    } footer: {
                        Button("Send a new code") {
                            Task { await sendCode() }
                        }
                        .font(.footnote)
                        .disabled(isWorking)
                    }

                    Section("Password Requirements") {
                        RequirementView(met: PasswordPolicy.hasMinimumLength(newPassword), text: "8+ characters")
                        RequirementView(met: PasswordPolicy.hasNumber(newPassword), text: "Contains number")
                        RequirementView(met: PasswordPolicy.hasSpecialCharacter(newPassword), text: "Special character (!@#$%^&*)")
                        if !confirmPassword.isEmpty {
                            RequirementView(met: newPassword == confirmPassword, text: "Passwords match")
                        }
                    }

                    Button(isWorking ? "Resetting..." : "Reset Password") {
                        Task { await reset() }
                    }
                    .disabled(!canReset || isWorking)
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if email.isEmpty { email = initialEmail }
            }
        }
    }

    private func sendCode() async {
        errorMessage = ""
        isWorking = true
        defer { isWorking = false }
        do {
            try await userData.sendPasswordResetCode(email: trimmedEmail)
            codeSent = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func reset() async {
        errorMessage = ""
        isWorking = true
        defer { isWorking = false }
        do {
            try await userData.resetPassword(
                email: trimmedEmail,
                code: code.trimmingCharacters(in: .whitespacesAndNewlines),
                newPassword: newPassword
            )
            dismiss()
            onComplete()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
