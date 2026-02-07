import SwiftUI

struct ChangePasswordView: View {
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.item) {
                        VStack(spacing: 6) {
                            Text("Alterar senha")
                                .font(AppTheme.Typography.title)
                                .foregroundColor(DS.Colors.textPrimary)

                            Text("Atualize sua senha com segurança")
                                .font(AppTheme.Typography.body)
                                .foregroundColor(DS.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)

                        AuthCard {
                            AuthTextField(
                                label: "Senha atual",
                                placeholder: "Digite sua senha atual",
                                text: $currentPassword,
                                isSecure: true,
                                textContentType: .password,
                                autocapitalization: .never,
                                autocorrectionDisabled: true
                            )

                            AuthTextField(
                                label: "Nova senha",
                                placeholder: "Digite a nova senha",
                                text: $newPassword,
                                isSecure: true,
                                textContentType: .newPassword,
                                autocapitalization: .never,
                                autocorrectionDisabled: true
                            )

                            AuthTextField(
                                label: "Confirmar nova senha",
                                placeholder: "Confirme a nova senha",
                                text: $confirmPassword,
                                isSecure: true,
                                textContentType: .newPassword,
                                autocapitalization: .never,
                                autocorrectionDisabled: true
                            )

                            Text("A nova senha deve ser diferente da senha atual.")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(DS.Colors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if let inlineValidationMessage {
                                Text(inlineValidationMessage)
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(DS.Colors.error)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            AuthPrimaryButton(
                                title: isSaving ? "Salvando..." : "Salvar",
                                isDisabled: isSaving || !canSubmit
                            ) {
                                Task { await save() }
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.screen)
                    .padding(.top, AppTheme.Spacing.screen + 10)
                    .padding(.bottom, AppTheme.Spacing.screen * 2)
                }
            }
        }
        .errorAlert(message: $errorMessage)
        .alert("Senha alterada", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Sua senha foi atualizada com sucesso.")
        }
        .tint(DS.Colors.primary)
    }

    private var canSubmit: Bool {
        let trimmedCurrent = currentPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNew = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedConfirm = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedCurrent.isEmpty
            && !trimmedNew.isEmpty
            && trimmedNew == trimmedConfirm
            && trimmedNew != trimmedCurrent
    }

    private var inlineValidationMessage: String? {
        let trimmedCurrent = currentPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNew = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedConfirm = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedNew.isEmpty && !trimmedConfirm.isEmpty && trimmedNew != trimmedConfirm {
            return "As senhas não conferem."
        }

        if !trimmedCurrent.isEmpty && !trimmedNew.isEmpty && trimmedNew == trimmedCurrent {
            return "A nova senha deve ser diferente da senha atual."
        }

        return nil
    }

    private func save() async {
        errorMessage = nil
        let trimmedCurrent = currentPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNew = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedConfirm = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedNew != trimmedConfirm {
            errorMessage = "As senhas não conferem."
            return
        }

        if trimmedNew == trimmedCurrent {
            errorMessage = "A nova senha deve ser diferente da senha atual."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try await session.changePassword(
                currentPassword: trimmedCurrent,
                newPassword: trimmedNew
            )
            showSuccess = true
        } catch {
            errorMessage = error.userMessage
        }
    }
}

struct ChangePasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ChangePasswordView()
            .environmentObject(SessionStore.shared)
    }
}
