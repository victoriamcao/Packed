import SwiftUI
struct ListPage: View {
    @State private var vacationName: String = ""
    @State private var newItem: String = ""
    @State private var itemList: [String] = []
    @State private var showHomeButton: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            
            TextField("Vacation Name", text: $vacationName)
                .padding([.top, .leading, .bottom])
                .font(.largeTitle)
                .multilineTextAlignment(.center)

            Divider()

         
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(itemList, id: \.self) { item in
                        Text("• \(item)")
                            .padding(.horizontal)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 10)
            }
            .frame(maxHeight: .infinity)

            
            HStack {
                TextField("Item Name", text: $newItem)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading)

                Button(action: {
                    if !newItem.trimmingCharacters(in: .whitespaces).isEmpty {
                        itemList.append(newItem)
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

          
            VStack(spacing: 0) {
                if showHomeButton {
                    Button(action: {
                        
                    }) {
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
    }
}
#Preview {
    ListPage()
}
