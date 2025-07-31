//
//  ProfileView.swift
//  Packed
//
//  Created by Scholar on 7/30/25.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var userData: UserData
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                Text("Welcome, \(userData.name)!")
                    .font(.title)
                
                Button(action: {
                    userData.logout()
                    dismiss() // Goes back to previous screen
                }) {
                    Text("Log Out")
                        .frame(maxWidth: 200, minHeight: 50)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Your Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ProfileView(userData: UserData())
}
