//
//  BottomNavBar.swift
//  Packed
//
//  The app's persistent bottom navigation bar (Home / Map / Profile),
//  shared across every top-level screen so it's always available to
//  jump back Home or over to the map/profile, no matter how deep the
//  user has navigated.
//

import SwiftUI

enum AppTab {
    case home, map, profile
}

struct BottomNavBar: View {
    var current: AppTab
    @EnvironmentObject var navigator: AppNavigator
    @EnvironmentObject var userData: UserData

    var body: some View {
        HStack {
            Button {
                navigator.goHome()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 25))
                        .foregroundColor(current == .home ? .darkBlue : .textGray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Button {
                navigator.go(to: .map)
            } label: {
                VStack {
                    Image(systemName: "globe")
                        .font(.system(size: 25))
                        .foregroundColor(current == .map ? .darkBlue : .textGray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Button {
                navigator.go(to: userData.isLoggedIn ? .profile : .loginChoice)
            } label: {
                VStack {
                    Image(systemName: userData.isLoggedIn ? "person.circle.fill" : "person.crop.circle")
                        .font(.system(size: 25))
                        .foregroundColor(current == .profile ? .darkBlue : .textGray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
        .background(Color("appBackground"))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .top
        )
    }
}
