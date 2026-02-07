import SwiftUI

struct AuthLandingView: View {
    let onLogin: () -> Void
    let onSignup: () -> Void

    var body: some View {
        ZStack {
            DS.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 64, weight: .semibold))
                        .foregroundColor(DS.Colors.primary)

                    Text("GranaStream")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(DS.Colors.textPrimary)

                    Text("Organize seu dinheiro com clareza.")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(DS.Colors.textSecondary)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: AppTheme.Spacing.item) {
                    AuthPrimaryButton(title: "Entrar") {
                        onLogin()
                    }

                    AuthSecondaryButton(title: "Criar conta") {
                        onSignup()
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.screen)
                .padding(.bottom, AppTheme.Spacing.screen * 2)
            }
        }
    }
}
