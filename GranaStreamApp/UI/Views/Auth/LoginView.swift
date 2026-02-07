import SwiftUI

struct LoginView: View {
    @ObservedObject var session: SessionStore
    let onSignup: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        AuthScreenContainer(
            title: "Bem-vindo",
            subtitle: "Acesse sua conta"
        ) {
            VStack(spacing: AppTheme.Spacing.item) {
                AuthTextField(
                    label: "Email",
                    placeholder: "voce@exemplo.com",
                    text: $email,
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress,
                    autocapitalization: .never,
                    autocorrectionDisabled: true
                )

                AuthTextField(
                    label: "Senha",
                    placeholder: "Sua senha",
                    text: $password,
                    isSecure: true,
                    textContentType: .password,
                    autocapitalization: .never
                )

                AuthPrimaryButton(
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
                            errorMessage = error.userMessage
                        }
                    }
                }

                AuthSecondaryButton(title: "Criar conta") {
                    onSignup()
                }
            }
        }
        .errorAlert(message: $errorMessage)
    }
}
