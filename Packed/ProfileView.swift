//  ProfileView.swift
//  Packed
//
//  Created by Scholar on 7/30/25.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var userData: UserData
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditView = false
    
    var body: some View {
        NavigationStack {
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
                            NavigationLink(destination: ChangePasswordView(userData: userData)) {
                                InfoRow(label: "Password", value: "••••••••", isSecure: true)
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

            .sheet(isPresented: $showingEditView) {
                EditProfileView(userData: userData)
            }
        }
    }
}

// Edit Profile Subview
struct EditProfileView: View {
    @ObservedObject var userData: UserData
    @Environment(\.dismiss) var dismiss
    @State private var name: String
    @State private var email: String
    @State private var username: String
    
    init(userData: UserData) {
        self.userData = userData
        _name = State(initialValue: userData.name)
        _email = State(initialValue: userData.email)
        _username = State(initialValue: userData.username)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal Info")) {
                    TextField("Name", text: $name)
                    TextField("Username", text: $username)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Edit Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        userData.updateProfile(
                            name: name,
                            email: email,
                            username: username
                        )
                        dismiss()
                    }
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
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Current Password", text: $currentPassword)
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm Password", text: $confirmPassword)
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Change Password")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if validatePasswordChange() {
                            userData.changePassword(newPassword: newPassword)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    private func validatePasswordChange() -> Bool {
        guard !currentPassword.isEmpty else {
            errorMessage = "Enter current password"
            return false
        }
        guard newPassword.count >= 8 else {
            errorMessage = "Password must be 8+ characters"
            return false
        }
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords don't match"
            return false
        }
        return true
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
