import SwiftUI

// TODO: [TECH-DEBT] View com 506 linhas e 17+ @State - considerar extrair estado para um Coordinator ou usar @Observable
// TODO: [TECH-DEBT] Múltiplas Tasks manuais - avaliar uso de .task modifiers com IDs para simplificar ciclo de vida
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
    private let sectionSpacing = AppTheme.Spacing.item
    private let shortcutColumns = [
        GridItem(.flexible(), spacing: AppTheme.Spacing.item),
        GridItem(.flexible(), spacing: AppTheme.Spacing.item),
        GridItem(.flexible(), spacing: AppTheme.Spacing.item)
    ]

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let topBackgroundHeight = max(380, proxy.size.height * 0.56)

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

                            transactionsSection(viewportHeight: proxy.size.height)
                                .padding(.top, sectionSpacing)
                        }
                    }
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
                "Excluir lançamento?",
                isPresented: Binding(
                    get: { transactionPendingDelete != nil },
                    set: { isPresented in
                        if !isPresented { transactionPendingDelete = nil }
                    }
                )
            ) {
                Button("Cancelar", role: .cancel) {
                    transactionPendingDelete = nil
                }
                Button("Excluir", role: .destructive) {
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
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .tint(DS.Colors.primary)
    }

    private var header: some View {
        HStack {
            Button {
                showFilters = true
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(DS.Colors.surface.opacity(0.45))
                    .clipShape(Circle())
            }
            .foregroundColor(DS.Colors.onPrimary)

            Spacer()

            Text("Transações")
                .font(AppTheme.Typography.title)
                .foregroundColor(DS.Colors.onPrimary)

            Spacer()

            Button {
                showUnifiedEntryForm = true
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

    private var topBlock: some View {
        VStack(spacing: AppTheme.Spacing.item) {
            header
            summaryCards
            managementShortcuts
        }
        .padding(.horizontal, AppTheme.Spacing.screen)
        .padding(.top, 6)
        .padding(.bottom, 0)
    }

    private var summaryCards: some View {
        VStack(spacing: AppTheme.Spacing.item) {
            TransactionSummaryCardLarge(
                title: "Saldo total",
                value: CurrencyFormatter.string(from: viewModel.totalBalance)
            )

            HStack(spacing: AppTheme.Spacing.item) {
                Button {
                    toggleQuickFilter(.income)
                } label: {
                    TransactionSummaryCardSmall(
                        title: "Receita",
                        value: CurrencyFormatter.string(from: viewModel.incomeTotal),
                        icon: "arrow.down.left",
                        accentColor: DS.Colors.primary,
                        isSelected: quickFilter == .income
                    )
                }
                .buttonStyle(.plain)

                Button {
                    toggleQuickFilter(.expense)
                } label: {
                    TransactionSummaryCardSmall(
                        title: "Despesa",
                        value: CurrencyFormatter.string(from: -abs(viewModel.expenseTotal)),
                        icon: "arrow.up.right",
                        accentColor: DS.Colors.error,
                        isSelected: quickFilter == .expense
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var managementShortcuts: some View {
        LazyVGrid(columns: shortcutColumns, spacing: AppTheme.Spacing.item) {
            NavigationLink {
                PayablesView()
            } label: {
                Image(systemName: "checklist")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(DS.Colors.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.field)
                            .fill(DS.Colors.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.field)
                            .stroke(DS.Colors.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            NavigationLink {
                RecurrencesView()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(DS.Colors.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.field)
                            .fill(DS.Colors.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.field)
                            .stroke(DS.Colors.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            NavigationLink {
                InstallmentSeriesView()
            } label: {
                Image(systemName: "creditcard")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(DS.Colors.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.field)
                            .fill(DS.Colors.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.field)
                            .stroke(DS.Colors.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func managementShortcutCard(title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
            Text(title)
                .font(AppTheme.Typography.caption)
                .lineLimit(1)
        }
        .foregroundColor(DS.Colors.primary)
        .frame(maxWidth: .infinity, minHeight: 36)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.field)
                .fill(DS.Colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.field)
                .stroke(DS.Colors.border, lineWidth: 1)
        )
    }

    private func transactionsSection(viewportHeight: CGFloat) -> some View {
        let emptyMinHeight = max(320, viewportHeight * 0.52)

        return transactionsCard
            .padding(.horizontal, AppTheme.Spacing.screen)
            .padding(.top, 6)
            .padding(.bottom, 0)
            .frame(
                maxWidth: .infinity,
                minHeight: viewModel.monthSections.isEmpty ? emptyMinHeight : nil,
                alignment: .top
            )
            .topSectionStyle()
    }

    private var transactionsCard: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            if shouldShowLoadingState {
                loadingState
            } else if viewModel.monthSections.isEmpty {
                Text("Sem transações neste período.")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(DS.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                ForEach(Array(viewModel.monthSections.enumerated()), id: \.element.id) { index, section in
                    TransactionMonthHeader(title: section.title)
                        .padding(.leading, 4)
                        .padding(.top, index == 0 ? 14 : 0)

                    LazyVStack(spacing: 12) {
                        ForEach(Array(section.items.enumerated()), id: \.element.id) { rowIndex, transaction in
                            TransactionSwipeRow(
                                onTap: { selectedTransactionForDetail = transaction },
                                onEdit: {
                                    transactionToEdit = transaction
                                },
                                onDelete: {
                                    transactionPendingDelete = transaction
                                }
                            ) {
                                TransactionRow(transaction: transaction)
                            }
                            .contextMenu {
                                Button("Editar") {
                                    transactionToEdit = transaction
                                }
                                Button("Excluir", role: .destructive) {
                                    transactionPendingDelete = transaction
                                }
                            }

                            if rowIndex < section.items.count - 1 {
                                Divider()
                                    .overlay(DS.Colors.border)
                            }
                        }
                    }
                }

                if viewModel.canLoadMore {
                    HStack {
                        Spacer()
                        if viewModel.isLoadingMore {
                            ProgressView()
                                .tint(DS.Colors.primary)
                        } else {
                            ProgressView()
                                .tint(DS.Colors.primary)
                                .onAppear {
                                    requestLoadMore()
                                }
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    private var shouldShowLoadingState: Bool {
        !hasFinishedInitialLoad || (viewModel.isLoading && viewModel.transactions.isEmpty)
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(DS.Colors.primary)
            Text("Carregando lançamentos...")
                .font(AppTheme.Typography.body)
                .foregroundColor(DS.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 24)
    }

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
            return "Você realmente quer excluir \"\(label)\"?"
        }
        return "Você realmente quer excluir este lançamento?"
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
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DS.Colors.success)
            Text(text)
                .font(AppTheme.Typography.caption)
                .foregroundColor(DS.Colors.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(DS.Colors.surface)
        .overlay(
            Capsule()
                .stroke(DS.Colors.border, lineWidth: 1)
        )
        .clipShape(Capsule())
        .shadow(color: DS.Colors.border.opacity(0.25), radius: 6, x: 0, y: 3)
    }
}

