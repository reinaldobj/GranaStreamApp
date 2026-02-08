import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var appLock: AppLockService
    @State private var showLogoutConfirm = false
    @State private var showProfileSheet = false

    private let sectionSpacing = AppTheme.Spacing.item

    var body: some View {
        NavigationStack {
            ListViewContainer(primaryBackgroundHeight: max(260, UIScreen.main.bounds.height * 0.35)) {
                VStack(spacing: 0) {
                    topBlock
                        .padding(.top, DS.Spacing.sm)

                    settingsSection(viewportHeight: UIScreen.main.bounds.height)
                        .padding(.top, sectionSpacing)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .alert(L10n.Settings.logoutConfirm, isPresented: $showLogoutConfirm) {
            Button(L10n.Common.cancel, role: .cancel) {}
            Button(L10n.Settings.logout, role: .destructive) {
                Task { await session.logout() }
            }
        } message: {
            Text(L10n.Settings.logoutMessage)
        }
        .sheet(isPresented: $showProfileSheet) {
            ProfileView()
                .environmentObject(session)
                .presentationDetents([.fraction(0.80)])
                .presentationDragIndicator(.visible)
        }
        .tint(DS.Colors.primary)
    }

    private var topBlock: some View {
        VStack(spacing: AppTheme.Spacing.item) {
            header
            profileLinkCard
        }
        .padding(.horizontal, AppTheme.Spacing.screen)
        .padding(.top, 6)
    }

    private var header: some View {
        HStack {
            Color.clear
                .frame(width: 40, height: 40)

            Spacer()

            Text("Configurações")
                .font(AppTheme.Typography.title)
                .foregroundColor(DS.Colors.onPrimary)

            Spacer()

            Color.clear
                .frame(width: 40, height: 40)
        }
    }

    private var profileLinkCard: some View {
        Button {
            showProfileSheet = true
        } label: {
            HStack(spacing: AppTheme.Spacing.item) {
                InitialsAvatarView(name: profileNameRaw, size: 66)

                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(AppTheme.Typography.section)
                        .foregroundColor(DS.Colors.textPrimary)
                        .lineLimit(1)

                    Text(displayEmail)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 12)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DS.Colors.textSecondary)
            }
            .padding(14)
            .background(DS.Colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(DS.Colors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func settingsSection(viewportHeight: CGFloat) -> some View {
        let minHeight = max(300, viewportHeight * 0.52)

        return settingsCard
            .padding(.horizontal, AppTheme.Spacing.screen)
            .padding(.top, 6)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .top)
            .topSectionStyle()
    }

    private var settingsCard: some View {
        VStack(spacing: AppTheme.Spacing.item) {
            NavigationLink {
                AccountsView()
            } label: {
                SettingsMenuRow(title: "Contas", systemImage: "wallet.pass")
            }
            .buttonStyle(.plain)

            NavigationLink {
                CategoriesView()
            } label: {
                SettingsMenuRow(title: "Categorias", systemImage: "square.grid.2x2")
            }
            .buttonStyle(.plain)

            biometricProtectionCard

            Button {
                showLogoutConfirm = true
            } label: {
                SettingsMenuRow(
                    title: L10n.Settings.logout,
                    systemImage: "rectangle.portrait.and.arrow.right",
                    isDestructive: true,
                    showsChevron: false
                )
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
        .padding(.top, 16)
    }

    private var biometricProtectionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: biometricToggleBinding) {
                HStack(spacing: AppTheme.Spacing.item) {
                    ZStack {
                        Circle()
                            .fill(DS.Colors.primary.opacity(0.18))
                            .frame(width: 42, height: 42)

                        Image(systemName: appLock.biometricSystemImage)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(DS.Colors.primary)
                    }

                    Text("Proteção por \(appLock.biometricDisplayName)")
                        .font(AppTheme.Typography.section)
                        .foregroundColor(DS.Colors.textPrimary)
                }
            }
            .tint(DS.Colors.primary)
            .disabled(!appLock.isBiometricOptionAvailable && !appLock.isBiometricLockEnabled)

            Text(biometricHelpText)
                .font(AppTheme.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)
                .padding(.leading, 2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(DS.Colors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(DS.Colors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var biometricToggleBinding: Binding<Bool> {
        Binding(
            get: { appLock.isBiometricLockEnabled },
            set: { isEnabled in
                if isEnabled {
                    appLock.enableBiometricLock()
                } else {
                    appLock.disableBiometricLock()
                }
            }
        )
    }

    private var biometricHelpText: String {
        if appLock.isBiometricOptionAvailable {
            return "Ao voltar para o app depois de 15 segundos fora, use \(appLock.biometricDisplayName) ou código do iPhone."
        }
        return "Este aparelho não oferece Face ID ou Touch ID no momento."
    }

    private var displayName: String {
        let trimmed = profileNameRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Seu perfil" : trimmed
    }

    private var profileNameRaw: String {
        session.profile?.name ?? session.currentUser?.name ?? ""
    }

    private var displayEmail: String {
        let raw = session.profile?.email ?? session.currentUser?.email ?? ""
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Toque para abrir perfil" : trimmed
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsView()
                .preferredColorScheme(.light)

            SettingsView()
                .preferredColorScheme(.dark)
        }
        .environmentObject(SessionStore.shared)
        .environmentObject(AppLockService.shared)
    }
}
