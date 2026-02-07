import SwiftUI

struct RootView: View {
    @StateObject private var session = SessionStore.shared
    @StateObject private var monthStore = MonthFilterStore()
    @StateObject private var referenceStore = ReferenceDataStore.shared
    @StateObject private var appLock = AppLockService.shared

    var body: some View {
        ZStack {
            Group {
                if session.isAuthenticated {
                    MainTabView()
                        .environmentObject(session)
                        .environmentObject(monthStore)
                        .environmentObject(referenceStore)
                        .environmentObject(appLock)
                } else {
                    AuthFlowView(session: session)
                }
            }

            if session.isAuthenticated, appLock.isPrivacyMaskVisible {
                AppPrivacyMaskView()
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }

            if session.isAuthenticated, appLock.isLocked {
                AppLockOverlayView(
                    iconSystemName: appLock.biometricSystemImage,
                    subtitle: "Use \(appLock.biometricDisplayName) ou o código do iPhone para continuar.",
                    errorMessage: appLock.lastUnlockErrorMessage,
                    isUnlocking: appLock.isUnlocking,
                    onUnlock: {
                        Task { await appLock.attemptUnlock() }
                    },
                    onLogout: {
                        Task { await session.logout() }
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: appLock.isLocked)
        .animation(.easeInOut(duration: 0.2), value: appLock.isPrivacyMaskVisible)
        .onAppear {
            appLock.syncAuthenticationState(isAuthenticated: session.isAuthenticated)
        }
        .onChange(of: session.isAuthenticated) { _, isAuthenticated in
            appLock.syncAuthenticationState(isAuthenticated: isAuthenticated)
        }
        .task(id: appLock.isLocked) {
            guard session.isAuthenticated, appLock.isLocked else { return }
            await appLock.attemptUnlock()
        }
        .alert(
            "Ativar proteção por \(appLock.biometricDisplayName)?",
            isPresented: enablePromptBinding
        ) {
            Button("Agora não", role: .cancel) {
                appLock.markPromptAsHandled()
            }
            Button("Ativar") {
                appLock.enableBiometricLock()
                appLock.markPromptAsHandled()
            }
        } message: {
            Text("Ao voltar para o app, você confirma com \(appLock.biometricDisplayName) ou código do iPhone.")
        }
    }

    private var enablePromptBinding: Binding<Bool> {
        Binding(
            get: { session.isAuthenticated && appLock.shouldShowEnablePrompt },
            set: { shouldShow in
                if !shouldShow {
                    appLock.markPromptAsHandled()
                }
            }
        )
    }
}
