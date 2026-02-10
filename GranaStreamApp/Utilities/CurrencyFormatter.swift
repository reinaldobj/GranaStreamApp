import Foundation

enum CurrencyFormatter {
    static func string(from value: Double) -> String {
        FormatterPool.brlCurrencyFormatter().string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}
