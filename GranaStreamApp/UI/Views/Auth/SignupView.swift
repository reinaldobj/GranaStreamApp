import SwiftUI

struct SignupView: View {
    @Binding var showSignup: Bool

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showSignupAlert = false

    var body: some View {
        ZStack {
            DS.Colors.background
                .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.screen) {
                VStack(spacing: AppTheme.Spacing.base) {
                    AppTitle(text: "Criar conta")
                    Text("Leva poucos segundos")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(DS.Colors.textSecondary)
                }

                AppCard {
                    VStack(spacing: AppTheme.Spacing.item) {
                        AppTextField(
                            placeholder: "Nome",
                            text: $name,
                            textContentType: .name
                        )

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
                            textContentType: .newPassword,
                            autocapitalization: .never
                        )

                        PrimaryButton(
                            title: "Cadastrar",
                            isDisabled: name.isEmpty || email.isEmpty || password.isEmpty
                        ) {
                            showSignupAlert = true
                        }

                        SecondaryButton(title: "Voltar") {
                            showSignup = false
                        }
                    }
                }

                Spacer()
            }
            .padding(AppTheme.Spacing.screen)
        }
        .alert("Cadastro ainda não implementado", isPresented: $showSignupAlert) {
            Button("OK", role: .cancel) {}
        }
    }
}
