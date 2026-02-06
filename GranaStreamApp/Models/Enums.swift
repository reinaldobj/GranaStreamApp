import Foundation

enum AccountType: Int, Codable, CaseIterable, Identifiable {
    case carteira = 1
    case contaCorrente = 2
    case contaPoupanca = 3

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .carteira: return "Carteira"
        case .contaCorrente: return "Conta Corrente"
        case .contaPoupanca: return "Conta Poupança"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self), let value = AccountType(rawValue: intValue) {
            self = value
            return
        }
        if let stringValue = try? container.decode(String.self) {
            if let value = AccountType.from(stringValue) {
                self = value
                return
            }
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid AccountType")
    }

    private static func from(_ value: String) -> AccountType? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "1", "carteira", "wallet": return .carteira
        case "2", "contacorrente", "conta_corrente", "conta corrente", "checking": return .contaCorrente
        case "3", "contapoupanca", "conta_poupanca", "conta poupanca", "savings": return .contaPoupanca
        default: return nil
        }
    }
}

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

enum UserStatus: Int, Codable, CaseIterable, Identifiable {
    case unverified = 0
    case active = 1
    case blocked = 2

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .unverified: return "Não verificado"
        case .active: return "Ativo"
        case .blocked: return "Bloqueado"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self), let value = UserStatus(rawValue: intValue) {
            self = value
            return
        }
        if let stringValue = try? container.decode(String.self) {
            if let value = UserStatus.from(stringValue) {
                self = value
                return
            }
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid UserStatus")
    }

    private static func from(_ value: String) -> UserStatus? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "0", "unverified", "nao verificado", "não verificado": return .unverified
        case "1", "active", "ativo": return .active
        case "2", "blocked", "bloqueado": return .blocked
        default: return nil
        }
    }
}
