//
//  ContentView.swift
//  Packed
//
//  Created by Scholar on 7/29/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var savedLists = SavedLists() // The single source of truth for all lists
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color if you want one
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack {
                    // Header
                    Text("PACKED")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(Color("darkBlue"))
                        .padding(.top, 40)
                        .padding(.bottom, 20)
                    
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
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    ContentView()
}
