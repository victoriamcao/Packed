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
    @ObservedObject var savedLists: SavedLists

    private var resolvedStartDate: Date { tripStartDate ?? Date() }

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
                        navigator.goBack()
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
                    navigator.push(.listPage(ListPageParams(
                        selectedType: selectedType,
                        selectedGender: selectedGender,
                        selectedWeather: fallbackWeatherLabel,
                        selectedLength: tripLengthDays,
                        destination: destination,
                        travelDate: resolvedStartDate
                    )))
                } label: {
                    Text("Create")
                        .font(.title3)
                        .foregroundColor(Color.white)
                        .frame(maxWidth: 350, minHeight: 46)
                        .background(Color("lightBlue"))
                        .cornerRadius(10)
                }
                .padding(.top, 10)

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
    }
}

#Preview {
    SurveyPage(savedLists: SavedLists())
        .environmentObject(AppNavigator())
        .environmentObject(UserData())
}
