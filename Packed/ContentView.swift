import SwiftUI

struct ContentView: View {
    @EnvironmentObject var savedLists: SavedLists
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    Text("PACKED")
                        .font(.largeTitle)
                        .fontWeight(.medium)
                        .foregroundColor(Color("darkBlue"))
                        .offset(y: -100)
                    
                    NavigationLink(destination: SurveryPage()) {
                        Text("Create Packing List")
                            .font(.title)
                            .foregroundColor(Color.white)
                    }
                    .frame(maxWidth: 350, minHeight: 80)
                    .background(Color("lightBlue"))
                    .cornerRadius(30)
                    
                    NavigationLink(destination: PastLists()) {
                        Text("View Past Lists")
                            .foregroundColor(Color("textGray"))
                    }
                    .frame(maxWidth: 350, minHeight: 50)
                    .background(Color("buttonGray"))
                    .cornerRadius(20)
                }
                .padding()
                .padding(.horizontal)
                
                Image("plane 1")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 440)
                    .offset(y: 230)
                    .offset(x: -50)
                    .rotationEffect(.degrees(-8))
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SavedLists())
}
