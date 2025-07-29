//
//  ContentView.swift
//  Packed
//
//  Created by Scholar on 7/29/25.
//

//This is the homepage

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack{
            ZStack{
                Image("Screenshot 2025-07-29 at 1.56.15 PM")
                    .resizable(resizingMode: .stretch)
                    .aspectRatio(contentMode: .fill)
                    
                   
                VStack {
                    // Spacer()
                    
                    Text("PACKED")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color("darkBlue"))
                        
                    
                    //  Spacer()
                   /* Image("Screenshot 2025-07-29 at 1.21.39 PM")
                        .resizable(resizingMode: .tile)
                        .aspectRatio(contentMode: .fit)*/
                    NavigationLink(destination: SurveryPage()) {
                        Text("Make a List")
                            .font(.title2)
                            .foregroundColor(Color.white)
                    }
                    
                    .frame(maxWidth: .infinity, minHeight: 70)
                    .background(Color("lightBlue"))
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    
                    
                    NavigationLink(destination: SurveryPage()){
                        Text("View Past Lists")
                            .foregroundColor(Color("textGray"))//remember to change link to past lists
                        
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color("buttonGray"))
                    // .foregroundColor(.white)
                    .cornerRadius(15)
                }
                .padding()
                .padding()
            }
        }
    }
}

#Preview {
    ContentView()
}
