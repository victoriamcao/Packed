import SwiftUI

struct ListPage: View {
    @EnvironmentObject var savedLists: SavedLists // Changed to EnvironmentObject
    @State private var currentList: [String] = []
    @State private var newItem: String = ""
    @State private var tripName: String = ""
    @Environment(\.dismiss) var dismiss
    
    // Trip details
    var selectedType: String
    var selectedGender: String
    var selectedWeather: String
    var selectedLength: Int
    
    var body: some View {
        VStack {
            // Trip Name Field
            TextField("Name your trip", text: $tripName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onAppear {
                    if tripName.isEmpty {
                        tripName = "\(selectedType) Trip"
                    }
                }
            
            // Trip Details
            VStack(alignment: .leading) {
                Text("Type: \(selectedType)")
                Text("Weather: \(selectedWeather)")
                Text("Duration: \(selectedLength) day(s)")
            }
            .font(.caption)
            .foregroundColor(.gray)
            .padding(.bottom)
            
            // Add Items
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
            
            // List of Items
            List {
                ForEach(currentList, id: \.self) { item in
                    Text(item)
                }
                .onDelete { indexSet in
                    currentList.remove(atOffsets: indexSet)
                }
            }
            
            // WORKING SAVE BUTTON
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
        
        // Create complete list with metadata
        var completeList = currentList
        completeList.insert("TRIP_NAME: \(tripName)", at: 0)
        completeList.insert("TRIP_TYPE: \(selectedType)", at: 1)
        completeList.insert("DURATION: \(selectedLength) days", at: 2)
        completeList.insert("WEATHER: \(selectedWeather)", at: 3)
        
        // Save to shared SavedLists
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
