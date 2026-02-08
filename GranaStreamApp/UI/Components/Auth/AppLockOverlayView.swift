import SwiftUI

struct AppLockOverlayView: View {
    let iconSystemName: String
    let subtitle: String
    let errorMessage: String?
    let isUnlocking: Bool
    let onUnlock: () -> Void
    let onLogout: () -> Void

    var body: some View {
        ZStack {
            DS.Colors.background
                .ignoresSafeArea()

            VStack(spacing: DS.Spacing.screen) {
                Spacer()

                VStack(spacing: DS.Spacing.item) {
                    Image(systemName: iconSystemName)
                        .font(.system(size: 54, weight: .semibold))
                        .foregroundColor(DS.Colors.primary)

                    Text("App protegido")
                        .font(DS.Typography.title)
                        .foregroundColor(DS.Colors.textPrimary)

                    Text(subtitle)
                        .font(DS.Typography.body)
                        .foregroundColor(DS.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 24)
                }

                if let errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(DS.Typography.caption)
                        .foregroundColor(DS.Colors.error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DS.Spacing.screen * 2)
                }

                Spacer()

                VStack(spacing: DS.Spacing.item) {
                    AppPrimaryButton(
                        title: isUnlocking ? "Verificando..." : "Desbloquear",
                        isDisabled: isUnlocking
                    ) {
                        onUnlock()
                    }

                    Button("Sair da conta", role: .destructive) {
                        onLogout()
                    }
                    .font(DS.Typography.body)
                    .foregroundColor(DS.Colors.error)
                }
                .padding(.horizontal, DS.Spacing.screen)
                .padding(.bottom, DS.Spacing.screen * 2)
            }
        }
    }
}

struct AppPrivacyMaskView: View {
    var body: some View {
        ZStack {
            DS.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 10) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(DS.Colors.primary)

                Text("GranaStream")
                    .font(DS.Typography.section)
                    .foregroundColor(DS.Colors.textPrimary)
            }
        }
        .accessibilityHidden(true)
    }
}

struct AppLockOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        AppLockOverlayView(
            iconSystemName: "faceid",
            subtitle: "Use Face ID ou o código do iPhone para continuar.",
            errorMessage: nil,
            isUnlocking: false,
            onUnlock: {},
            onLogout: {}
        )
    }
}
