//  ProfileView.swift
//  Packed
//
//  Created by Scholar on 7/30/25.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var userData: UserData
    @EnvironmentObject var navigator: AppNavigator
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditView = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header with Greeting
                    VStack(spacing: 10) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.lightBlue)
                        
                        Text("Hi, \(userData.name)!")
                            .font(.title)
                            .fontWeight(.medium)
                    }
                    .padding(.top, 20)
                    
                    // Editable User Info
                    VStack(alignment: .leading, spacing: 16) {
                        Section(header: Text("Your Profile").font(.headline)) {
                            InfoRow(label: "Name", value: userData.name)
                            InfoRow(label: "Username", value: userData.username)
                        }
                        
                        Section(header: Text("Contact").font(.headline)) {
                            InfoRow(label: "Email", value: userData.email)
                        }
                        
                        Section(header: Text("Security").font(.headline)) {
                            Button {
                                navigator.push(.changePassword)
                            } label: {
                                InfoRow(label: "Password", value: "••••••••", isSecure: true)
                            }
                        }

                        Section(header: Text("AI Packing Assistant").font(.headline)) {
                            Button {
                                navigator.push(.apiKeySettings)
                            } label: {
                                InfoRow(
                                    label: "Anthropic API Key",
                                    value: APIKeyStore.load() == nil ? "Not set" : "Configured"
                                )
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Action Buttons
                    VStack(spacing: 15) {
                        Button(action: { showingEditView = true }) {
                            Text("Edit Profile")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.lightBlue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        Button(action: {
                            userData.logout()
                            dismiss()
                        }) {
                            Text("Log Out")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentRed)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .sheet(isPresented: $showingEditView) {
                EditProfileView(userData: userData)
            }

            BottomNavBar(current: .profile)
        }
    }
}

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
                Section(header: Text("Anthropic API Key"), footer: Text("Packed uses your own Anthropic API key to generate AI-personalized packing lists. Your key is stored securely on this device and is never sent anywhere besides Anthropic's API. Without a key, Packed falls back to its built-in packing list rules.")) {
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
    }
}

// Reusable Info Row Component
struct InfoRow: View {
    let label: String
    let value: String
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            
            if isSecure {
                HStack {
                    Text("••••••••")
                    Spacer()
                    Image(systemName: "eye.slash")
                }
            } else {
                Text(value.isEmpty ? "Not set" : value)
            }
            
            Divider()
        }
        .padding(.vertical, 8)
        .foregroundColor(.primary)
    }
}
#Preview {
    ProfileView(userData: UserData())
}
