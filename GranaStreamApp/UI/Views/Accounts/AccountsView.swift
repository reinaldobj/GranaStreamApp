import SwiftUI

struct AccountsView: View {
    @StateObject private var viewModel = AccountsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var formMode: AccountFormMode?
    @State private var searchText = ""
    @State private var hasFinishedInitialLoad = false
    @State private var accountPendingDelete: AccountResponseDto?

    private let sectionSpacing = DS.Spacing.item

    var body: some View {
        ListViewContainer(primaryBackgroundHeight: max(240, UIScreen.main.bounds.height * 0.34)) {
            VStack(spacing: 0) {
                topBlock
                    .padding(.top, DS.Spacing.sm)

                accountsSection(viewportHeight: UIScreen.main.bounds.height)
                    .padding(.top, sectionSpacing)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $formMode) { mode in
            AccountFormView(existing: mode.existing, viewModel: viewModel) { }
            .presentationDetents([.fraction(0.50)])
            .presentationDragIndicator(.visible)
        }
        .alert(
            L10n.Accounts.deleteConfirm,
            isPresented: Binding(
                get: { accountPendingDelete != nil },
                set: { isPresented in
                    if !isPresented { accountPendingDelete = nil }
                }
            )
        ) {
            Button(L10n.Common.cancel, role: .cancel) {
                accountPendingDelete = nil
            }
            Button(L10n.Common.delete, role: .destructive) {
                guard let account = accountPendingDelete else { return }
                accountPendingDelete = nil
                Task { await viewModel.delete(account: account) }
            }
        } message: {
            Text(deleteMessage)
        }
        .task {
            searchText = viewModel.activeSearchTerm
            await viewModel.load()
            hasFinishedInitialLoad = true
        }
        .errorAlert(message: $viewModel.errorMessage)
        .tint(DS.Colors.primary)
        .simultaneousGesture(backSwipeGesture)
    }

    private var topBlock: some View {
        VStack(spacing: DS.Spacing.item) {
            ListHeaderView(
                title: L10n.Accounts.title,
                searchText: $searchText,
                showSearch: false,
                actions: [
                    HeaderAction(
                        id: "add",
                        systemImage: "plus",
                        action: { formMode = .new }
                    )
                ],
                onDismiss: { dismiss() }
            )

            AccountSearchField(text: $searchText) {
                viewModel.applySearch(term: searchText)
            }
        }
        .padding(.horizontal, DS.Spacing.screen)
        .padding(.top, DS.Spacing.sm)
        .padding(.bottom, 0)
    }

    private var backSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 16, coordinateSpace: .local)
            .onEnded { value in
                let fromLeftEdge = value.startLocation.x < 28
                let hasHorizontalIntent = value.translation.width > 80 && abs(value.translation.height) < 60
                guard fromLeftEdge && hasHorizontalIntent else { return }
                dismiss()
            }
    }

    private func accountsSection(viewportHeight: CGFloat) -> some View {
        let emptyMinHeight = max(320, viewportHeight * 0.52)

        return accountsCard
            .padding(.horizontal, DS.Spacing.screen)
            .padding(.top, 6)
            .frame(
                maxWidth: .infinity,
                minHeight: viewModel.accounts.isEmpty ? emptyMinHeight : nil,
                alignment: .top
            )
            .topSectionStyle()
    }

    private var accountsCard: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            if shouldShowLoadingState {
                loadingState
            } else if viewModel.accounts.isEmpty {
                Text(viewModel.activeSearchTerm.isEmpty ? L10n.Accounts.empty : "Nenhuma conta encontrada.")
                    .font(DS.Typography.body)
                    .foregroundColor(DS.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                ForEach(Array(viewModel.accounts.enumerated()), id: \.element.id) { index, account in
                    TransactionSwipeRow(
                        onTap: {},
                        onEdit: {
                            formMode = .edit(account)
                        },
                        onDelete: {
                            accountPendingDelete = account
                        }
                    ) {
                        AccountRowView(account: account)
                    }
                    .contextMenu {
                        Button("Editar") {
                            formMode = .edit(account)
                        }
                                Button(L10n.Common.delete, role: .destructive) {
                            accountPendingDelete = account
                        }
                    }

                    if index < viewModel.accounts.count - 1 {
                        Divider()
                            .overlay(DS.Colors.border)
                    }
                }
            }
        }
        .padding(.top, 14)
    }

    private var shouldShowLoadingState: Bool {
        !hasFinishedInitialLoad || (viewModel.isLoading && viewModel.accounts.isEmpty)
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(DS.Colors.primary)
            Text(L10n.Accounts.loading)
                .font(DS.Typography.body)
                .foregroundColor(DS.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 24)
    }

    private var deleteMessage: String {
        let name = accountPendingDelete?.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let name, !name.isEmpty {
            return "Você realmente quer excluir a conta \"\(name)\"?"
        }
        return "Você realmente quer excluir esta conta?"
    }
}

private enum AccountFormMode: Identifiable {
    case new
    case edit(AccountResponseDto)

    var id: String {
        switch self {
        case .new:
            return "new"
        case .edit(let account):
            return "edit-\(account.id)"
        }
    }

    var existing: AccountResponseDto? {
        switch self {
        case .new:
            return nil
        case .edit(let account):
            return account
        }
    }
}
