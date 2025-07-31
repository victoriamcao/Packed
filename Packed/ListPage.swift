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
                                    .background(Color("lightBlue"))
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                            ) {
                                
                                ForEach(groupedItems[category]!) { $item in
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
                        dismiss()
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
                    Task {
                        items = await ListItems.generatePackingList(
                            type: selectedType,
                            gender: selectedGender,
                            weather: selectedWeather,
                            length: selectedLength
                        )
                        vacationName = "\(selectedType) - \(selectedLength) Day(s)"
                    }
                }
            }
        }
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
