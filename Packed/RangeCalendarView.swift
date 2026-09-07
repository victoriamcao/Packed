//
//  RangeCalendarView.swift
//  Packed
//
//  A simple tap-to-select date range calendar: the first tap sets the
//  start date, the second tap sets the end date and everything between
//  is selected automatically - no need to tap every day of a long trip.
//  Tapping again after a range is complete starts a fresh selection.
//

import SwiftUI

struct RangeCalendarView: View {
    @Binding var startDate: Date?
    @Binding var endDate: Date?

    @State private var displayedMonth: Date

    private let calendar = Calendar.current

    init(startDate: Binding<Date?>, endDate: Binding<Date?>) {
        _startDate = startDate
        _endDate = endDate
        _displayedMonth = State(initialValue: startDate.wrappedValue ?? Date())
    }

    var body: some View {
        VStack(spacing: 10) {
            header
            weekdayHeader
            dayGrid
        }
    }

    private var header: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(monthTitle)
                .font(.subheadline.bold())
            Spacer()
            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .foregroundColor(Color("lightBlue"))
        .padding(.horizontal, 4)
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    /// Weekday symbols rotated so they line up with the day grid's columns,
    /// which are laid out starting from calendar.firstWeekday (locale-
    /// dependent) - the raw symbol array is always Sunday-first.
    private var orderedWeekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let offset = calendar.firstWeekday - 1
        return Array(symbols[offset...] + symbols[..<offset])
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(Array(orderedWeekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol.uppercased())
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var dayGrid: some View {
        let days = daysInMonthGrid()
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
            ForEach(days.indices, id: \.self) { index in
                if let date = days[index] {
                    dayCell(for: date)
                } else {
                    Color.clear.frame(height: 30)
                }
            }
        }
    }

    private func dayCell(for date: Date) -> some View {
        let isStart = startDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let isEnd = endDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let inRange = isDateInRange(date)
        let isToday = calendar.isDateInToday(date)

        return Button {
            handleTap(date)
        } label: {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 14))
                .foregroundColor(isStart || isEnd ? .white : .primary)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(isStart || isEnd ? Color("lightBlue") : (inRange ? Color("lightBlue").opacity(0.25) : Color.clear))
                )
                .overlay(
                    Circle()
                        .stroke(Color("lightBlue"), lineWidth: (isToday && !isStart && !isEnd) ? 1 : 0)
                )
        }
        .buttonStyle(.plain)
    }

    private func isDateInRange(_ date: Date) -> Bool {
        guard let start = startDate, let end = endDate else { return false }
        return date > start && date < end
    }

    private func handleTap(_ date: Date) {
        if startDate == nil || endDate != nil {
            // No selection yet, or a range was already completed - start fresh.
            startDate = date
            endDate = nil
        } else if let start = startDate {
            if date < start {
                endDate = start
                startDate = date
            } else {
                endDate = date
            }
        }
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    /// Returns a 7-per-row grid of dates for the displayed month, with nil
    /// for the leading/trailing blanks outside the month.
    private func daysInMonthGrid() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else {
            return []
        }
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let leadingBlanks = (firstWeekday - calendar.firstWeekday + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)

        var current = monthInterval.start
        while current < monthInterval.end {
            days.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }
}
