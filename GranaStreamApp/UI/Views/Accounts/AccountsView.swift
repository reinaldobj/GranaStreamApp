import SwiftUI

struct AccountsView: View {
    @StateObject private var viewModel = AccountsViewModel()
    @State private var showForm = false
    @State private var selectedAccount: AccountResponseDto?

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.accounts.isEmpty {
                SkeletonListView()
            } else {
                List {
                    ForEach(viewModel.accounts) { account in
                        AppCard {
                            HStack {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.base) {
                                    Text(account.name ?? "Conta")
                                        .font(AppTheme.Typography.section)
                                        .foregroundColor(DS.Colors.textPrimary)
                                    Text(account.accountType.label)
                                        .font(AppTheme.Typography.caption)
                                        .foregroundColor(DS.Colors.textSecondary)
                                }
                                Spacer()
                                Text(CurrencyFormatter.string(from: account.initialBalance))
                                    .font(AppTheme.Typography.body)
                                    .foregroundColor(DS.Colors.textSecondary)
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                        .contentShape(Rectangle())
                        .swipeActions(edge: .trailing) {
                            Button {
                                selectedAccount = account
                                showForm = true
                            } label: {
                                Label("Editar", systemImage: "pencil")
                            }
                            .tint(DS.Colors.primary)
                            Button(role: .destructive) {
                                Task { await viewModel.delete(account: account) }
                            } label: {
                                Label("Excluir", systemImage: "trash")
                            }
                            .tint(DS.Colors.error)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(DS.Colors.background)
                .safeAreaInset(edge: .top) {
                    if viewModel.isLoading && !viewModel.accounts.isEmpty {
                        HStack {
                            Spacer()
                            LoadingPillView()
                            Spacer()
                        }
                        .padding(.top, 6)
                    }
                }
            }
        }
        .navigationTitle("Contas")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    selectedAccount = nil
                    showForm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showForm) {
            AccountFormView(existing: selectedAccount) {
                Task { await viewModel.load() }
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .errorAlert(message: $viewModel.errorMessage)
        .tint(DS.Colors.primary)
    }
}
