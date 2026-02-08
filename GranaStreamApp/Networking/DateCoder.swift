import Foundation

enum DateCoder {
    static func decode(_ decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)

        let formatterWithFraction = makeFormatterWithFraction()
        let formatterNoFraction = makeFormatterNoFraction()
        let noTimeZoneFormatters = makeNoTimeZoneFormatters()

        if let date = formatterWithFraction.date(from: value) {
            return date
        }
        if let date = formatterNoFraction.date(from: value) {
            return date
        }
        if let trimmed = trimFraction(value, maxDigits: 6),
           let date = formatterWithFraction.date(from: trimmed) {
            return date
        }
        if let trimmed = trimFraction(value, maxDigits: 3),
           let date = formatterWithFraction.date(from: trimmed) {
            return date
        }
        if let date = parseNoTimeZone(value, formatters: noTimeZoneFormatters) {
            return date
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(value)")
    }

    static func encode(_ date: Date, encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let value = makeFormatterWithFraction().string(from: date)
        try container.encode(value)
    }

    static func string(from date: Date) -> String {
        makeFormatterWithFraction().string(from: date)
    }

    static func parseDate(_ value: String) -> Date? {
        let formatterWithFraction = makeFormatterWithFraction()
        let formatterNoFraction = makeFormatterNoFraction()
        let noTimeZoneFormatters = makeNoTimeZoneFormatters()

        if let date = formatterWithFraction.date(from: value) {
            return date
        }
        if let date = formatterNoFraction.date(from: value) {
            return date
        }
        if let trimmed = trimFraction(value, maxDigits: 6),
           let date = formatterWithFraction.date(from: trimmed) {
            return date
        }
        if let trimmed = trimFraction(value, maxDigits: 3),
           let date = formatterWithFraction.date(from: trimmed) {
            return date
        }
        return parseNoTimeZone(value, formatters: noTimeZoneFormatters)
    }

    private static func trimFraction(_ value: String, maxDigits: Int) -> String? {
        guard let dotIndex = value.firstIndex(of: ".") else { return nil }

        let afterDot = value.index(after: dotIndex)
        let fractionEnd = value[afterDot...].firstIndex(where: { $0 == "Z" || $0 == "+" || $0 == "-" }) ?? value.endIndex
        let fraction = value[afterDot..<fractionEnd]

        guard fraction.count > maxDigits else { return nil }

        let trimmedFraction = fraction.prefix(maxDigits)
        return String(value[..<afterDot]) + trimmedFraction + value[fractionEnd...]
    }

    private static func parseNoTimeZone(_ value: String, formatters: [DateFormatter]) -> Date? {
        guard let tIndex = value.firstIndex(of: "T") else { return nil }
        let timePortion = value[tIndex...]
        if timePortion.contains("Z") || timePortion.contains("+") {
            return nil
        }
        if let tzMinusIndex = timePortion.dropFirst().firstIndex(of: "-") {
            _ = tzMinusIndex
            return nil
        }

        for formatter in formatters {
            if let digits = fractionDigits(for: formatter.dateFormat),
               let normalized = trimFraction(value, maxDigits: digits),
               let date = formatter.date(from: normalized) {
                return date
            }
            if let date = formatter.date(from: value) {
                return date
            }
        }
        return nil
    }

    private static func makeFormatterWithFraction() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }

    private static func makeFormatterNoFraction() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }

    private static func makeNoTimeZoneFormatters() -> [DateFormatter] {
        func makeFormatter(_ format: String) -> DateFormatter {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone.current
            formatter.dateFormat = format
            return formatter
        }

        return [
            makeFormatter("yyyy-MM-dd'T'HH:mm:ss.SSSSSSS"),
            makeFormatter("yyyy-MM-dd'T'HH:mm:ss.SSSSSS"),
            makeFormatter("yyyy-MM-dd'T'HH:mm:ss.SSS"),
            makeFormatter("yyyy-MM-dd'T'HH:mm:ss")
        ]
    }

    private static func fractionDigits(for format: String) -> Int? {
        guard let range = format.range(of: ".") else { return nil }
        let fraction = format[range.upperBound...].prefix { $0 == "S" }
        return fraction.isEmpty ? nil : fraction.count
    }
}
