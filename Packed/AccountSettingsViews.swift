//
//  AccountSettingsViews.swift
//  Packed
//
//  The screens reached from Profile: edit profile, change password, and
//  the optional personal Anthropic API key.
//

import SwiftUI

// Edit Profile Subview
struct EditProfileView: View {
    @ObservedObject var userData: UserData
    @Environment(\.dismiss) var dismiss
    @State private var name: String
    @State private var username: String
    @State private var errorMessage = ""
    @State private var isSaving = false

    init(userData: UserData) {
        self.userData = userData
        _name = State(initialValue: userData.name)
        _username = State(initialValue: userData.username)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal Info"), footer: Text("Email is set at signup and can't be changed here.")) {
                    TextField("Name", text: $name)
                    TextField("Username", text: $username)
                    Text(userData.email)
                        .foregroundColor(.gray)
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Edit Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") {
                        Task {
                            isSaving = true
                            do {
                                try await userData.updateProfile(name: name, username: username)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isSaving = false
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }
}

// Change Password Subview
struct ChangePasswordView: View {
    @ObservedObject var userData: UserData
    @Environment(\.dismiss) var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var isSaving = false

    private var canSave: Bool {
        !currentPassword.isEmpty && PasswordPolicy.isValid(newPassword) && newPassword == confirmPassword
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Form {
                Section {
                    SecureField("Current Password", text: $currentPassword)
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm Password", text: $confirmPassword)
                }

                Section("Password Requirements") {
                    RequirementView(met: PasswordPolicy.hasMinimumLength(newPassword), text: "8+ characters")
                    RequirementView(met: PasswordPolicy.hasNumber(newPassword), text: "Contains number")
                    RequirementView(met: PasswordPolicy.hasSpecialCharacter(newPassword), text: "Special character (!@#$%^&*)")
                    if !confirmPassword.isEmpty {
                        RequirementView(met: newPassword == confirmPassword, text: "Passwords match")
                    }
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Change Password")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") {
                        guard validatePasswordChange() else { return }
                        Task {
                            isSaving = true
                            do {
                                try await userData.changePassword(currentPassword: currentPassword, newPassword: newPassword)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isSaving = false
                        }
                    }
                    .disabled(isSaving || !canSave)
                }
            }

            BottomNavBar(current: .profile)
        }
        .background(Color("appBackground").ignoresSafeArea())
    }

    private func validatePasswordChange() -> Bool {
        guard !currentPassword.isEmpty else {
            errorMessage = "Enter current password"
            return false
        }
        guard PasswordPolicy.isValid(newPassword) else {
            errorMessage = "Password doesn't meet all requirements"
            return false
        }
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords don't match"
            return false
        }
        errorMessage = ""
        return true
    }
}

// API Key Settings Subview
struct APIKeySettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var apiKey: String = APIKeyStore.load() ?? ""
    @State private var errorMessage: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            Form {
                Section(header: Text("Anthropic API Key"), footer: Text("Optional. When you're logged in, Packed makes AI-personalized lists for you without a key. If you add your own Anthropic API key, Packed uses it instead (no monthly limit). Your key is stored securely on this device and is only ever sent to Anthropic's API.")) {
                    SecureField("sk-ant-...", text: $apiKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }

                if !apiKey.isEmpty {
                    Button("Remove Key", role: .destructive) {
                        if APIKeyStore.clear() {
                            apiKey = ""
                            errorMessage = nil
                        } else {
                            errorMessage = "Couldn't remove the key from the Keychain. Try again."
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("AI Packing Assistant")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if APIKeyStore.save(apiKey) {
                            dismiss()
                        } else {
                            errorMessage = "Couldn't save the key to the Keychain. Try again."
                        }
                    }
                }
            }

            BottomNavBar(current: .profile)
        }
        .background(Color("appBackground").ignoresSafeArea())
    }
}

