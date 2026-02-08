import Foundation
import SwiftUI
import Combine

/// Gerencia estado de bloqueio da aplicação
@MainActor
final class LockStateManager: ObservableObject {
    @Published private(set) var isLocked: Bool = false
    @Published private(set) var isPrivacyMaskVisible: Bool = false
    
    private var backgroundEnteredAt: Date?
    private let lockDelay: TimeInterval = 15
    
    /// Atualiza estados com base na fase da cena (ScenePhase)
    func handleScenePhaseChange(_ phase: ScenePhase, isAuthenticated: Bool, lockEnabled: Bool) {
        switch phase {
        case .active:
            isPrivacyMaskVisible = false
            guard isAuthenticated else { return }

            if lockEnabled,
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
    
    /// Atualiza estado de bloqueio com base em autenticação
    func updateLockState(isAuthenticated: Bool, lockEnabled: Bool, previouslyAuthenticated: Bool) {
        guard isAuthenticated else {
            reset()
            return
        }

        isPrivacyMaskVisible = false

        if !lockEnabled {
            isLocked = false
        } else if previouslyAuthenticated == false {
            isLocked = false
        }
    }
    
    /// Desbloqueia a aplicação
    func unlock() {
        isLocked = false
    }
    
    /// Bloqueia a aplicação
    func lock() {
        isLocked = true
    }
    
    /// Reseta todos os estados (usado no logout)
    func reset() {
        isLocked = false
        isPrivacyMaskVisible = false
        backgroundEnteredAt = nil
    }
}
