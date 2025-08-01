//
//  ListPage.swift
//  Packed
//
//  Created by Scholar on 7/29/25.
//

import SwiftUI

struct ListPage: View {
    var selectedType: String
    var selectedGender: String
    var selectedWeather: String
    var selectedLength: Int
    @ObservedObject var savedLists: SavedLists
    @State private var vacationName: String = ""
    @State private var newItem: String = ""
    // Add the state variable to track the swiped item
    @State private var swipedItemId: UUID?
    @State private var items: [PackingItem] = []
    
    @Environment(\.dismiss) var dismiss
    
    // Grouping logic
    var groupedItems: [String: [Binding<PackingItem>]] {
        Dictionary(grouping: $items, by: { $0.category.wrappedValue })
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextField("Vacation Name", text: $vacationName)
                    .padding([.top, .leading, .bottom])
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                Divider()
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(groupedItems.keys.sorted(), id: \.self) { category in
                            Section(header:
                                Text(category)
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(Color("lightBlue")) // Restored original color
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                            ) {
                                ForEach(groupedItems[category]!) { $item in
                                    // ZStack to layer the delete button behind the item
                                    ZStack(alignment: .trailing) {
                                        // The delete button that is conditionally rendered on swipe
                                        if item.id == swipedItemId {
                                            Button(action: {
                                                withAnimation {
                                                    deleteItem(item: item)
                                                }
                                            }) {
                                                Image(systemName: "trash.fill")
                                                    .foregroundColor(.white)
                                                    .font(.title2)
                                                    .frame(width: 80, height: 44)
                                                    .background(Color.red)
                                                    .cornerRadius(10)
                                            }
                                            // Ensure the button is on top of the list item
                                            .zIndex(1)
                                        }
                                        
                                        // The item content that slides to reveal the button
                                        HStack {
                                            // Custom square checkbox
                                            Button(action: {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    item.isPacked.toggle()
                                                }
                                            }) {
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .stroke(Color.gray, lineWidth: 2)
                                                        .frame(width: 24, height: 24)
                                                        .background(
                                                            RoundedRectangle(cornerRadius: 4)
                                                                .fill(item.isPacked ? Color("accentRed") : Color.clear)
                                                        )
                                                    
                                                    if item.isPacked {
                                                        Image(systemName: "xmark")
                                                            .font(.system(size: 14, weight: .bold))
                                                            .foregroundColor(.white)
                                                            .transition(.scale.combined(with: .opacity))
                                                    }
                                                }
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            
                                            Text(item.name)
                                                .font(.body)
                                                .strikethrough(item.isPacked, color: .gray)
                                                .foregroundColor(item.isPacked ? .gray : .primary)
                                                .animation(.easeInOut(duration: 0.2), value: item.isPacked)
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.systemBackground))
                                        .offset(x: item.id == swipedItemId ? -80 : 0) // Slide to reveal button
                                        .animation(.easeOut(duration: 0.3), value: swipedItemId)
                                        .contentShape(Rectangle()) // Make the entire row tappable
                                        // Ensure the list item is below the button when swiped
                                        .zIndex(0)
                                        .gesture(
                                            DragGesture()
                                                .onEnded { value in
                                                    if value.translation.width < -50 {
                                                        swipedItemId = item.id
                                                    } else if value.translation.width > 50 {
                                                        swipedItemId = nil
                                                    }
                                                }
                                        )
                                        .onTapGesture {
                                            // Close the swipe if the row is tapped
                                            swipedItemId = nil
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top)
                }
                
                // Add new item manually
                HStack {
                    TextField("Item Name", text: $newItem)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.leading)
                    Button(action: {
                        let trimmed = newItem.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty {
                            items.append(PackingItem(name: trimmed, category: "Added by You"))
                            newItem = ""
                        }
                    }) {
                        Text("Add")
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color("lightBlue"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.trailing)
                }
                .padding(.vertical, 12)
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.4)),
                    alignment: .top
                )
                
                // Save and Go Home buttons
                VStack(spacing: 0) {
                    Button(action: {
                        let listItems = items.map { $0.name }
                        savedLists.saveList(
                            title: vacationName.isEmpty ? "Untitled" : vacationName,
                            items: listItems,
                            type: selectedType,
                            duration: selectedLength,
                            member: selectedGender
                        )
                        dismiss() // Dismiss the view and go back to the home screen
                    }) {
                        Text("Save List")
                            .font(.headline)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(Color("lightBlue"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    .padding(.top, 10)
                }
                .padding(.bottom, 20)
            }
            .padding(.top)
            .onAppear {
                if items.isEmpty {
                    // Use a Task to run the async function
                    Task {
                        items = await ListItems.generatePackingList(
                            type: selectedType,
                            gender: selectedGender,
                            weather: selectedWeather,
                            length: selectedLength
                        )
                        // Pre-fill the vacation name based on selections
                        vacationName = "\(selectedType) - \(selectedLength) Day(s)"
                    }
                }
            }
        }
    }
    
    // Function to delete an item from the list
    private func deleteItem(item: PackingItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: index)
        }
        swipedItemId = nil // Reset the swiped state
    }
}

#Preview {
    ListPage(
        selectedType: "Tropical Vacation",
        selectedGender: "Female",
        selectedWeather: "Sunny",
        selectedLength: 3,
        savedLists: SavedLists()
    )
}
