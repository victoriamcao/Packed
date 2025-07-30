import SwiftUI

struct PastLists: View {
    @State private var savedLists: [PackingList] = []
    @State private var goHome = false

    var body: some View {
        VStack {
            Text("Past Lists")
                .padding(.top)
                .font(.largeTitle)

            Divider()

            if savedLists.isEmpty {
                Spacer()
                Text("No past lists yet.")
                    .foregroundColor(.gray)
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(savedLists) { list in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(list.vacationName)
                                    .font(.headline)
                                ForEach(list.items, id: \.self) { item in
                                    Text("• \(item)")
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }
            }

            Button(action: {
                goHome = true
            }) {
                Text("Go Home")
                    .font(.headline)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color("lightBlue"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding()
        .onAppear {
            loadSavedLists()
        }
        .navigationDestination(isPresented: $goHome) {
            ContentView()
        }
    }

    func loadSavedLists() {
        if let data = UserDefaults.standard.data(forKey: "savedPackingLists"),
           let decoded = try? JSONDecoder().decode([PackingList].self, from: data) {
            savedLists = decoded
        }
    }
}

#Preview {
    NavigationStack {
        PastLists()
    }
}
