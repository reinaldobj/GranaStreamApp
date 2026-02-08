import SwiftUI
import Combine

/// Coordena autenticação biométrica e estado de bloqueio da aplicação
@MainActor
final class AppLockService: ObservableObject {
    static let shared = AppLockService()

    // MARK: - Published Properties
    
    @Published private(set) var isBiometricLockEnabled: Bool
    @Published private(set) var shouldShowEnablePrompt: Bool = false
    @Published private(set) var lastUnlockErrorMessage: String?
    @Published private(set) var isUnlocking: Bool = false
    
    // Delegates from LockStateManager
    var isLocked: Bool { lockStateManager.isLocked }
    var isPrivacyMaskVisible: Bool { lockStateManager.isPrivacyMaskVisible }
    
    // Delegates from BiometricAuthManager
    var biometricDisplayName: String { biometricAuthManager.biometricDisplayName }
    var biometricSystemImage: String { biometricAuthManager.biometricSystemImage }
    var isBiometricOptionAvailable: Bool { biometricAuthManager.isAvailable }

    // MARK: - Dependencies
    
    private let lockStateManager: LockStateManager
    private let biometricAuthManager: BiometricAuthManager
    private let defaults: UserDefaults
    
    private let isBiometricLockEnabledKey = "gs_biometric_lock_enabled"
    private let biometricPromptSeenKey = "gs_biometric_prompt_seen"
    
    private var previousAuthenticationState: Bool

    // MARK: - Initialization
    
    init(
        lockStateManager: LockStateManager? = nil,
        biometricAuthManager: BiometricAuthManager? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.lockStateManager = lockStateManager ?? LockStateManager()
        self.biometricAuthManager = biometricAuthManager ?? BiometricAuthManager()
        self.defaults = defaults
        
        let initialBiometricEnabled = defaults.bool(forKey: isBiometricLockEnabledKey)
        self.isBiometricLockEnabled = initialBiometricEnabled

        let isAuthenticated = SessionStore.shared.isAuthenticated
        
        if isAuthenticated && initialBiometricEnabled {
            self.lockStateManager.lock()
        }
        
        self.previousAuthenticationState = isAuthenticated
        updatePromptState(isAuthenticated: isAuthenticated)
    }

    // MARK: - Public Methods

    func handleScenePhaseChange(_ phase: ScenePhase) {
        let isAuthenticated = SessionStore.shared.isAuthenticated
        lockStateManager.handleScenePhaseChange(
            phase,
            isAuthenticated: isAuthenticated,
            lockEnabled: isBiometricLockEnabled
        )
    }

    func syncAuthenticationState(isAuthenticated: Bool) {
        defer {
            previousAuthenticationState = isAuthenticated
        }

        guard isAuthenticated else {
            resetForLogout()
            return
        }

        lockStateManager.updateLockState(
            isAuthenticated: isAuthenticated,
            lockEnabled: isBiometricLockEnabled,
            previouslyAuthenticated: previousAuthenticationState
        )
        
        lastUnlockErrorMessage = nil
        updatePromptState(isAuthenticated: true)
    }

    func attemptUnlock() async {
        guard SessionStore.shared.isAuthenticated else {
            lockStateManager.unlock()
            return
        }

        guard isBiometricLockEnabled else {
            lockStateManager.unlock()
            return
        }

        guard !isUnlocking else { return }

        isUnlocking = true
        lastUnlockErrorMessage = nil

        defer {
            isUnlocking = false
        }

        do {
            let success = try await biometricAuthManager.authenticate()
            
            if success {
                lockStateManager.unlock()
                lastUnlockErrorMessage = nil
            }
        } catch BiometricAuthError.notAvailable {
            lockStateManager.lock()
            lastUnlockErrorMessage = "Não foi possível pedir autenticação neste aparelho."
        } catch {
            lockStateManager.lock()
            lastUnlockErrorMessage = biometricAuthManager.errorMessage(for: error)
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

        lockStateManager.unlock()
        lastUnlockErrorMessage = nil
        markPromptAsHandled()
    }

    func markPromptAsHandled() {
        defaults.set(true, forKey: biometricPromptSeenKey)
        shouldShowEnablePrompt = false
    }

    func resetForLogout() {
        lockStateManager.reset()
        shouldShowEnablePrompt = false
        lastUnlockErrorMessage = nil
        previousAuthenticationState = false
    }

    // MARK: - Private Methods

    private func updatePromptState(isAuthenticated: Bool) {
        let promptWasSeen = defaults.bool(forKey: biometricPromptSeenKey)
        shouldShowEnablePrompt = isAuthenticated
            && !promptWasSeen
            && !isBiometricLockEnabled
            && isBiometricOptionAvailable
    }
}
