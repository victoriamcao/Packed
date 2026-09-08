import SwiftUI

struct PastLists: View {
    @ObservedObject var savedLists: SavedLists
    @EnvironmentObject var navigator: AppNavigator
    @EnvironmentObject var userData: UserData

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 6) {
                Text("Saved Lists")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.lightBlue)
                    .padding(.top, 20)
                    .padding(.bottom, 10)

                Group {
                    if !userData.isLoggedIn {
                        Text("Log in to view your saved lists")
                            .foregroundColor(.gray)
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
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(list.title)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("\(list.tripType) • \(list.items.count) items • \(list.duration) day(s)")
                                            .font(.caption)
                                            .foregroundColor(Color("textGray"))
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color("buttonGray"))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            }
                            .onDelete { indexSet in
                                let listsToDelete = indexSet.map { savedLists.lists[$0] }
                                Task {
                                    guard let token = try? await userData.validAccessToken() else { return }
                                    for list in listsToDelete {
                                        await savedLists.deleteList(list, accessToken: token)
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                if userData.isLoggedIn && !savedLists.lists.isEmpty {
                    EditButton()
                }
            }

            BottomNavBar(current: .home)
        }
        .background(Color("appBackground").ignoresSafeArea())
        .onAppear {
            Task {
                guard let token = try? await userData.validAccessToken(), let uid = userData.currentUserId else { return }
                await savedLists.loadFromStorage(userId: uid, accessToken: token)
            }
        }
    }
}

struct ListDetailView: View {
    let list: SavedLists.PackingList
    @ObservedObject var savedLists: SavedLists
    @EnvironmentObject var userData: UserData
    @State private var items: [PackingItem] = []

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Text(list.title)
                    .padding([.top, .leading, .bottom])
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Text("\(list.tripType) • \(list.duration) day(s) • \(list.member)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 8)

                Divider()

                PackingItemsListView(items: $items)
            }
            .padding(.top)

            BottomNavBar(current: .home)
        }
        .background(Color("appBackground").ignoresSafeArea())
        .onAppear {
            if items.isEmpty {
                items = list.items.map { PackingItem(name: $0.name, category: $0.category) }
            }
        }
        .onChange(of: items) { oldValue, newValue in
            // Skip the initial [] -> populated-from-list transition in
            // onAppear above; only persist genuine user edits (check-off,
            // swipe-to-delete) that happen after items is already populated.
            guard !oldValue.isEmpty else { return }
            Task {
                guard let token = try? await userData.validAccessToken() else { return }
                let saved = newValue.map { SavedPackingItem(name: $0.name, category: $0.category) }
                await savedLists.updateList(list, items: saved, accessToken: token)
            }
        }
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
