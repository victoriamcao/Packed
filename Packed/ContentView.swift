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
        .onAppear {
            Task { await loadHomeDataIfNeeded() }
        }
        .onChange(of: userData.isLoggedIn) { _, isLoggedIn in
            if isLoggedIn {
                Task { await loadHomeDataIfNeeded() }
            }
        }
    }

    private func loadHomeDataIfNeeded() async {
        guard let token = try? await userData.validAccessToken(), let uid = userData.currentUserId else { return }
        await savedLists.loadFromStorage(userId: uid, accessToken: token)
    }

    /// Trips with a travel date today or later, soonest first.
    private var upcomingTrips: [SavedLists.PackingList] {
        let today = Calendar.current.startOfDay(for: Date())
        return savedLists.lists
            .filter { list in
                guard let date = list.travelDate else { return false }
                return date >= today
            }
            .sorted { ($0.travelDate ?? .distantFuture) < ($1.travelDate ?? .distantFuture) }
    }

    private var homeContent: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 18) {
                Text("PACKED")
                    .font(.largeTitle)
                    .fontWeight(.medium)
                    .foregroundColor(Color("darkBlue"))
                    .padding(.top, 24)

                upcomingTripsSection

                VStack(spacing: 12) {
                    Button {
                        navigator.push(.survey)
                    } label: {
                        Text("Create Packing List")
                            .font(.title2)
                            .foregroundColor(Color.white)
                    }
                    .frame(maxWidth: 350, minHeight: 70)
                    .background(Color("lightBlue"))
                    .cornerRadius(24)

                    Button {
                        navigator.push(.pastLists)
                    } label: {
                        Text("View Past Lists")
                            .foregroundColor(Color("textGray"))
                    }
                    .frame(maxWidth: 350, minHeight: 46)
                    .background(Color("buttonGray"))
                    .cornerRadius(18)
                }

                Spacer(minLength: 0)

                Image("plane 1")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 220)
                    .rotationEffect(.degrees(-8))
                    .opacity(0.9)
            }
            .padding(.horizontal)
            .padding(.bottom, 74)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            BottomNavBar(current: .home)
        }
        .background(Color("appBackground").ignoresSafeArea())
    }

    private var upcomingTripsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("UPCOMING TRIPS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color("textGray"))
                .padding(.horizontal, 4)

            if !userData.isLoggedIn {
                emptyStateRow(icon: "airplane", message: "Log in to see your upcoming trips")
            } else if upcomingTrips.isEmpty {
                emptyStateRow(icon: "airplane.departure", message: "No upcoming trips yet - create one below!")
            } else {
                VStack(spacing: 8) {
                    ForEach(upcomingTrips.prefix(2)) { trip in
                        Button {
                            navigator.push(.listDetail(trip))
                        } label: {
                            upcomingTripCard(trip)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: 350)
    }

    private func upcomingTripCard(_ trip: SavedLists.PackingList) -> some View {
        HStack(spacing: 14) {
            VStack(spacing: 0) {
                Text(monthAbbreviation(trip.travelDate))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text(dayNumber(trip.travelDate))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .frame(width: 48, height: 48)
            .background(Color("lightBlue"))
            .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(trip.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text("\(relativeDayLabel(trip.travelDate)) • \(trip.items.count) items")
                    .font(.caption)
                    .foregroundColor(Color("textGray"))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color("textGray"))
        }
        .padding(12)
        .background(Color("buttonGray"))
        .cornerRadius(12)
    }

    private func emptyStateRow(icon: String, message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color("lightBlue"))
            Text(message)
                .font(.subheadline)
                .foregroundColor(Color("textGray"))
            Spacer()
        }
        .padding(14)
        .background(Color("buttonGray"))
        .cornerRadius(12)
    }

    private func monthAbbreviation(_ date: Date?) -> String {
        guard let date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date).uppercased()
    }

    private func dayNumber(_ date: Date?) -> String {
        guard let date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private func relativeDayLabel(_ date: Date?) -> String {
        guard let date else { return "" }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: date)
        ).day ?? 0
        if days > 0 && days <= 30 {
            return "In \(days) days"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
#Preview {
    ContentView()
}
