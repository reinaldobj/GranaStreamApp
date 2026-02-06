import Foundation
import Combine

final class MonthFilterStore: ObservableObject {
    @Published var selectedMonth: Date

    private let calendar: Calendar
    private let formatter: DateFormatter

    init(now: Date = Date()) {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "pt_BR")
        self.calendar = calendar

        let start = MonthFilterStore.startOfMonth(for: now, calendar: calendar)
        self.selectedMonth = start

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "LLLL yyyy"
        self.formatter = formatter
    }

    var selectedMonthLabel: String {
        label(for: selectedMonth)
    }

    var monthsInYear: [Date] {
        let year = calendar.component(.year, from: selectedMonth)
        return (1...12).compactMap { month in
            calendar.date(from: DateComponents(year: year, month: month, day: 1))
        }
    }

    func select(month: Date) {
        selectedMonth = MonthFilterStore.startOfMonth(for: month, calendar: calendar)
    }

    func label(for date: Date) -> String {
        let text = formatter.string(from: date)
        guard let first = text.first else { return text }
        return String(first).uppercased() + text.dropFirst()
    }

    private static func startOfMonth(for date: Date, calendar: Calendar) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }
}
