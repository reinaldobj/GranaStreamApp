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
    @State private var saveTask: Task<Void, Never>?
    @State private var hideToastTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DS.Spacing.item) {
                        VStack(spacing: 6) {
                            Text("Perfil")
                                .font(DS.Typography.title)
                                .foregroundColor(DS.Colors.textPrimary)

                            Text("Atualize suas informações")
                                .font(DS.Typography.body)
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
                                .font(DS.Typography.caption)
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
                    .padding(.horizontal, DS.Spacing.screen)
                    .padding(.top, DS.Spacing.screen + 10)
                    .padding(.bottom, DS.Spacing.screen * 2)
                }
            }
        }
        .task {
            loadFromSession()
            do {
                try await session.loadProfile()
                loadFromSession()
            } catch {
                errorMessage = error.userMessage
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
                    .font(DS.Typography.body)
                    .foregroundColor(DS.Colors.textPrimary)
                    .padding(.vertical, DS.Spacing.base)
                    .padding(.horizontal, DS.Spacing.screen)
                    .background(DS.Colors.surface2)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.field)
                            .stroke(DS.Colors.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.field))
                    .shadow(color: DS.Colors.border.opacity(0.25), radius: 6, x: 0, y: 2)
                    .padding(.bottom, DS.Spacing.screen)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onDisappear {
            saveTask?.cancel()
            hideToastTask?.cancel()
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

        saveTask?.cancel()
        isSaving = true

        saveTask = Task {
            defer {
                isSaving = false
                saveTask = nil
            }
            do {
                try await session.updateProfile(name: trimmedName, email: trimmedEmail)
                if Task.isCancelled { return }

                loadFromSession()
                hideToastTask?.cancel()
                showSavedToast = true

                hideToastTask = Task {
                    try? await Task.sleep(nanoseconds: 1_200_000_000)
                    if Task.isCancelled { return }

                    withAnimation {
                        showSavedToast = false
                    }
                    dismiss()
                }
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.userMessage
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ProfileView()
                .preferredColorScheme(.light)

            ProfileView()
                .preferredColorScheme(.dark)
        }
        .environmentObject(SessionStore.shared)
    }
}
