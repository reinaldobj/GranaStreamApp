import SwiftUI

struct TransactionsView: View {
    @StateObject private var viewModel = TransactionsViewModel()
    @EnvironmentObject private var referenceStore: ReferenceDataStore

    @State private var showUnifiedEntryForm = false
    @State private var transactionToEdit: TransactionSummaryDto?
    @State private var selectedTransactionForDetail: TransactionSummaryDto?
    @State private var showFilters = false
    @State private var quickFilter: TransactionType?
    @State private var hasFinishedInitialLoad = false
    @State private var transactionPendingDelete: TransactionSummaryDto?
    @State private var successMessage: String?
    @State private var initialLoadTask: Task<Void, Never>?
    @State private var reloadTask: Task<Void, Never>?
    @State private var deleteTask: Task<Void, Never>?
    @State private var loadMoreTask: Task<Void, Never>?
    @State private var successBannerTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ListViewContainer {
                VStack(spacing: 0) {
                    TransactionsTopBarView(
                        totalBalance: viewModel.totalBalance,
                        incomeTotal: viewModel.incomeTotal,
                        expenseTotal: viewModel.expenseTotal,
                        quickFilter: quickFilter,
                        onShowFilters: { showFilters = true },
                        onAddTransaction: { showUnifiedEntryForm = true },
                        onToggleFilter: toggleQuickFilter
                    )
                    .padding(.top, DS.Spacing.sm)

                    TransactionListSection(
                        monthSections: viewModel.monthSections,
                        isLoading: !hasFinishedInitialLoad || (viewModel.isLoading && viewModel.transactions.isEmpty),
                        canLoadMore: viewModel.canLoadMore,
                        isLoadingMore: viewModel.isLoadingMore,
                        onTransactionTap: { selectedTransactionForDetail = $0 },
                        onEdit: { transactionToEdit = $0 },
                        onDelete: { transactionPendingDelete = $0 },
                        onLoadMore: requestLoadMore,
                        viewportHeight: UIScreen.main.bounds.height
                    )
                    .padding(.top, AppTheme.Spacing.item)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showUnifiedEntryForm) {
                UnifiedEntryFormView(initialMode: .single) { message in
                    handleCreateSuccess(message: message)
                }
                .presentationDetents([.fraction(0.90)])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $transactionToEdit) { transaction in
                TransactionFormView(existing: transaction) {
                    requestReload()
                }
                .presentationDetents([.fraction(0.80)])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showFilters) {
                TransactionFiltersView(filters: $viewModel.filters) {
                    syncQuickFilter()
                    requestReload()
                }
                .presentationDetents([.fraction(0.70)])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedTransactionForDetail) { item in
                TransactionDetailView(transaction: item)
                    .presentationDetents([.fraction(0.72)])
                    .presentationDragIndicator(.visible)
            }
            .task { startInitialLoad() }
            .onDisappear { cancelAllTasks() }
            .alert(
                L10n.Transactions.deleteConfirm,
                isPresented: Binding(
                    get: { transactionPendingDelete != nil },
                    set: { isPresented in
                        if !isPresented { transactionPendingDelete = nil }
                    }
                )
            ) {
                Button(L10n.Common.cancel, role: .cancel) {
                    transactionPendingDelete = nil
                }
                Button(L10n.Common.delete, role: .destructive) {
                    guard let transaction = transactionPendingDelete else { return }
                    transactionPendingDelete = nil
                    startDelete(transaction)
                }
            } message: {
                Text(deleteMessage)
            }
            .errorAlert(message: $viewModel.errorMessage)
            .overlay(alignment: .top) {
                if let successMessage {
                    successBanner(text: successMessage)
                        .padding(.top, DS.Spacing.sm)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .tint(DS.Colors.primary)
    }

    // MARK: - Private Methods

    private func toggleQuickFilter(_ type: TransactionType) {
        if quickFilter == type {
            quickFilter = nil
            viewModel.filters.type = nil
        } else {
            quickFilter = type
            viewModel.filters.type = type
        }
        requestReload()
    }

    private func syncQuickFilter() {
        switch viewModel.filters.type {
        case .income, .expense:
            quickFilter = viewModel.filters.type
        default:
            quickFilter = nil
        }
    }

    private var deleteMessage: String {
        let label = transactionPendingDelete?.description?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let label, !label.isEmpty {
            return L10n.Transactions.deleteConfirmMessage(label)
        }
        return L10n.Transactions.deleteDefault
    }

    private func startInitialLoad() {
        initialLoadTask?.cancel()
        hasFinishedInitialLoad = false

        initialLoadTask = Task {
            await referenceStore.loadIfNeeded()
            if Task.isCancelled { return }

            await MainActor.run {
                syncQuickFilter()
            }

            await viewModel.load(reset: true)
            if Task.isCancelled { return }

            await MainActor.run {
                hasFinishedInitialLoad = true
            }
        }
    }

    private func requestReload() {
        reloadTask?.cancel()
        reloadTask = Task {
            await viewModel.load(reset: true)
        }
    }

    private func requestLoadMore() {
        guard loadMoreTask == nil else { return }

        loadMoreTask = Task {
            await viewModel.loadMore()
            await MainActor.run {
                loadMoreTask = nil
            }
        }
    }

    private func startDelete(_ transaction: TransactionSummaryDto) {
        deleteTask?.cancel()
        deleteTask = Task {
            await viewModel.delete(transaction: transaction)
        }
    }

    private func cancelAllTasks() {
        initialLoadTask?.cancel()
        reloadTask?.cancel()
        deleteTask?.cancel()
        loadMoreTask?.cancel()
        successBannerTask?.cancel()

        initialLoadTask = nil
        reloadTask = nil
        deleteTask = nil
        loadMoreTask = nil
        successBannerTask = nil
    }

    private func handleCreateSuccess(message: String) {
        requestReload()
        showSuccessBanner(message: message)
    }

    private func showSuccessBanner(message: String) {
        successBannerTask?.cancel()

        withAnimation(.easeInOut(duration: 0.2)) {
            successMessage = message
        }

        successBannerTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    successMessage = nil
                }
            }
        }
    }

    private func successBanner(text: String) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DS.Colors.success)
            Text(text)
                .font(AppTheme.Typography.caption)
                .foregroundColor(DS.Colors.textPrimary)
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
        .background(DS.Colors.surface)
        .overlay(
            Capsule()
                .stroke(DS.Colors.border, lineWidth: 1)
        )
        .clipShape(Capsule())
        .shadow(color: DS.Colors.border.opacity(DS.Opacity.divider), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    TransactionsView()
        .environmentObject(ReferenceDataStore())
}
