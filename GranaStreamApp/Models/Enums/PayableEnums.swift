import Foundation

/// Tipo de pendência (A pagar, A receber)
enum PayableKind: Int, Codable, CaseIterable, Identifiable {
    case payable = 1
    case receivable = 2

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .payable: return "A pagar"
        case .receivable: return "A receber"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self), let value = PayableKind(rawValue: intValue) {
            self = value
            return
        }
        if let stringValue = try? container.decode(String.self) {
            if let value = PayableKind.from(stringValue) {
                self = value
                return
            }
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid PayableKind")
    }

    private static func from(_ value: String) -> PayableKind? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "1", "payable", "a pagar": return .payable
        case "2", "receivable", "a receber": return .receivable
        default: return nil
        }
    }
}

/// Status de uma pendência (Pendente, Quitado, Cancelado)
enum PayableStatus: Int, Codable, CaseIterable, Identifiable {
    case pending = 1
    case settled = 2
    case canceled = 3

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .pending: return "Pendente"
        case .settled: return "Quitado"
        case .canceled: return "Cancelado"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self), let value = PayableStatus(rawValue: intValue) {
            self = value
            return
        }
        if let stringValue = try? container.decode(String.self) {
            if let value = PayableStatus.from(stringValue) {
                self = value
                return
            }
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid PayableStatus")
    }

    private static func from(_ value: String) -> PayableStatus? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "1", "pending", "pendente": return .pending
        case "2", "settled", "quitado": return .settled
        case "3", "canceled", "cancelled", "cancelado": return .canceled
        default: return nil
        }
    }
}
