import Foundation

/// Tipo de conta (Carteira, Conta Corrente, Poupança)
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
