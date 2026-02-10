import Foundation

/// Repositório central de formatadores reutilizáveis por thread.
/// Isso evita recriar formatadores pesados em loops e digitação.
enum FormatterPool {
    private enum Key {
        nonisolated static let iso8601WithFraction = "grana.formatter.iso8601.withFraction"
        nonisolated static let iso8601WithoutFraction = "grana.formatter.iso8601.withoutFraction"
        nonisolated static let brlCurrency = "grana.formatter.number.brl.currency"
        nonisolated static let brlDecimalInteger = "grana.formatter.number.brl.decimal.integer"
        nonisolated static let brlDecimalTwo = "grana.formatter.number.brl.decimal.two"
        nonisolated static let monthUTC = "grana.formatter.date.month.utc"
        nonisolated static let monthStartUTC = "grana.formatter.date.monthStart.utc"
    }

    nonisolated private static func threadLocal<T: AnyObject>(key: String, create: () -> T) -> T {
        let dictionary = Thread.current.threadDictionary
        if let existing = dictionary[key] as? T {
            return existing
        }

        let formatter = create()
        dictionary[key] = formatter
        return formatter
    }

    nonisolated static func iso8601WithFraction() -> ISO8601DateFormatter {
        threadLocal(key: Key.iso8601WithFraction) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return formatter
        }
    }

    nonisolated static func iso8601WithoutFraction() -> ISO8601DateFormatter {
        threadLocal(key: Key.iso8601WithoutFraction) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            return formatter
        }
    }

    nonisolated static func noTimeZoneDateFormatter(format: String) -> DateFormatter {
        threadLocal(key: "grana.formatter.date.noTimezone.\(format)") {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone.current
            formatter.dateFormat = format
            return formatter
        }
    }

    nonisolated static func monthFormatterUTC() -> DateFormatter {
        threadLocal(key: Key.monthUTC) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM"
            return formatter
        }
    }

    nonisolated static func monthStartFormatterUTC() -> DateFormatter {
        threadLocal(key: Key.monthStartUTC) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter
        }
    }

    nonisolated static func brlCurrencyFormatter() -> NumberFormatter {
        threadLocal(key: Key.brlCurrency) {
            let formatter = NumberFormatter()
            formatter.locale = Locale(identifier: "pt_BR")
            formatter.numberStyle = .currency
            formatter.currencyCode = "BRL"
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2
            return formatter
        }
    }

    nonisolated static func brlDecimalIntegerFormatter() -> NumberFormatter {
        threadLocal(key: Key.brlDecimalInteger) {
            let formatter = NumberFormatter()
            formatter.locale = Locale(identifier: "pt_BR")
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
            return formatter
        }
    }

    nonisolated static func brlDecimalTwoFormatter() -> NumberFormatter {
        threadLocal(key: Key.brlDecimalTwo) {
            let formatter = NumberFormatter()
            formatter.locale = Locale(identifier: "pt_BR")
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            return formatter
        }
    }
}
