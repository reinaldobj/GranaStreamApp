import Foundation

/// Status do usuário (Não verificado, Ativo, Bloqueado)
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
