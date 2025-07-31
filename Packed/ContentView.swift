//
//  ContentView.swift
//  Packed
//
//
import SwiftUI
struct ContentView: View {
    @StateObject var savedLists = SavedLists()
    @StateObject var userData = UserData()
    @State private var showAuthScreen = false
    @State private var currentTab: Tab = .home
    @State private var forceRefreshID = UUID()
    
    // Add these for navigation control
    @State private var isShowingExplore = false
    @State private var isShowingProfile = false
    
    enum Tab: String {
        case home, explore, profile
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Your original content (unchanged)
                VStack {
                    Text("PACKED")
                        .font(.largeTitle)
                        .fontWeight(.medium)
                        .foregroundColor(Color("darkBlue"))
                        .offset(y: -100)
                    
                    NavigationLink(destination: SurveryPage(savedLists: savedLists)) {
                        Text("Create Packing List")
                            .font(.title)
                            .foregroundColor(Color.white)
                    }
                    .frame(maxWidth: 350, minHeight: 80)
                    .background(Color("lightBlue"))
                    .cornerRadius(30)
                    
                    NavigationLink(destination: PastLists(savedLists: savedLists)) {
                        Text("View Past Lists")
                            .foregroundColor(Color("textGray"))
                    }
                    .frame(maxWidth: 350, minHeight: 50)
                    .background(Color("buttonGray"))
                    .cornerRadius(20)
                }
                .padding()
                .padding(.horizontal)
                
                // Plane image (unchanged)
                Image("plane 1")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 440)
                    .offset(y: 230)
                    .offset(x: -50)
                    .rotationEffect(.degrees(-8))
                
                // Bottom Navigation Bar
                HStack {
                    // Home Tab
                    Button {
                        if currentTab == .home {
                            forceRefreshID = UUID()
                        }
                        currentTab = .home
                        isShowingExplore = false
                        isShowingProfile = false
                    } label: {
                        VStack (spacing: 4) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 25))
                                .foregroundColor(currentTab == .home ? .darkBlue : .textGray)
                           
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    
                    // Explore Tab
                    Button {
                        if currentTab == .explore {
                            forceRefreshID = UUID()
                        }
                        currentTab = .explore
                        isShowingExplore = true
                        isShowingProfile = false
                    } label: {
                        VStack {
                            Image(systemName: "globe")
                                .font(.system(size: 25))
                                .foregroundColor(currentTab == .explore ? .darkBlue : .textGray)
                        
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    
                    // Profile Tab
                    Button {
                        if currentTab == .profile {
                            forceRefreshID = UUID()
                        }
                        currentTab = .profile
                        isShowingExplore = false
                        isShowingProfile = true
                    } label: {
                        VStack {
                            Image(systemName: userData.isLoggedIn ? "person.circle.fill" : "person.crop.circle")
                                .font(.system(size: 25))
                                .foregroundColor(currentTab == .profile ? .darkBlue : .textGray)
                           
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                }
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .offset(y: 298)
                
                // Updated Hidden Navigation
                Group {
                    NavigationLink(
                        destination: MapPage().id(forceRefreshID),
                        isActive: $isShowingExplore,
                        label: { EmptyView() }
                    )
                    
                    NavigationLink(
                        destination: userData.isLoggedIn ?
                            AnyView(ProfileView(userData: userData).id(forceRefreshID)) :
                            AnyView(LoginChoiceView(userData: userData).id(forceRefreshID)),
                        isActive: $isShowingProfile,
                        label: { EmptyView() }
                    )
                }
                .onChange(of: currentTab) { newTab in
                    // Reset navigation states when tab changes
                    isShowingExplore = (newTab == .explore)
                    isShowingProfile = (newTab == .profile)
                }
            }
        }
    .onAppear {
        savedLists.loadFromStorage()
            }
    }
}
#Preview {
    ContentView()
}

