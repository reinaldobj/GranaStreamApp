import Foundation
import SwiftUI

/// Helper para validação de campos comuns em formulários
struct FormValidationHelper {
    
    // MARK: - Email Validation
    
    /// Valida formato de email
    static func isValidEmail(_ email: String) -> Bool {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty else { return false }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - Password Validation
    
    /// Valida força de senha
    /// - Mínimo 8 caracteres
    /// - Pelo menos 1 letra maiúscula
    /// - Pelo menos 1 letra minúscula
    /// - Pelo menos 1 número
    static func isValidPassword(_ password: String) -> Bool {
        let password = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard password.count >= 8 else { return false }
        
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        
        return hasUppercase && hasLowercase && hasNumber
    }
    
    /// Valida força de senha com requisitos customizados
    static func passwordStrength(_ password: String) -> PasswordStrength {
        let password = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard password.count >= 8 else { return .weak }
        
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecial = password.range(of: "[!@#$%^&*()_+\\-=\\[\\]{};:'\",.<>?/\\\\|`~]", options: .regularExpression) != nil
        
        let strengthScore = [hasUppercase, hasLowercase, hasNumber, hasSpecial]
            .filter { $0 }
            .count
        
        switch strengthScore {
        case 3...: return .strong
        case 2: return .medium
        default: return .weak
        }
    }
    
    // MARK: - Name Validation
    
    /// Valida nome (mínimo 2 caracteres)
    static func isValidName(_ name: String) -> Bool {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.count >= 2 && name.count <= 100
    }
    
    // MARK: - Text Field Validation
    
    /// Valida se um campo de texto está vazio
    static func isNotEmpty(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Valida comprimento mínimo
    static func hasMinimumLength(_ text: String, length: Int) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).count >= length
    }
    
    /// Valida comprimento máximo
    static func hasMaximumLength(_ text: String, length: Int) -> Bool {
        text.count <= length
    }
    
    // MARK: - Number Validation
    
    /// Valida se string é número válido
    static func isValidNumber(_ text: String) -> Bool {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return false }
        return Double(text) != nil
    }
    
    /// Valida se número é positivo
    static func isPositiveNumber(_ text: String) -> Bool {
        guard let number = Double(text) else { return false }
        return number > 0
    }
    
    /// Valida se número está dentro de intervalo
    static func isInRange(_ text: String, min: Double, max: Double) -> Bool {
        guard let number = Double(text) else { return false }
        return number >= min && number <= max
    }
    
    // MARK: - Date Validation
    
    /// Valida se data é no futuro
    static func isFutureDate(_ date: Date) -> Bool {
        date > Date()
    }
    
    /// Valida se data é no passado
    static func isPastDate(_ date: Date) -> Bool {
        date < Date()
    }
    
    /// Valida se data está dentro de intervalo
    static func isInDateRange(_ date: Date, from: Date, to: Date) -> Bool {
        date >= from && date <= to
    }
}

// MARK: - Password Strength Enum

enum PasswordStrength {
    case weak
    case medium
    case strong
    
    var description: String {
        switch self {
        case .weak: return "Fraca"
        case .medium: return "Média"
        case .strong: return "Forte"
        }
    }
    
    var color: Color {
        switch self {
        case .weak: return DS.Colors.error
        case .medium: return DS.Colors.warning
        case .strong: return DS.Colors.success
        }
    }
}
