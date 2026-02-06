import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var showLogoutConfirm = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AppHeaderView()
                        .listRowInsets(
                            EdgeInsets(
                                top: AppTheme.Spacing.screen,
                                leading: AppTheme.Spacing.screen,
                                bottom: AppTheme.Spacing.item,
                                trailing: AppTheme.Spacing.screen
                            )
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }

                Section {
                    NavigationLink("Contas") {
                        AccountsView()
                    }
                    NavigationLink("Categorias") {
                        CategoriesView()
                    }
                }

                Section {
                    Button("Logout", role: .destructive) {
                        showLogoutConfirm = true
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(DS.Colors.background)
        }
        .alert("Tem certeza?", isPresented: $showLogoutConfirm) {
            Button("Cancelar", role: .cancel) {}
            Button("Sair", role: .destructive) {
                Task { await session.logout() }
            }
        } message: {
            Text("Você será desconectado da sua conta.")
        }
        .tint(DS.Colors.primary)
    }
}

private struct SettingsPlaceholderView: View {
    let title: String

    var body: some View {
        ZStack {
            DS.Colors.background
                .ignoresSafeArea()

            VStack {
                AppCard {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.base) {
                        Text(title)
                            .font(AppTheme.Typography.section)
                            .foregroundColor(DS.Colors.textPrimary)
                        Text("Em breve")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(DS.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(AppTheme.Spacing.screen)
        }
        .navigationTitle(title)
    }
}

#Preview {
    Group {
        SettingsView()
            .preferredColorScheme(.light)

        SettingsView()
            .preferredColorScheme(.dark)
    }
    .environmentObject(SessionStore.shared)
    .environmentObject(MonthFilterStore())
}
