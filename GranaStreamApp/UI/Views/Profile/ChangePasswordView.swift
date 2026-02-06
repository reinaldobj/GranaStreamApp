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
            Form {
                SecureField("Senha atual", text: $currentPassword)
                    .textContentType(.password)

                SecureField("Nova senha", text: $newPassword)
                    .textContentType(.newPassword)

                SecureField("Confirmar nova senha", text: $confirmPassword)
                    .textContentType(.newPassword)

                Text("A nova senha deve ser diferente da senha atual.")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)
            }
            .listRowBackground(DS.Colors.surface)
            .scrollContentBackground(.hidden)
            .background(DS.Colors.background)
            .navigationTitle("Alterar senha")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSaving ? "Salvando..." : "Salvar") {
                        Task { await save() }
                    }
                    .disabled(isSaving || !canSubmit)
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
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        ChangePasswordView()
    }
    .environmentObject(SessionStore.shared)
}
