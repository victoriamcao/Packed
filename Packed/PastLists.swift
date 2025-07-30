import SwiftUI

struct PastLists: View {
    @EnvironmentObject var savedLists: SavedLists
    
    var body: some View {
        VStack {
            Text("Past Lists")
                .font(.largeTitle)
                .foregroundColor(Color("darkBlue"))
                .padding()
            
            if savedLists.lists.isEmpty {
                Text("No saved lists yet")
                    .foregroundColor(.gray)
                    .padding()
                Spacer()
            } else {
                List {
                    ForEach(savedLists.lists.indices, id: \.self) { index in
                        Section(header:
                            Text(savedLists.lists[index][0].replacingOccurrences(of: "TRIP_NAME: ", with: ""))
                                .font(.headline)
                        ) {
                            ForEach(Array(savedLists.lists[index].dropFirst(4)), id: \.self) { item in
                                Text(item)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    PastLists()
        .environmentObject(SavedLists())
}
