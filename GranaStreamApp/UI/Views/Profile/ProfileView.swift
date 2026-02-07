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
        NavigationStack {
            ZStack {
                DS.Colors.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.item) {
                        VStack(spacing: 6) {
                            Text("Perfil")
                                .font(AppTheme.Typography.title)
                                .foregroundColor(DS.Colors.textPrimary)

                            Text("Atualize suas informações")
                                .font(AppTheme.Typography.body)
                                .foregroundColor(DS.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)

                        AuthCard {
                            AuthTextField(
                                label: "Nome",
                                placeholder: "Seu nome",
                                text: $name,
                                textContentType: .name
                            )

                            AuthTextField(
                                label: "Email",
                                placeholder: "seu@email.com",
                                text: $email,
                                keyboardType: .emailAddress,
                                textContentType: .emailAddress,
                                autocapitalization: .never,
                                autocorrectionDisabled: true
                            )
                            .disabled(true)
                            .opacity(0.75)

                            Text("Email não pode ser alterado.")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(DS.Colors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            AuthSecondaryButton(title: "Alterar senha") {
                                showChangePasswordSheet = true
                            }

                            AuthPrimaryButton(title: isSaving ? "Salvando..." : "Salvar", isDisabled: isSaving) {
                                handleSave()
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.screen)
                    .padding(.top, AppTheme.Spacing.screen + 10)
                    .padding(.bottom, AppTheme.Spacing.screen * 2)
                }
            }
        }
        .task {
            loadFromSession()
            do {
                try await session.loadProfile()
                loadFromSession()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        .errorAlert(message: $errorMessage)
        .sheet(isPresented: $showChangePasswordSheet) {
            ChangePasswordView()
                .environmentObject(session)
                .presentationDetents([.fraction(0.75)])
                .presentationDragIndicator(.visible)
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
        .tint(DS.Colors.primary)
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
        ProfileView()
            .preferredColorScheme(.light)

        ProfileView()
            .preferredColorScheme(.dark)
    }
    .environmentObject(SessionStore.shared)
}
