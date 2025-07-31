//
//  BottomNavBar.swift
//  Packed
//
//  Created by Scholar on 7/31/25.
//

import SwiftUI

struct BottomNavBar: View {
    @StateObject var userData = UserData()
    @State private var showAuthScreen = false

    var body: some View {
        HStack(spacing: 0) {
            // Home Button
            NavigationLink(destination: ContentView()) {
                VStack {
                    Image(systemName: "house.fill")
                        .font(.system(size: 22))
                    
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            
            // Map Button
            NavigationLink(destination: MapPage()) {
                VStack {
                    Image(systemName: "globe")
                        .font(.system(size: 22))
                    Text("Explore")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            
            // Profile Button
           
                    
                        NavigationLink {
                        if userData.isLoggedIn {
                        ProfileView(userData: userData)
                        } else {
                        LoginChoiceView(userData: userData)
                                     }
                        } label: {
                        Image(systemName: "person.circle")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .padding()
                                .offset(y: 750)
                                .offset(x: -40)
                                 }
                           
        }
        .background(Color(.systemBackground))
        .overlay(Divider(), alignment: .top)
        .frame(height: 60)
    }
}

#Preview {
    BottomNavBar()
}
