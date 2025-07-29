//
//  ListPage.swift
//  Packed
//
//  Created by Scholar on 7/29/25.
//

import SwiftUI

struct ListPage: View {
    @State private var vacationName: String = ""
    @State private var newItem: String = ""
    @State private var itemList: [String] = []

    var body: some View {
        VStack(alignment: .center) {
            TextField("Vacation Name", text: $vacationName)
                .padding([.top, .leading, .bottom])
                .font(.largeTitle)
                .multilineTextAlignment(.center)

            Divider()

            if !itemList.isEmpty {
                List {
                    ForEach(itemList, id: \.self) { item in
                        Text("• \(item)")
                    }
                    .onDelete(perform: deleteItem)
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .frame(maxHeight: 250)
            }

            Spacer()

            HStack {
                TextField("Item Name", text: $newItem)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: {
                    if !newItem.trimmingCharacters(in: .whitespaces).isEmpty {
                        itemList.append(newItem)
                        newItem = ""
                    }
                }) {
                    Text("Add")
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.trailing)
            }
        }
        .padding()
    }

    private func deleteItem(at offsets: IndexSet) {
        itemList.remove(atOffsets: offsets)
    }
}

#Preview {
    ListPage()
}
