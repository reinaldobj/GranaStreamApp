import Foundation
import LocalAuthentication

/// Gerencia autenticação biométrica (Face ID / Touch ID)
@MainActor
final class BiometricAuthManager {
    
    var biometricDisplayName: String {
        switch biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "Face ID"
        @unknown default:
            return "Face ID"
        }
    }

    var biometricSystemImage: String {
        switch biometryType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        case .none:
            return "lock.shield"
        @unknown default:
            return "lock.shield"
        }
    }

    var isAvailable: Bool {
        biometryType != .none
    }
    
    private var biometryType: LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }
    
    /// Tenta autenticar o usuário com biometria
    func authenticate() async throws -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Agora não"

        var canEvaluateError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &canEvaluateError) else {
            throw BiometricAuthError.notAvailable
        }

        return try await context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "Confirme sua identidade para acessar seus dados financeiros."
        )
    }
    
    /// Converte erro do LAContext em mensagem amigável
    func errorMessage(for error: Error) -> String? {
        guard let localAuthError = error as? LAError else {
            return "Não foi possível validar sua identidade. Tente novamente."
        }

        switch localAuthError.code {
        case .userCancel, .systemCancel, .appCancel:
            return nil
        case .authenticationFailed:
            return "Não foi possível confirmar sua identidade. Tente novamente."
        case .biometryLockout:
            return "Face ID indisponível no momento. Use o código do iPhone."
        case .biometryNotEnrolled:
            return "Ative o Face ID nas configurações do iPhone para usar esta proteção."
        case .biometryNotAvailable:
            return "Este aparelho não oferece Face ID ou Touch ID no momento."
        case .passcodeNotSet:
            return "Defina um código no iPhone para usar esta proteção."
        default:
            return "Não foi possível validar sua identidade. Tente novamente."
        }
    }
}

enum BiometricAuthError: Error {
    case notAvailable
}
