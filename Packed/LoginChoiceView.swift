//
//  LoginChoiceView.swift
//  Packed
//
//  Created by Scholar on 7/30/25.
//

import SwiftUI

struct LoginChoiceView: View {
    @ObservedObject var userData: UserData
    @EnvironmentObject var navigator: AppNavigator
    @State private var isHoveringLogin = false
    @State private var isHoveringSignup = false

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 20) {
                Image("logo")
                    .resizable()
                    .frame(width: 200, height: 200)

                Text("Join us!")
                    .font(.largeTitle)
                    .bold()
                    .padding()

                Button {
                    navigator.push(.login)
                } label: {
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

                Button {
                    navigator.push(.signup)
                } label: {
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
            .padding(.bottom, 60)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            BottomNavBar(current: .profile)
        }
        .background(Color("appBackground").ignoresSafeArea())
    }
}

#Preview {
    LoginChoiceView(userData: UserData())
        .environmentObject(AppNavigator())
}
