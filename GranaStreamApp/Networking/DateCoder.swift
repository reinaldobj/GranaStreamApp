import Foundation

enum DateCoder {
    static let formatterWithFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let formatterNoFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func decode(_ decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        if let date = formatterWithFraction.date(from: value) {
            return date
        }
        if let date = formatterNoFraction.date(from: value) {
            return date
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(value)")
    }

    static func encode(_ date: Date, encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let value = formatterWithFraction.string(from: date)
        try container.encode(value)
    }

    static func string(from date: Date) -> String {
        formatterWithFraction.string(from: date)
    }
}
