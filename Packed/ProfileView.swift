//  ProfileView.swift
//  Packed
//
//  Created by Scholar on 7/30/25.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var userData: UserData
    @EnvironmentObject var navigator: AppNavigator
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditView = false
    @State private var confirmingDelete = false
    @State private var isDeleting = false
    @State private var deleteError: String?
    
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
                            .accessibilityHidden(true)
                        
                        Text(userData.name.isEmpty ? "Hi!" : "Hi, \(userData.name)!")
                            .font(.title)
                            .fontWeight(.medium)
                            .accessibilityAddTraits(.isHeader)
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
                            .accessibilityLabel("Change password")
                        }

                        Section(header: Text("AI Packing Assistant").font(.headline)) {
                            Button {
                                navigator.push(.apiKeySettings)
                            } label: {
                                InfoRow(
                                    label: "Personal Anthropic API Key (optional)",
                                    value: APIKeyStore.load() == nil ? "Not set - using Packed's AI" : "Using your key"
                                )
                            }
                        }

                        Section(header: Text("Appearance").font(.headline)) {
                            AppearancePicker(selection: $themeManager.preference)
                                .padding(.top, 4)
                        }
                    }
                    .padding()
                    .background(Color("buttonGray"))
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
                            navigator.goHome()
                        }) {
                            Text("Log Out")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentRed)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        Button(role: .destructive) {
                            confirmingDelete = true
                        } label: {
                            Text(isDeleting ? "Deleting Account..." : "Delete Account")
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .disabled(isDeleting)
                        .padding(.top, 8)

                        Link("Privacy Policy", destination: AppLinks.privacyPolicy)
                            .font(.footnote)
                            .foregroundColor(Color.textGray)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .sheet(isPresented: $showingEditView) {
                EditProfileView(userData: userData)
            }
            .confirmationDialog(
                "Delete your account?",
                isPresented: $confirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Delete Account and All Data", role: .destructive) {
                    Task { await deleteAccount() }
                }
            } message: {
                Text("This permanently deletes your account, saved lists, and map photos. It can't be undone.")
            }
            .alert("Couldn't delete account", isPresented: Binding(
                get: { deleteError != nil },
                set: { if !$0 { deleteError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deleteError ?? "")
            }

            BottomNavBar(current: .profile)
        }
        .background(Color("appBackground").ignoresSafeArea())
    }

    private func deleteAccount() async {
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await userData.deleteAccount()
            navigator.goHome()
        } catch {
            deleteError = error.localizedDescription
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
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .accessibilityHidden(true)
            } else {
                Text(value.isEmpty ? "Not set" : value)
            }
            
            Divider()
        }
        .padding(.vertical, 8)
        .foregroundColor(.primary)
    }
}
// Appearance Picker - a 3-way Light/Dark/System control styled like the
// rest of the app's custom controls (buttonGray pill, lightBlue selection)
// instead of the native segmented control.
struct AppearancePicker: View {
    @Binding var selection: AppColorScheme

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppColorScheme.allCases) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = option
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: option.icon)
                            .font(.subheadline.weight(.semibold))
                            .accessibilityHidden(true)
                        Text(option.label)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(selection == option ? Color.lightBlue : Color.clear)
                    .foregroundColor(selection == option ? .white : Color.textGray)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(option.label) appearance")
                .accessibilityAddTraits(selection == option ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Color.buttonGray)
        .cornerRadius(12)
    }
}

#Preview {
    ProfileView(userData: UserData())
        .environmentObject(AppNavigator())
        .environmentObject(ThemeManager())
}
