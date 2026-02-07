import SwiftUI

struct SignupView: View {
    let onLogin: () -> Void

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showSignupAlert = false

    var body: some View {
        AuthScreenContainer(
            title: "Criar conta",
            subtitle: "Leva poucos segundos"
        ) {
            VStack(spacing: AppTheme.Spacing.item) {
                AuthTextField(
                    label: "Nome",
                    placeholder: "Seu nome completo",
                    text: $name,
                    textContentType: .name,
                    autocapitalization: .words
                )

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
                    placeholder: "Crie uma senha",
                    text: $password,
                    isSecure: true,
                    textContentType: .newPassword,
                    autocapitalization: .never
                )

                AuthTextField(
                    label: "Confirmar senha",
                    placeholder: "Repita a senha",
                    text: $confirmPassword,
                    isSecure: true,
                    textContentType: .newPassword,
                    autocapitalization: .never
                )

                if showPasswordMismatch {
                    Text("As senhas não são iguais.")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(DS.Colors.error)
                }

                AuthPrimaryButton(
                    title: "Cadastrar",
                    isDisabled: !canSubmit
                ) {
                    showSignupAlert = true
                }

                HStack(spacing: 4) {
                    Text("Já tem conta?")
                        .foregroundColor(DS.Colors.textSecondary)

                    Button("Entrar") {
                        onLogin()
                    }
                    .foregroundColor(DS.Colors.primary)
                }
                .font(AppTheme.Typography.caption)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)
            }
        }
        .alert("Cadastro ainda não implementado", isPresented: $showSignupAlert) {
            Button("OK", role: .cancel) {}
        }
    }

    private var canSubmit: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedConfirm = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty
            && !trimmedEmail.isEmpty
            && !trimmedPassword.isEmpty
            && trimmedPassword == trimmedConfirm
    }

    private var showPasswordMismatch: Bool {
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedConfirm = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedConfirm.isEmpty && trimmedPassword != trimmedConfirm
    }
}
