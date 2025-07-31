//
//  ContentView.swift
//  Packed
//
//  Created by Scholar on 7/29/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var userData = UserData()
    @State private var showAuthScreen = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Your existing home screen content
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
                
                // Plane image
                Image("plane 1")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 440)
                    .offset(y: 230)
                    .offset(x: -50)
                    .rotationEffect(.degrees(-8))
                
                // Profile button in top-right
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            showAuthScreen = true
                        }) {
                            Image(systemName: "person.circle")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .padding()
                        }
                    }
                    Spacer()
                }
            }
            .navigationDestination(isPresented: $showAuthScreen) {
                if userData.isLoggedIn {
                    ProfileView(userData: userData)
                } else {
                    LoginChoiceView(userData: userData)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
