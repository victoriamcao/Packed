//
//  PackingItemsListView.swift
//  Packed
//
//  The categorized, checkbox packing list UI, shared between a freshly
//  generated list (ListPage) and a saved one being reviewed
//  (ListDetailView) so both look and behave the same way.
//
//  Built on List so it gets the system's swipe-to-delete (which VoiceOver
//  exposes as an action) and touch-and-hold drag to reorder for free.
//

import SwiftUI

struct PackingItemsListView: View {
    @Binding var items: [PackingItem]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // Group once per render rather than once per row.
        let grouped = Dictionary(grouping: $items, by: { $0.category.wrappedValue })
        let categories = grouped.keys.sorted()

        List {
            ForEach(categories, id: \.self) { category in
                Section {
                    ForEach(grouped[category] ?? []) { $item in
                        row(for: $item)
                            .listRowBackground(Color("buttonGray"))
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    delete(item.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    .onMove { source, destination in
                        move(in: category, from: source, to: destination)
                    }
                } header: {
                    Text(category)
                        .font(.title3)
                        .bold()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color("lightBlue"))
                        .cornerRadius(10)
                        .padding(.top, 8)
                        .textCase(nil)
                        .accessibilityAddTraits(.isHeader)
                }
                .listRowSeparator(.hidden)
                .listSectionSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func row(for item: Binding<PackingItem>) -> some View {
        let packed = item.wrappedValue.isPacked
        return Button {
            if reduceMotion {
                item.wrappedValue.isPacked.toggle()
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    item.wrappedValue.isPacked.toggle()
                }
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray, lineWidth: 2)
                        .frame(width: 24, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(packed ? Color("accentRed") : Color.clear)
                        )

                    if packed {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                Text(item.wrappedValue.name)
                    .font(.body)
                    .lineLimit(3)
                    .strikethrough(packed, color: .secondary)
                    .foregroundColor(packed ? .secondary : .primary)

                Spacer(minLength: 0)
            }
            // Whole row is the tap target, at least 44pt tall.
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.wrappedValue.name)
        .accessibilityValue(packed ? "Packed" : "Not packed")
        .accessibilityHint("Double tap to mark as \(packed ? "not packed" : "packed")")
        .accessibilityAddTraits(packed ? [.isButton, .isSelected] : .isButton)
    }

    private func delete(_ id: UUID) {
        items.removeAll { $0.id == id }
    }

    /// Reorders within one category. Each category's items keep the same
    /// slots in the overall array, just in a new order.
    private func move(in category: String, from source: IndexSet, to destination: Int) {
        let positions = items.indices.filter { items[$0].category == category }
        var reordered = positions.map { items[$0] }
        reordered.move(fromOffsets: source, toOffset: destination)
        for (position, item) in zip(positions, reordered) {
            items[position] = item
        }
    }
}
