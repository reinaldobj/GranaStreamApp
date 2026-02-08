import Foundation

/// Tipo de transação (Receita, Despesa, Transferência)
enum TransactionType: Int, Codable, CaseIterable, Identifiable {
    case income = 1
    case expense = 2
    case transfer = 3

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .income: return "Receita"
        case .expense: return "Despesa"
        case .transfer: return "Transferência"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self), let value = TransactionType(rawValue: intValue) {
            self = value
            return
        }
        if let stringValue = try? container.decode(String.self) {
            if let value = TransactionType.from(stringValue) {
                self = value
                return
            }
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid TransactionType")
    }

    private static func from(_ value: String) -> TransactionType? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "1", "income", "receita": return .income
        case "2", "expense", "despesa": return .expense
        case "3", "transfer", "transferencia", "transferência": return .transfer
        default: return nil
        }
    }
}

/// Tipo de fluxo (Débito, Crédito)
enum FlowType: Int, Codable, CaseIterable, Identifiable {
    case debit = 1
    case credit = 2

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .debit: return "Débito"
        case .credit: return "Crédito"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self), let value = FlowType(rawValue: intValue) {
            self = value
            return
        }
        if let stringValue = try? container.decode(String.self) {
            if let value = FlowType.from(stringValue) {
                self = value
                return
            }
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid FlowType")
    }

    private static func from(_ value: String) -> FlowType? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "1", "debit", "debito", "débito": return .debit
        case "2", "credit", "credito", "crédito": return .credit
        default: return nil
        }
    }
}
