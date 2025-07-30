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
               
                   
                VStack {
                    // Spacer()
                    
                    Text("PACKED")
                        .font(.largeTitle)
                        .fontWeight(.medium)
                        .foregroundColor(Color("darkBlue"))
                        .offset(y: -100)
                        
                    
                    //  Spacer()
                   /* Image("Screenshot 2025-07-29 at 1.21.39 PM")
                        .resizable(resizingMode: .tile)
                        .aspectRatio(contentMode: .fit)*/
                    NavigationLink(destination: SurveryPage()) {
                        Text("Create Packing List")
                            .font(.title)
                            .foregroundColor(Color.white)
                    }//Navlink
                    
                    .frame(maxWidth: 350, minHeight: 80)
                    .background(Color("lightBlue"))
                    .foregroundColor(.white)
                    .cornerRadius(30)
                    
                    
                    NavigationLink(destination: SurveryPage()){
                        Text("View Past Lists")
                            .foregroundColor(Color("textGray"))//remember to change link to past lists
                        
                    }//Navlink
                    .frame(maxWidth: 350, minHeight: 50)
                    .background(Color("buttonGray"))
                    // .foregroundColor(.white)
                    .cornerRadius(20)
                }//VStack
                .padding()
                .padding(.horizontal)
                Image("plane 1")
                    .resizable()
                           .aspectRatio(contentMode: .fit)
                           .frame(width: 440) // adjust size
                           .offset(y: 230)
                           .offset(x: -50)
                           .rotationEffect(.degrees(-8)) // rotates the image counterclockwise

                    
            }//ZStack
        }//navStack
    }//body
}//struct

#Preview {
    ContentView()
}
