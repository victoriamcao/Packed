//
//  SurveyPage.swift
//  Packed
//
//  Created by Scholar on 7/29/25.
//

import SwiftUI

private enum SurveyDropdown {
    case type, gender
}

struct SurveyPage: View {
    @EnvironmentObject var navigator: AppNavigator
    @EnvironmentObject var userData: UserData

    @State private var selectedType = "Tropical Vacation"
    @State private var selectedGender = "I prefer not to say"
    @State private var expandedDropdown: SurveyDropdown?
    @State private var destination: String = ""
    // Tap-to-select date range (e.g. Sep 3-7) replaces a separate
    // start-date + day-count picker. Starts nil so the very first tap on
    // the calendar is treated as "start a fresh selection" rather than
    // being read as setting an end date against a pre-seeded start.
    @State private var tripStartDate: Date?
    @State private var tripEndDate: Date?
    @State private var isCheckingDestination = false
    @State private var destinationErrorMessage: String?
    @ObservedObject var savedLists: SavedLists

    private var resolvedStartDate: Date { tripStartDate ?? Date() }

    private var trimmedDestination: String {
        destination.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var tripLengthDays: Int {
        guard let start = tripStartDate else { return 1 }
        let end = tripEndDate ?? start
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: start),
            to: Calendar.current.startOfDay(for: end)
        ).day ?? 0
        return max(1, days + 1)
    }

    private var tripDatesSummary: String {
        guard let start = tripStartDate else { return "Select trip dates" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        guard let end = tripEndDate, !Calendar.current.isDate(end, inSameDayAs: start) else {
            return "1 day • \(formatter.string(from: start))"
        }
        return "\(tripLengthDays) days • \(formatter.string(from: start)) - \(formatter.string(from: end))"
    }

    /// Only used as a last-resort fallback (no destination weather data AND
    /// the AI generator unavailable) - a trip-type-informed guess reads
    /// better than always assuming sunny, e.g. for a Ski Trip.
    private var fallbackWeatherLabel: String {
        switch selectedType {
        case "Ski Trip":
            return "Snowy"
        case "Mountain Vacation":
            return "Cold"
        case "Business Trip", "City Vacation":
            return "Cloudy"
        default:
            return "Sunny"
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
            VStack(spacing: 6) {
                HStack {
                    Button {
                        navigator.goHome()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(Color("lightBlue"))
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 12)

                Text("Create New List")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.lightBlue)
                    .padding(.bottom, 8.0)
                    .accessibilityAddTraits(.isHeader)

                // Type of Vacation button
                Text("TYPE OF VACATION")
                    .font(.caption)
                    .foregroundColor(Color.textGray)
                DropdownField(
                    options: ["Tropical Vacation", "Mountain Vacation", "Ski Trip", "City Vacation", "Business Trip"],
                    selection: $selectedType,
                    isExpanded: Binding(
                        get: { expandedDropdown == .type },
                        set: { expandedDropdown = $0 ? .type : nil }
                    ),
                    accessibilityTitle: "Type of vacation"
                )
                .padding(.bottom, 6)

                // Destination field (used to look up real weather for the trip)
                Text("DESTINATION")
                    .font(.caption)
                    .foregroundColor(Color.textGray)
                TextField("City, Country", text: $destination)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .autocorrectionDisabled()
                    .frame(maxWidth: 350, minHeight: 44)
                    .background(Color("buttonGray"))
                    .cornerRadius(10)
                    .accessibilityLabel("Destination")
                .padding(.bottom, 6)

                // Trip dates - tap a start day, then an end day; everything
                // between is selected automatically. The destination's real
                // weather (fetched separately) replaces the need to manually
                // pick a weather condition here.
                Text("TRIP DATES")
                    .font(.caption)
                    .foregroundColor(Color.textGray)
                RangeCalendarView(startDate: $tripStartDate, endDate: $tripEndDate)
                    .frame(maxWidth: 350)
                Text(tripDatesSummary)
                    .font(.caption)
                    .foregroundColor(Color.textGray)
                    .padding(.bottom, 4)

                // Gender button
                Text("GENDER")
                    .font(.caption)
                    .foregroundColor(Color.textGray)
                DropdownField(
                    options: ["I prefer not to say", "Male", "Female"],
                    selection: $selectedGender,
                    isExpanded: Binding(
                        get: { expandedDropdown == .gender },
                        set: { expandedDropdown = $0 ? .gender : nil }
                    ),
                    accessibilityTitle: "Gender"
                )

                Button {
                    createList()
                } label: {
                    Text(isCheckingDestination ? "Checking destination..." : "Create")
                        .font(.title3)
                        .foregroundColor(Color.white)
                        .frame(maxWidth: 350, minHeight: 46)
                        .background(trimmedDestination.isEmpty ? Color.gray : Color("lightBlue"))
                        .cornerRadius(10)
                }
                .disabled(trimmedDestination.isEmpty || isCheckingDestination)
                .padding(.top, 10)

                if trimmedDestination.isEmpty {
                    Text("Enter a destination so your list can be based on real weather there.")
                        .font(.caption)
                        .foregroundColor(Color.textGray)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }

                Text(userData.isLoggedIn
                     ? "✨ Your list will be AI-personalized for your destination and weather."
                     : "Log in to get an AI-personalized list for your destination and weather.")
                    .font(.caption)
                    .foregroundColor(Color.textGray)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding(.horizontal)
            .padding(.bottom, 70)
            }
            .frame(maxHeight: .infinity, alignment: .top)

            BottomNavBar(current: .home)
        }
        .background(Color("appBackground").ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .alert("Couldn't find that destination", isPresented: Binding(
            get: { destinationErrorMessage != nil },
            set: { if !$0 { destinationErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(destinationErrorMessage ?? "")
        }
    }

    /// Confirms the destination actually resolves to a real place before
    /// moving on, so the packing list is always built from real weather
    /// instead of silently falling back to the trip-type guess.
    private func createList() {
        isCheckingDestination = true
        Task {
            do {
                _ = try await WeatherService.geocode(place: trimmedDestination)
                isCheckingDestination = false
                navigator.push(.listPage(ListPageParams(
                    selectedType: selectedType,
                    selectedGender: selectedGender,
                    selectedWeather: fallbackWeatherLabel,
                    selectedLength: tripLengthDays,
                    destination: trimmedDestination,
                    travelDate: resolvedStartDate
                )))
            } catch {
                isCheckingDestination = false
                destinationErrorMessage = "Couldn't find \"\(trimmedDestination)\". Check the spelling and try again."
            }
        }
    }
}

#Preview {
    SurveyPage(savedLists: SavedLists())
        .environmentObject(AppNavigator())
        .environmentObject(UserData())
}
