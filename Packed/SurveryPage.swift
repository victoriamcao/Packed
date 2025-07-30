import SwiftUI

struct ListPage: View {
    @EnvironmentObject var savedLists: SavedLists
    @State private var currentList: [String] = []
    @State private var newItem: String = ""
    @State private var tripName: String = ""
    @Environment(\.dismiss) var dismiss
    
    var selectedType: String
    var selectedGender: String
    var selectedWeather: String
    var selectedLength: Int
    
    var body: some View {
        VStack {
            TextField("Name Your Trip", text: $tripName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onAppear {
                    if tripName.isEmpty {
                        tripName = "\(selectedType) Trip"
                    }
                }
            
            HStack {
                TextField("Add item", text: $newItem)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Add") {
                    if !newItem.isEmpty {
                        currentList.append(newItem)
                        newItem = ""
                    }
                }
            }
            .padding()
            
            List {
                ForEach(currentList, id: \.self) { item in
                    Text(item)
                }
                .onDelete { indexSet in
                    currentList.remove(atOffsets: indexSet)
                }
            }
            
            Button("Save and Go Home") {
                saveList()
                dismiss()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color("lightBlue"))
            .foregroundColor(.white)
            .cornerRadius(15)
            .padding()
        }
        .onAppear {
            currentList = ListItems.generatePackingList(
                type: selectedType,
                gender: selectedGender,
                weather: selectedWeather,
                length: selectedLength
            )
        }
    }
    
    private func saveList() {
        guard !currentList.isEmpty else { return }
        
        var completeList = currentList
        completeList.insert("TRIP_NAME: \(tripName)", at: 0)
        completeList.insert("TYPE: \(selectedType)", at: 1)
        completeList.insert("DURATION: \(selectedLength) days", at: 2)
        completeList.insert("WEATHER: \(selectedWeather)", at: 3)
        
        savedLists.lists.insert(completeList, at: 0)
    }
}

#Preview {
    ListPage(
        selectedType: "Beach Vacation",
        selectedGender: "Female",
        selectedWeather: "Sunny",
        selectedLength: 5
    )
    .environmentObject(SavedLists())
}
