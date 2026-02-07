import SwiftUI
import Combine
import LocalAuthentication

@MainActor
final class AppLockService: ObservableObject {
    static let shared = AppLockService()

    @Published private(set) var isBiometricLockEnabled: Bool
    @Published private(set) var isLocked: Bool
    @Published private(set) var isPrivacyMaskVisible: Bool = false
    @Published private(set) var shouldShowEnablePrompt: Bool = false
    @Published private(set) var lastUnlockErrorMessage: String?
    @Published private(set) var isUnlocking: Bool = false

    var biometricDisplayName: String {
        switch currentBiometryType() {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .none:
            return "Face ID"
        @unknown default:
            return "Face ID"
        }
    }

    var biometricSystemImage: String {
        switch currentBiometryType() {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .none:
            return "lock.shield"
        @unknown default:
            return "lock.shield"
        }
    }

    var isBiometricOptionAvailable: Bool {
        currentBiometryType() != .none
    }

    private let defaults: UserDefaults
    private let isBiometricLockEnabledKey = "gs_biometric_lock_enabled"
    private let biometricPromptSeenKey = "gs_biometric_prompt_seen"
    private let lockDelay: TimeInterval = 15

    private var backgroundEnteredAt: Date?
    private var previousAuthenticationState: Bool

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let initialBiometricEnabled = defaults.bool(forKey: isBiometricLockEnabledKey)
        self.isBiometricLockEnabled = initialBiometricEnabled

        let isAuthenticated = SessionStore.shared.isAuthenticated
        self.isLocked = isAuthenticated && initialBiometricEnabled
        self.previousAuthenticationState = isAuthenticated

        updatePromptState(isAuthenticated: isAuthenticated)
    }

    func handleScenePhaseChange(_ phase: ScenePhase) {
        let isAuthenticated = SessionStore.shared.isAuthenticated

        switch phase {
        case .active:
            isPrivacyMaskVisible = false
            guard isAuthenticated else { return }

            if isBiometricLockEnabled,
               let backgroundEnteredAt,
               Date().timeIntervalSince(backgroundEnteredAt) >= lockDelay {
                isLocked = true
            }
            self.backgroundEnteredAt = nil
        case .inactive:
            if isAuthenticated {
                isPrivacyMaskVisible = true
            }
        case .background:
            if isAuthenticated {
                backgroundEnteredAt = Date()
                isPrivacyMaskVisible = true
            }
        @unknown default:
            break
        }
    }

    func syncAuthenticationState(isAuthenticated: Bool) {
        defer {
            previousAuthenticationState = isAuthenticated
        }

        guard isAuthenticated else {
            resetForLogout()
            return
        }

        isPrivacyMaskVisible = false
        lastUnlockErrorMessage = nil

        if !isBiometricLockEnabled {
            isLocked = false
        } else if previousAuthenticationState == false {
            isLocked = false
        }

        updatePromptState(isAuthenticated: true)
    }

    func attemptUnlock() async {
        guard SessionStore.shared.isAuthenticated else {
            isLocked = false
            return
        }

        guard isBiometricLockEnabled else {
            isLocked = false
            return
        }

        guard !isUnlocking else { return }

        let context = LAContext()
        context.localizedCancelTitle = "Agora não"

        var canEvaluateError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &canEvaluateError) else {
            isLocked = true
            lastUnlockErrorMessage = "Não foi possível pedir autenticação neste aparelho."
            return
        }

        isUnlocking = true
        lastUnlockErrorMessage = nil

        defer {
            isUnlocking = false
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Confirme sua identidade para acessar seus dados financeiros."
            )

            if success {
                isLocked = false
                lastUnlockErrorMessage = nil
            }
        } catch {
            isLocked = true
            lastUnlockErrorMessage = unlockErrorMessage(for: error)
        }
    }

    func enableBiometricLock() {
        guard isBiometricOptionAvailable else {
            lastUnlockErrorMessage = "Este aparelho não oferece Face ID ou Touch ID no momento."
            return
        }

        isBiometricLockEnabled = true
        defaults.set(true, forKey: isBiometricLockEnabledKey)
        markPromptAsHandled()
        lastUnlockErrorMessage = nil
    }

    func disableBiometricLock() {
        isBiometricLockEnabled = false
        defaults.set(false, forKey: isBiometricLockEnabledKey)

        isLocked = false
        backgroundEnteredAt = nil
        lastUnlockErrorMessage = nil
        markPromptAsHandled()
    }

    func markPromptAsHandled() {
        defaults.set(true, forKey: biometricPromptSeenKey)
        shouldShowEnablePrompt = false
    }

    func resetForLogout() {
        isLocked = false
        isPrivacyMaskVisible = false
        shouldShowEnablePrompt = false
        lastUnlockErrorMessage = nil
        backgroundEnteredAt = nil
        previousAuthenticationState = false
    }

    private func updatePromptState(isAuthenticated: Bool) {
        let promptWasSeen = defaults.bool(forKey: biometricPromptSeenKey)
        shouldShowEnablePrompt = isAuthenticated
            && !promptWasSeen
            && !isBiometricLockEnabled
            && isBiometricOptionAvailable
    }

    private func currentBiometryType() -> LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }

    private func unlockErrorMessage(for error: Error) -> String? {
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
