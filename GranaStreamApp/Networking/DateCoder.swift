import Foundation

enum DateCoder {
    nonisolated static func decode(_ decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)

        let formatterWithFraction = FormatterPool.iso8601WithFraction()
        let formatterNoFraction = FormatterPool.iso8601WithoutFraction()
        let noTimeZoneFormatters = noTimeZoneFormatters()

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

    nonisolated static func encode(_ date: Date, encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let value = FormatterPool.iso8601WithFraction().string(from: date)
        try container.encode(value)
    }

    nonisolated static func string(from date: Date) -> String {
        FormatterPool.iso8601WithFraction().string(from: date)
    }

    nonisolated static func parseDate(_ value: String) -> Date? {
        let formatterWithFraction = FormatterPool.iso8601WithFraction()
        let formatterNoFraction = FormatterPool.iso8601WithoutFraction()
        let noTimeZoneFormatters = noTimeZoneFormatters()

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

    nonisolated private static func trimFraction(_ value: String, maxDigits: Int) -> String? {
        guard let dotIndex = value.firstIndex(of: ".") else { return nil }

        let afterDot = value.index(after: dotIndex)
        let fractionEnd = value[afterDot...].firstIndex(where: { $0 == "Z" || $0 == "+" || $0 == "-" }) ?? value.endIndex
        let fraction = value[afterDot..<fractionEnd]

        guard fraction.count > maxDigits else { return nil }

        let trimmedFraction = fraction.prefix(maxDigits)
        return String(value[..<afterDot]) + trimmedFraction + value[fractionEnd...]
    }

    nonisolated private static func parseNoTimeZone(_ value: String, formatters: [DateFormatter]) -> Date? {
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

    nonisolated private static let noTimeZoneFormats: [String] = [
        "yyyy-MM-dd'T'HH:mm:ss.SSSSSSS",
        "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
        "yyyy-MM-dd'T'HH:mm:ss.SSS",
        "yyyy-MM-dd'T'HH:mm:ss"
    ]

    nonisolated private static func noTimeZoneFormatters() -> [DateFormatter] {
        noTimeZoneFormats.map { FormatterPool.noTimeZoneDateFormatter(format: $0) }
    }

    nonisolated private static func fractionDigits(for format: String) -> Int? {
        guard let range = format.range(of: ".") else { return nil }
        let fraction = format[range.upperBound...].prefix { $0 == "S" }
        return fraction.isEmpty ? nil : fraction.count
    }
}
