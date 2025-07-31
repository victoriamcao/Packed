//
//  LoginChoiceView.swift
//  Packed
//
//  Created by Scholar on 7/30/25.
//

import SwiftUI

struct LoginChoiceView: View {
    @ObservedObject var userData: UserData
    @State private var isHoveringLogin = false
    @State private var isHoveringSignup = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image("logo")
                    .resizable()
                    .frame(width: 200, height: 200)


                Text("Join us!")

                    .font(.largeTitle)
                    .bold()
                    .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)

                NavigationLink(destination: LoginFormView(userData: userData)) {
                    Text("Log in")
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(isHoveringLogin ? Color.lightBlue.opacity(90) : Color.lightBlue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .onHover { hovering in
                    isHoveringLogin = hovering
                }

                NavigationLink(destination: SignupFormView(userData: userData)) {
                    Text("Create Account")
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .opacity(isHoveringSignup ? 0.9 : 1.0)
                }
                .onHover { hovering in
                    isHoveringSignup = hovering
                }
            }
            .padding()
        }
    }
}

#Preview {
    LoginChoiceView(userData: UserData())
}
