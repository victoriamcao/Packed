//
//  SurveryPage.swift
//  Packed
//
//  Created by Scholar on 7/29/25.
//

import SwiftUI

struct SurveryPage: View {
    @EnvironmentObject var navigator: AppNavigator

    @State private var selectedType = "Tropical Vacation"
    @State private var selectedGender = "I prefer not to say"
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
                    .foregroundColor(Color(red: 0.195, green: 0.648, blue: 0.859))
                    .padding(.bottom, 8.0)

                // Type of Vacation button
                Text("TYPE OF VACATION")
                    .font(.caption)
                    .foregroundColor(Color(red: 0.561, green: 0.557, blue: 0.557))
                Menu {
                    Button(action: { selectedType = "Tropical Vacation" }) {
                        Text("Tropical Vacation")
                    }
                    Button(action: { selectedType = "Mountain Vacation" }) {
                        Text("Mountain Vacation")
                    }
                    Button(action: { selectedType = "Ski Trip" }) {
                        Text("Ski Trip")
                    }
                    Button(action: { selectedType = "City Vacation" }) {
                        Text("City Vacation")
                    }
                    Button(action: { selectedType = "Business Trip" }) {
                        Text("Business Trip")
                    }
                } label: {
                    ZStack {
                        Rectangle()
                            .foregroundColor(Color("buttonGray"))
                            .frame(width: 350, height: 44)
                            .cornerRadius(10)

                        Label(
                            title: {Text(selectedType)
                                .foregroundColor(Color(red: 0.561, green: 0.561, blue: 0.561))
                                .padding(.all)},
                            icon: {Image("arrow")
                                .resizable()
                                .frame(width: 30, height: 24)
                            }
                        )
                    }
                }
                .padding(.bottom, 6)

                // Destination field (used to look up real weather for the trip)
                Text("DESTINATION")
                    .font(.caption)
                    .foregroundColor(Color(red: 0.561, green: 0.557, blue: 0.557))
                ZStack {
                    Rectangle()
                        .foregroundColor(Color("buttonGray"))
                        .frame(width: 350, height: 44)
                        .cornerRadius(10)
                    TextField("City, Country", text: $destination)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .autocorrectionDisabled()
                        .frame(width: 350)
                }
                .padding(.bottom, 6)

                // Trip dates - tap a start day, then an end day; everything
                // between is selected automatically. The destination's real
                // weather (fetched separately) replaces the need to manually
                // pick a weather condition here.
                Text("TRIP DATES")
                    .font(.caption)
                    .foregroundColor(Color(red: 0.561, green: 0.557, blue: 0.557))
                RangeCalendarView(startDate: $tripStartDate, endDate: $tripEndDate)
                    .frame(width: 350)
                Text(tripDatesSummary)
                    .font(.caption)
                    .foregroundColor(Color(red: 0.561, green: 0.557, blue: 0.557))
                    .padding(.bottom, 4)

                // Gender button
                Text("GENDER")
                    .font(.caption)
                    .foregroundColor(Color(red: 0.561, green: 0.557, blue: 0.557))
                Menu {
                    Button(action: { selectedGender = "I prefer not to say" }) {
                        Text("I prefer not to say")
                    }
                    Button(action: { selectedGender = "Male" }) {
                        Text("Male")
                    }
                    Button(action: { selectedGender = "Female" }) {
                        Text("Female")
                    }
                } label: {
                    ZStack {
                        Rectangle()
                            .foregroundColor(Color("buttonGray"))
                            .frame(width: 350, height: 44)
                            .cornerRadius(10)

                        Label(
                            title: {Text(selectedGender)
                                .foregroundColor(Color(red: 0.561, green: 0.561, blue: 0.561))
                                .padding(.all)},
                            icon: {Image("arrow")
                                .resizable()
                                .frame(width: 30, height: 24)
                            }
                        )
                    }
                }

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
                    ZStack {
                        Rectangle()
                            .foregroundColor(Color("lightBlue"))
                            .frame(width: 350, height: 46)
                            .cornerRadius(10)
                        Text("Create")
                            .font(.title3)
                            .foregroundColor(Color.white)
                    }
                }
                .padding(.top, 10)
            }
            .padding(.bottom, 70)
            .frame(maxHeight: .infinity, alignment: .top)

            BottomNavBar(current: .home)
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SurveryPage(savedLists: SavedLists())
        .environmentObject(AppNavigator())
        .environmentObject(UserData())
}
