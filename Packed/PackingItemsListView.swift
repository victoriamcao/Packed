//
//  PackingItemsListView.swift
//  Packed
//
//  The categorized, checkbox + swipe-to-delete packing list UI, shared
//  between a freshly generated list (ListPage) and a saved one being
//  reviewed (ListDetailView) so both look and behave the same way.
//

import SwiftUI

struct PackingItemsListView: View {
    @Binding var items: [PackingItem]
    @State private var swipedItemId: UUID?

    private var groupedItems: [String: [Binding<PackingItem>]] {
        Dictionary(grouping: $items, by: { $0.category.wrappedValue })
    }

    var body: some View {
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
                                .background(Color("buttonGray"))
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
            .padding(.bottom, 70)
        }
    }

    private func deleteItem(item: PackingItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: index)
        }
        swipedItemId = nil
    }
}
