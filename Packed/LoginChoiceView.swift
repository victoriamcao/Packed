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

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 20) {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 200, maxHeight: 200)
                    .accessibilityLabel("Packed logo")

                Text("Join us!")
                    .font(.largeTitle)
                    .bold()
                    .padding()
                    .accessibilityAddTraits(.isHeader)

                Text("Save your lists, get AI-personalized packing lists, and pin trip photos to your map.")
                    .font(.subheadline)
                    .foregroundColor(Color.textGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button {
                    navigator.push(.login)
                } label: {
                    Text("Log in")
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.lightBlue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
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
