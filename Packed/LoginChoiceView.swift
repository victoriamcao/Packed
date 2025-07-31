//
//  LoginChoiceView.swift
//  Packed
//
//  Created by Scholar on 7/30/25.
//

import SwiftUI

struct LoginChoiceView: View {
    @ObservedObject var userData: UserData  // Add this line
    
    var body: some View {
        NavigationStack{
            VStack(spacing: 20) {
                Text("Welcome")
                    .font(.largeTitle)
                    .bold()
                
                NavigationLink(destination: LoginFormView(userData: userData)) {  // Pass userData
                    Text("Log in")
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                NavigationLink(destination: SignupFormView(userData: userData)){  // Pass userData
                    Text("Create Account")
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
        }
    }
}

#Preview {
    LoginChoiceView(userData: UserData())  // Pass UserData for preview
}
