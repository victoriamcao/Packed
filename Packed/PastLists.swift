import SwiftUI

struct PastLists: View {
    @ObservedObject var savedLists: SavedLists
    @EnvironmentObject var navigator: AppNavigator
    @EnvironmentObject var userData: UserData
    @State private var actionError: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 6) {
                Text("Saved Lists")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.lightBlue)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    .accessibilityAddTraits(.isHeader)

                Group {
                    if !userData.isLoggedIn {
                        Text("Log in to view your saved lists")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if savedLists.lists.isEmpty && savedLists.errorMessage != nil {
                        LoadErrorView(message: savedLists.errorMessage ?? "") {
                            await reload()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if savedLists.lists.isEmpty && !savedLists.hasLoaded {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if savedLists.lists.isEmpty {
                        Text("No saved lists yet")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(savedLists.lists) { list in
                                Button {
                                    navigator.push(.listDetail(list))
                                } label: {
                                    listRow(list)
                                }
                                .buttonStyle(.plain)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            }
                            .onDelete { indexSet in
                                let listsToRemove = indexSet.map { savedLists.lists[$0] }
                                Task { await remove(listsToRemove) }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .refreshable { await reload() }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 60)
            .toolbar {
                if userData.isLoggedIn && !savedLists.lists.isEmpty {
                    EditButton()
                }
            }

            BottomNavBar(current: .home)
        }
        .background(Color("appBackground").ignoresSafeArea())
        .task { await reload() }
        .alert("Couldn't remove list", isPresented: Binding(
            get: { actionError != nil },
            set: { if !$0 { actionError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(actionError ?? "")
        }
    }

    private func listRow(_ list: SavedLists.PackingList) -> some View {
        let isShared = !list.isOwned(by: userData.currentUserId)
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(list.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                if isShared {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(Color("lightBlue"))
                        .accessibilityLabel("Shared with you")
                }
            }
            Text("\(list.tripType) • \(list.items.count) items • \(list.duration) day(s)")
                .font(.caption)
                .foregroundColor(Color("textGray"))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("buttonGray"))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
    }

    private func reload() async {
        guard let token = try? await userData.validAccessToken(), let uid = userData.currentUserId else { return }
        await savedLists.loadFromStorage(userId: uid, accessToken: token)
    }

    /// Deletes lists you own; for lists shared with you, just removes
    /// them from your saved lists.
    private func remove(_ listsToRemove: [SavedLists.PackingList]) async {
        guard let token = try? await userData.validAccessToken() else {
            actionError = "You've been logged out. Log in and try again."
            return
        }
        for list in listsToRemove {
            let ok: Bool
            if list.isOwned(by: userData.currentUserId) {
                ok = await savedLists.deleteList(list, accessToken: token)
            } else {
                ok = await savedLists.leaveSharedList(list, accessToken: token)
            }
            if !ok {
                actionError = savedLists.errorMessage ?? "Couldn't remove \"\(list.title)\"."
            }
        }
    }
}

struct ListDetailView: View {
    let list: SavedLists.PackingList
    @ObservedObject var savedLists: SavedLists
    @EnvironmentObject var userData: UserData
    @State private var items: [PackingItem] = []
    @State private var hasPopulated = false
    @State private var pendingSave: Task<Void, Never>?
    @State private var saveErrorMessage: String?
    @State private var showingShareSheet = false
    @State private var newItem = ""

    private var isOwner: Bool { list.isOwned(by: userData.currentUserId) }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Text(list.title)
                    .padding([.top, .leading, .bottom])
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity)
                    .accessibilityAddTraits(.isHeader)

                Text("\(list.tripType) • \(list.duration) day(s) • \(list.member)\(isOwner ? "" : " • Shared with you")")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 8)

                Text("\(items.filter(\.isPacked).count) of \(items.count) packed")
                    .font(.caption)
                    .foregroundColor(Color("textGray"))
                    .padding(.bottom, 8)

                Divider()

                PackingItemsListView(items: $items)

                AddItemBar(text: $newItem) { name in
                    items.append(PackingItem(name: name, category: "Added by You"))
                }
                .padding(.bottom, 60)
            }
            .padding(.top)

            BottomNavBar(current: .home)
        }
        .background(Color("appBackground").ignoresSafeArea())
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                ShareLink(item: PackingListExport.text(title: list.title, items: items)) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Export list")

                if isOwner {
                    Button {
                        showingShareSheet = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                    .accessibilityLabel("Share with a travel buddy")
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareListView(list: list)
                .environmentObject(userData)
        }
        .onAppear {
            if !hasPopulated {
                let latest = savedLists.lists.first(where: { $0.id == list.id }) ?? list
                items = latest.items.map(\.packingItem)
                hasPopulated = true
            }
        }
        .onChange(of: items) { _, newValue in
            guard hasPopulated else { return }
            scheduleSave(newValue)
        }
        .onDisappear {
            // Make sure the last edit still goes out if the user leaves
            // during the debounce window.
            if pendingSave != nil {
                pendingSave?.cancel()
                save(items)
            }
        }
        .alert("Couldn't save your changes", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("Try Again") { save(items) }
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveErrorMessage ?? "")
        }
    }

    /// Waits for a short pause in edits, then saves once - so checking off
    /// five items quickly sends one request, not five racing ones.
    private func scheduleSave(_ newItems: [PackingItem]) {
        pendingSave?.cancel()
        pendingSave = Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            guard !Task.isCancelled else { return }
            pendingSave = nil
            save(newItems)
        }
    }

    private func save(_ itemsToSave: [PackingItem]) {
        pendingSave = nil
        let saved = itemsToSave.map { SavedPackingItem($0) }
        Task {
            guard let token = try? await userData.validAccessToken() else {
                saveErrorMessage = "You've been logged out, so this change wasn't saved. Log in and try again."
                return
            }
            let ok = await savedLists.updateList(list, items: saved, userId: userData.currentUserId, accessToken: token)
            if !ok {
                saveErrorMessage = "Your last change didn't reach the server. Check your connection and try again."
            }
        }
    }
}

/// The "Item Name  [Add]" bar under a packing list.
struct AddItemBar: View {
    @Binding var text: String
    var onAdd: (String) -> Void

    var body: some View {
        HStack {
            TextField("Item Name", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.leading)
                .submitLabel(.done)
                .onSubmit(add)
            Button(action: add) {
                Text("Add")
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color("lightBlue"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .accessibilityLabel("Add item")
            .padding(.trailing)
        }
        .padding(.vertical, 12)
        .background(Color("buttonGray"))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.4)),
            alignment: .top
        )
    }

    private func add() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onAdd(String(trimmed.prefix(100)))
        text = ""
    }
}

// Preview provider for PastLists
struct PastLists_Previews: PreviewProvider {
    static var previews: some View {
        let savedLists = SavedLists()
        savedLists.lists = [
            SavedLists.PackingList(
                id: UUID().uuidString,
                title: "Beach Trip",
                items: [
                    SavedPackingItem(name: "Sunscreen", category: "Essentials"),
                    SavedPackingItem(name: "Swimsuit", category: "Beachwear"),
                    SavedPackingItem(name: "Towel", category: "Beachwear")
                ],
                tripType: "Vacation",
                duration: 7,
                member: "Family",
                createdAt: Date()
            )
        ]
        return NavigationStack {
            PastLists(savedLists: savedLists)
                .environmentObject(AppNavigator())
                .environmentObject(UserData())
        }
    }
}
