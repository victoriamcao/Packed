//
//  ContentView.swift
//  Packed
//
//
import SwiftUI
struct ContentView: View {
    @StateObject var savedLists = SavedLists()
    @StateObject var userData = UserData()
    @StateObject var navigator = AppNavigator()

    var body: some View {
        NavigationStack(path: $navigator.path) {
            homeContent
                .navigationDestination(for: AppDestination.self) { destination in
                    switch destination {
                    case .survey:
                        SurveryPage(savedLists: savedLists)
                    case .pastLists:
                        PastLists(savedLists: savedLists)
                    case .map:
                        MapPage()
                    case .profile:
                        ProfileView(userData: userData)
                    case .loginChoice:
                        LoginChoiceView(userData: userData)
                    case .listPage(let params):
                        ListPage(
                            selectedType: params.selectedType,
                            selectedGender: params.selectedGender,
                            selectedWeather: params.selectedWeather,
                            selectedLength: params.selectedLength,
                            destination: params.destination,
                            travelDate: params.travelDate,
                            savedLists: savedLists
                        )
                    case .listDetail(let list):
                        ListDetailView(list: list, savedLists: savedLists)
                    case .login:
                        LoginFormView(userData: userData)
                    case .signup:
                        SignupFormView(userData: userData)
                    case .changePassword:
                        ChangePasswordView(userData: userData)
                    case .apiKeySettings:
                        APIKeySettingsView()
                    }
                }
        }
        .environmentObject(navigator)
        .environmentObject(userData)
    }

    private var homeContent: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                Color.clear

                VStack {
                    Text("PACKED")
                        .font(.largeTitle)
                        .fontWeight(.medium)
                        .foregroundColor(Color("darkBlue"))
                        .offset(y: -100)

                    Button {
                        navigator.push(.survey)
                    } label: {
                        Text("Create Packing List")
                            .font(.title)
                            .foregroundColor(Color.white)
                    }
                    .frame(maxWidth: 350, minHeight: 80)
                    .background(Color("lightBlue"))
                    .cornerRadius(30)

                    Button {
                        navigator.push(.pastLists)
                    } label: {
                        Text("View Past Lists")
                            .foregroundColor(Color("textGray"))
                    }
                    .frame(maxWidth: 350, minHeight: 50)
                    .background(Color("buttonGray"))
                    .cornerRadius(20)
                }
                .padding()
                .padding(.horizontal)

                Image("plane 1")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 440)
                    .offset(y: 230)
                    .offset(x: -50)
                    .rotationEffect(.degrees(-8))
            }

            BottomNavBar(current: .home)
        }
    }
}
#Preview {
    ContentView()
}
