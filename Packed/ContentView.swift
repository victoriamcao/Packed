//
//  ContentView.swift
//  Packed
//
//

import SwiftUI

struct ContentView: View {
    @StateObject var userData = UserData()
    @State private var showAuthScreen = false
    @State private var currentTab: Tab = .home // Track current tab
    
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
                
                // Your original plane image (unchanged)
                Image("plane 1")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 440)
                    .offset(y: 230)
                    .offset(x: -50)
                    .rotationEffect(.degrees(-8))
                
                // Enhanced BottomNavBar with smart tab handling
                HStack {
                    // Home Tab
                    Button {
                        currentTab = .home
                    } label: {
                        VStack {
                            Image(systemName: "house.fill")
                                .font(.system(size: 24))
                                .foregroundColor(currentTab == .home ? .blue : .gray)
                            Text("Home")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Explore Tab
                    Button {
                        currentTab = .explore
                    } label: {
                        VStack {
                            Image(systemName: "globe")
                                .font(.system(size: 24))
                                .foregroundColor(currentTab == .explore ? .blue : .gray)
                            Text("Explore")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Profile Tab
                    Button {
                        currentTab = .profile
                    } label: {
                        VStack {
                            Image(systemName: userData.isLoggedIn ? "person.circle.fill" : "person.crop.circle")
                                .font(.system(size: 24))
                                .foregroundColor(currentTab == .profile ? .blue : .gray)
                            Text("Profile")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .overlay(Divider(), alignment: .top)
                .offset(y: 290) // Keeping your exact offset
            }
        }
    }
}

#Preview {
    ContentView()
}
