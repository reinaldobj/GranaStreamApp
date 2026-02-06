import SwiftUI

struct LoginView: View {
    @Binding var showSignup: Bool
    @ObservedObject var session: SessionStore

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            DS.Colors.background
                .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.screen) {
                VStack(spacing: AppTheme.Spacing.base) {
                    AppTitle(text: "GranaStream")
                    Text("Acesse sua conta")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(DS.Colors.textSecondary)
                }

                AppCard {
                    VStack(spacing: AppTheme.Spacing.item) {
                        AppTextField(
                            placeholder: "Email",
                            text: $email,
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress,
                            autocapitalization: .never,
                            autocorrectionDisabled: true
                        )

                        AppTextField(
                            placeholder: "Senha",
                            text: $password,
                            isSecure: true,
                            textContentType: .password,
                            autocapitalization: .never
                        )

                        PrimaryButton(
                            title: isLoading ? "Entrando..." : "Entrar",
                            isDisabled: email.isEmpty || password.isEmpty || isLoading
                        ) {
                            guard !isLoading else { return }
                            isLoading = true
                            Task {
                                defer { isLoading = false }
                                do {
                                    try await session.login(email: email, password: password)
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                            }
                        }

                        SecondaryButton(title: "Criar conta") {
                            showSignup = true
                        }
                    }
                }

                Spacer()
            }
            .padding(AppTheme.Spacing.screen)
        }
        .errorAlert(message: $errorMessage)
    }
}
