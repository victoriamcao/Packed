import SwiftUI

struct ListPage: View {
    var selectedType: String
    var selectedGender: String
    var selectedWeather: String
    var selectedLength: Int

    @State private var vacationName: String = ""
    @State private var newItem: String = ""
    @State private var showHomeButton: Bool = false
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
                    LazyVStack(alignm3ent: .leading, spacing: 20) {
                        ForEach(groupedItems.keys.sorted(), id: \.self) { category in
                            Section(header:
                                Text(category)
                                    .font(.headline)
                                    .padding(.horizontal)
                            ) {
                                ForEach(groupedItems[category]!) { $item in
                                    Button(action: {
                                        item.isPacked.toggle()
                                    }) {
                                        HStack {
                                            Text(item.isPacked ? "☒" : "☐")
                                                .font(.title1)
                                                .foregroundColor(item.isPacked ? .blue : .gray)
                                            Text(item.name)
                                                .foregroundColor(item.isPacked ? .gray : .primary)
                                                .strikethrough(item.isPacked, color: .gray)
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 0)
                                        .background(Color.white)
                                        .cornerRadius(8)
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

                // Go Home button
                VStack(spacing: 0) {
                    if showHomeButton {
                        NavigationLink(destination: ContentView()) {
                            Text("Go Home")
                                .font(.headline)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .background(Color("lightBlue"))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Button(action: {
                        withAnimation {
                            showHomeButton.toggle()
                        }
                    }) {
                        Image(systemName: showHomeButton ? "chevron.down" : "chevron.up")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.gray)
                            .padding(.bottom, 10)
                    }
                }
            }
            .padding(.top)
            .onAppear {
                if items.isEmpty {
                    items = ListItems.generatePackingList(
                        type: selectedType,
                        gender: selectedGender,
                        weather: selectedWeather,
                        length: selectedLength
                    )
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
        selectedLength: 3
    )
}


