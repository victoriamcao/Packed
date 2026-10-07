//
//  ShareListView.swift
//  Packed
//
//  Lets a list's owner share it with travel buddies by username. Shared
//  users see the list in their own Saved Lists and can check items off,
//  add, and remove items. Needs the sharing SQL in
//  supabase/migrations to be run on the backend.
//

import SwiftUI

struct ShareListView: View {
    let list: SavedLists.PackingList
    @EnvironmentObject var userData: UserData
    @Environment(\.dismiss) private var dismiss

    @State private var username = ""
    @State private var members: [SavedLists.ShareMember] = []
    @State private var isLoading = true
    @State private var isWorking = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("Their Packed username", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.send)
                            .onSubmit { Task { await addMember() } }
                        Button("Share") {
                            Task { await addMember() }
                        }
                        .disabled(trimmedUsername.isEmpty || isWorking)
                    }
                } header: {
                    Text("Share \"\(list.title)\"")
                } footer: {
                    Text("They'll see this list under Saved Lists and can check things off, add, and remove items. Changes show up for everyone when the list is reopened or refreshed.")
                }

                Section("Shared with") {
                    if isLoading {
                        ProgressView()
                    } else if members.isEmpty {
                        Text("Nobody yet")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(members) { member in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(member.name?.isEmpty == false ? member.name ?? member.username : member.username)
                                Text("@\(member.username)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .accessibilityElement(children: .combine)
                            .swipeActions {
                                Button(role: .destructive) {
                                    Task { await removeMember(member) }
                                } label: {
                                    Label("Remove", systemImage: "person.badge.minus")
                                }
                            }
                        }
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Share List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await loadMembers() }
        }
    }

    private var trimmedUsername: String {
        username.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "@"))
    }

    private func loadMembers() async {
        defer { isLoading = false }
        guard let token = try? await userData.validAccessToken() else { return }
        do {
            members = try await SavedLists.shareMembers(listId: list.id, accessToken: token)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func addMember() async {
        let name = trimmedUsername
        guard !name.isEmpty, !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        guard let token = try? await userData.validAccessToken() else {
            errorMessage = "You've been logged out. Log in and try again."
            return
        }
        do {
            try await SavedLists.share(listId: list.id, withUsername: name, accessToken: token)
            username = ""
            await loadMembers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func removeMember(_ member: SavedLists.ShareMember) async {
        guard let token = try? await userData.validAccessToken() else { return }
        do {
            try await SavedLists.unshare(listId: list.id, username: member.username, accessToken: token)
            members.removeAll { $0.id == member.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
