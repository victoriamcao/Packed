//
//  ContentView.swift
//  Packed
//
//  Created by Scholar on 7/29/25.
//

import SwiftUI

struct ContentView: View {
    // StateObjects
    @StateObject var savedLists = SavedLists()
    @StateObject var userData = UserData()
    
    // UI and navigation states
    @State private var showAuthScreen = false
    @State private var currentTab: Tab = .home
    @State private var forceRefreshID = UUID()
    @State private var isShowingExplore = false
    @State private var isShowingProfile = false
    
    enum Tab: String {
        case home, explore, profile
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack {
                    // Header
                    Text("PACKED")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(Color("darkBlue"))
                        .padding(.top, 40)
                        .padding(.bottom, 20)
                        .offset(y: currentTab == .home ? -60 : 0)
                    
                    Spacer()
                    
                    // Create New List Button
                    NavigationLink(destination: SurveryPage(savedLists: savedLists)) {
                        Text("Create Packing List")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 300, height: 80)
                            .background(Color("lightBlue"))
                            .cornerRadius(25)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, y: 5)
                    }
                    .padding(.bottom, 20)
                    
                    // View Past Lists Button
                    NavigationLink(destination: PastLists(savedLists: savedLists)) {
                        Text("View Past Lists")
                            .font(.title3)
                            .foregroundColor(Color("textGray"))
                            .frame(width: 300, height: 60)
                            .background(Color("buttonGray"))
                            .cornerRadius(20)
                    }
                    
                    Spacer()
                    Spacer()
                    
                    // Plane Image
                    Image("plane 1")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 400)
                        .offset(y: 50)
                        .rotationEffect(.degrees(-8))
                        .opacity(0.9)
                }
                .padding()
                .padding(.horizontal)
                
                // Bottom Tab Bar
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
                        VStack(spacing: 4) {
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
                
                // Hidden Navigation
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
                    isShowingExplore = (newTab == .explore)
                    isShowingProfile = (newTab == .profile)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            savedLists.loadFromStorage()
        }
    }
}

#Preview {
    ContentView()
}


