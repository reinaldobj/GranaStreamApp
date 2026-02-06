import Foundation

enum CurrencyFormatter {
    static let brl: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.numberStyle = .currency
        formatter.currencyCode = "BRL"
        return formatter
    }()

    static func string(from value: Double) -> String {
        brl.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}
