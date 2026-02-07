import SwiftUI

struct AccountsView: View {
    @StateObject private var viewModel = AccountsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var formMode: AccountFormMode?
    @State private var searchText = ""
    @State private var hasFinishedInitialLoad = false
    @State private var accountPendingDelete: AccountResponseDto?

    private let sectionSpacing = AppTheme.Spacing.item

    var body: some View {
        GeometryReader { proxy in
            let topBackgroundHeight = max(240, proxy.size.height * 0.34)

            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    DS.Colors.primary
                        .frame(height: topBackgroundHeight)
                        .frame(maxWidth: .infinity)

                    DS.Colors.surface2
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        topBlock
                            .padding(.top, 2)

                        accountsSection(viewportHeight: proxy.size.height)
                            .padding(.top, sectionSpacing)
                    }
                }
                .refreshable {
                    await viewModel.load()
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $formMode) { mode in
            AccountFormView(existing: mode.existing, viewModel: viewModel) { }
            .presentationDetents([.fraction(0.50)])
            .presentationDragIndicator(.visible)
        }
        .alert(
            "Excluir conta?",
            isPresented: Binding(
                get: { accountPendingDelete != nil },
                set: { isPresented in
                    if !isPresented { accountPendingDelete = nil }
                }
            )
        ) {
            Button("Cancelar", role: .cancel) {
                accountPendingDelete = nil
            }
            Button("Excluir", role: .destructive) {
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
        VStack(spacing: AppTheme.Spacing.item) {
            header

            AccountSearchField(text: $searchText) {
                viewModel.applySearch(term: searchText)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.screen)
        .padding(.top, 6)
        .padding(.bottom, 0)
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(DS.Colors.surface.opacity(0.45))
                    .clipShape(Circle())
            }
            .foregroundColor(DS.Colors.onPrimary)

            Spacer()

            Text("Contas")
                .font(AppTheme.Typography.title)
                .foregroundColor(DS.Colors.onPrimary)

            Spacer()

            Button {
                formMode = .new
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(DS.Colors.surface.opacity(0.45))
                    .clipShape(Circle())
            }
            .foregroundColor(DS.Colors.onPrimary)
        }
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
            .padding(.horizontal, AppTheme.Spacing.screen)
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
                Text(viewModel.activeSearchTerm.isEmpty ? "Sem contas cadastradas." : "Nenhuma conta encontrada.")
                    .font(AppTheme.Typography.body)
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
                        Button("Excluir", role: .destructive) {
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
            Text("Carregando contas...")
                .font(AppTheme.Typography.body)
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
