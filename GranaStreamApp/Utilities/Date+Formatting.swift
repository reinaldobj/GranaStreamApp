import Foundation

extension Date {
    private static let appDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    func formattedDate() -> String {
        Date.appDateFormatter.string(from: self)
    }
}
