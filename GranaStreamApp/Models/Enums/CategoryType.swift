import Foundation

/// Tipo de categoria (Receita, Despesa, Ambas)
enum CategoryType: Int, Codable, CaseIterable, Identifiable {
    case income = 1
    case expense = 2
    case both = 3

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .income: return "Receita"
        case .expense: return "Despesa"
        case .both: return "Ambas"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self), let value = CategoryType(rawValue: intValue) {
            self = value
            return
        }
        if let stringValue = try? container.decode(String.self) {
            if let value = CategoryType.from(stringValue) {
                self = value
                return
            }
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid CategoryType")
    }

    private static func from(_ value: String) -> CategoryType? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "1", "income", "receita": return .income
        case "2", "expense", "despesa": return .expense
        case "3", "both", "ambas": return .both
        default: return nil
        }
    }
}

extension CategoryType {
    static func fromServerString(_ value: String) -> CategoryType? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return from(normalized)
    }
}
