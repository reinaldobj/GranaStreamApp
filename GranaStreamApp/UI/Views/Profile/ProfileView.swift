import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var showChangePasswordSheet = false
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var showSavedToast = false

    var body: some View {
        ZStack {
            DS.Colors.background
                .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.screen) {
                VStack(spacing: AppTheme.Spacing.base) {
                    AppTitle(text: "Perfil")
                    Text("Atualize suas informações")
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
                        .disabled(true)
                        .opacity(0.7)

                        Text("Email não pode ser alterado.")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(DS.Colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        SecondaryButton(title: "Alterar senha") {
                            showChangePasswordSheet = true
                        }

                        PrimaryButton(title: isSaving ? "Salvando..." : "Salvar", isDisabled: isSaving) {
                            handleSave()
                        }
                    }
                }

                Spacer()
            }
            .padding(AppTheme.Spacing.screen)
        }
        .navigationTitle("Perfil")
        .onAppear {
            loadFromSession()
            Task {
                do {
                    try await session.loadProfile()
                    loadFromSession()
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
        .errorAlert(message: $errorMessage)
        .sheet(isPresented: $showChangePasswordSheet) {
            ChangePasswordView()
                .environmentObject(session)
        }
        .overlay(alignment: .bottom) {
            if showSavedToast {
                Text("Perfil salvo")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(DS.Colors.textPrimary)
                    .padding(.vertical, AppTheme.Spacing.base)
                    .padding(.horizontal, AppTheme.Spacing.screen)
                    .background(DS.Colors.surface2)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.field)
                            .stroke(DS.Colors.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.field))
                    .shadow(color: DS.Colors.border.opacity(0.25), radius: 6, x: 0, y: 2)
                    .padding(.bottom, AppTheme.Spacing.screen)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func loadFromSession() {
        name = session.profile?.name ?? session.currentUser?.name ?? ""
        email = session.profile?.email ?? session.currentUser?.email ?? ""
    }

    private func handleSave() {
        errorMessage = nil
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedEmail.isEmpty {
            errorMessage = "E-mail é obrigatório."
            return
        }

        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                try await session.updateProfile(name: trimmedName, email: trimmedEmail)
                loadFromSession()
                showSavedToast = true
                Task {
                    try? await Task.sleep(nanoseconds: 1_200_000_000)
                    withAnimation {
                        showSavedToast = false
                    }
                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    Group {
        NavigationStack {
            ProfileView()
        }
        .preferredColorScheme(.light)

        NavigationStack {
            ProfileView()
        }
        .preferredColorScheme(.dark)
    }
    .environmentObject(SessionStore.shared)
}
