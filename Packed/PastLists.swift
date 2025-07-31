import SwiftUI

struct PastLists: View {
    @ObservedObject var savedLists: SavedLists
    
    var body: some View {
        NavigationStack {
            if savedLists.lists.isEmpty {
                Text("No saved lists yet")
                    .foregroundColor(.gray)
            } else {
                List {
                    ForEach(savedLists.lists) { list in
                        NavigationLink {
                            ListDetailView(list: list)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(list.title)
                                    .font(.headline)
                                Text("\(list.items.count) items • \(list.duration) day(s) • \(list.member)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .onDelete(perform: savedLists.deleteList)
                }
            }
        }
        .navigationTitle("Saved Lists")
        .toolbar {
            EditButton()
        }
    }
}

struct ListDetailView: View {
    let list: SavedLists.PackingList
    
    var body: some View {
        List {
            Section("Trip Details") {
                Text("Type: \(list.tripType)")
                Text("Member: \(list.member)")
                Text("Duration: \(list.duration) day(s)")
            }
            
            Section("Packing List") {
                ForEach(list.items, id: \.self) { item in
                    Text(item)
                }
            }
        }
        .navigationTitle(list.title)
    }
}

// Preview provider for PastLists
struct PastLists_Previews: PreviewProvider {
    static var previews: some View {
        let savedLists = SavedLists()
        savedLists.lists = [
            SavedLists.PackingList(
                title: "Beach Trip",
                items: ["Sunscreen", "Swimsuit", "Towel"],
                tripType: "Vacation",
                duration: 7,
                member: "Family"
            )
        ]
        return PastLists(savedLists: savedLists)
    }
}
