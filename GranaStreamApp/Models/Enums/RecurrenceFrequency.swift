import Foundation

/// Frequência de recorrência (Semanal, Quinzenal, Mensal)
enum RecurrenceFrequency: Int, Codable, CaseIterable, Identifiable {
    case weekly = 1
    case biweekly = 2
    case monthly = 3

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .weekly: return "Semanal"
        case .biweekly: return "Quinzenal"
        case .monthly: return "Mensal"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self), let value = RecurrenceFrequency(rawValue: intValue) {
            self = value
            return
        }
        if let stringValue = try? container.decode(String.self) {
            if let value = RecurrenceFrequency.from(stringValue) {
                self = value
                return
            }
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid RecurrenceFrequency")
    }

    private static func from(_ value: String) -> RecurrenceFrequency? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "1", "weekly", "semanal": return .weekly
        case "2", "biweekly", "quinzenal": return .biweekly
        case "3", "monthly", "mensal": return .monthly
        default: return nil
        }
    }
}
