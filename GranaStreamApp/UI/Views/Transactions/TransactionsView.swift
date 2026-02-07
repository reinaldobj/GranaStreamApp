import SwiftUI

struct TransactionsView: View {
    @StateObject private var viewModel = TransactionsViewModel()
    @EnvironmentObject private var referenceStore: ReferenceDataStore

    @State private var formMode: TransactionFormMode?
    @State private var selectedTransactionForDetail: TransactionSummaryDto?
    @State private var showFilters = false
    @State private var quickFilter: TransactionType?
    @State private var hasFinishedInitialLoad = false
    @State private var transactionPendingDelete: TransactionSummaryDto?
    private let sectionSpacing = AppTheme.Spacing.item

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
            .sheet(item: $formMode) { mode in
                TransactionFormView(existing: mode.existing) {
                    Task { await viewModel.load(reset: true) }
                }
                .presentationDetents([.fraction(0.80)])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showFilters) {
                TransactionFiltersView(filters: $viewModel.filters) {
                    syncQuickFilter()
                    Task { await viewModel.load(reset: true) }
                }
                .presentationDetents([.fraction(0.70)])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedTransactionForDetail) { item in
                TransactionDetailView(transaction: item)
                    .presentationDetents([.fraction(0.72)])
                    .presentationDragIndicator(.visible)
            }
            .task {
                await referenceStore.loadIfNeeded()
                syncQuickFilter()
                await viewModel.load(reset: true)
                hasFinishedInitialLoad = true
            }
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
                    Task { await viewModel.delete(transaction: transaction) }
                }
            } message: {
                Text(deleteMessage)
            }
            .errorAlert(message: $viewModel.errorMessage)
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

    private var topBlock: some View {
        VStack(spacing: AppTheme.Spacing.item) {
            header
            summaryCards
        }
        .padding(.horizontal, AppTheme.Spacing.screen)
        .padding(.top, 6)
        .padding(.bottom, 0)
    }

    private var summaryCards: some View {
        VStack(spacing: AppTheme.Spacing.item) {
            TransactionSummaryCardLarge(
                title: "Saldo total",
                value: CurrencyFormatter.string(from: totalBalance)
            )

            HStack(spacing: AppTheme.Spacing.item) {
                Button {
                    toggleQuickFilter(.income)
                } label: {
                    TransactionSummaryCardSmall(
                        title: "Receita",
                        value: CurrencyFormatter.string(from: incomeTotal),
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
                        value: CurrencyFormatter.string(from: -abs(expenseTotal)),
                        icon: "arrow.up.right",
                        accentColor: DS.Colors.error,
                        isSelected: quickFilter == .expense
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func transactionsSection(viewportHeight: CGFloat) -> some View {
        let emptyMinHeight = max(320, viewportHeight * 0.52)

        return transactionsCard
            .padding(.horizontal, AppTheme.Spacing.screen)
            .padding(.top, 6)
            .padding(.bottom, 0)
            .frame(
                maxWidth: .infinity,
                minHeight: monthSections.isEmpty ? emptyMinHeight : nil,
                alignment: .top
            )
            .topSectionStyle()
    }

    private var transactionsCard: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            if shouldShowLoadingState {
                loadingState
            } else if monthSections.isEmpty {
                Text("Sem transações neste período.")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(DS.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                ForEach(Array(monthSections.enumerated()), id: \.element.id) { index, section in
                    TransactionMonthHeader(title: section.title)
                        .padding(.leading, 4)
                        .padding(.top, index == 0 ? 14 : 0)

                    LazyVStack(spacing: 12) {
                        ForEach(Array(section.items.enumerated()), id: \.element.id) { rowIndex, transaction in
                            TransactionSwipeRow(
                                onTap: { selectedTransactionForDetail = transaction },
                                onEdit: {
                                    formMode = .edit(transaction)
                                },
                                onDelete: {
                                    transactionPendingDelete = transaction
                                }
                            ) {
                                TransactionRow(transaction: transaction)
                            }
                            .contextMenu {
                                Button("Editar") {
                                    formMode = .edit(transaction)
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
                                    Task { await viewModel.loadMore() }
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

    private var incomeTotal: Double {
        viewModel.transactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }

    private var expenseTotal: Double {
        viewModel.transactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }

    private var totalBalance: Double {
        incomeTotal - expenseTotal
    }

    private var monthSections: [MonthSection] {
        let sorted = viewModel.transactions.sorted { $0.date > $1.date }
        guard !sorted.isEmpty else { return [] }

        let calendar = Calendar.current
        let years = Set(sorted.map { calendar.component(.year, from: $0.date) })
        let showYear = years.count > 1

        var sections: [MonthSection] = []
        var currentKey = ""
        var currentDate = Date()
        var currentItems: [TransactionSummaryDto] = []

        for item in sorted {
            let components = calendar.dateComponents([.year, .month], from: item.date)
            let key = String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
            if key != currentKey {
                if !currentItems.isEmpty {
                    sections.append(
                        MonthSection(
                            id: currentKey,
                            title: monthTitle(for: currentDate, showYear: showYear),
                            items: currentItems
                        )
                    )
                }
                currentKey = key
                currentDate = item.date
                currentItems = [item]
            } else {
                currentItems.append(item)
            }
        }

        if !currentItems.isEmpty {
            sections.append(
                MonthSection(
                    id: currentKey,
                    title: monthTitle(for: currentDate, showYear: showYear),
                    items: currentItems
                )
            )
        }

        return sections
    }

    private func monthTitle(for date: Date, showYear: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = showYear ? "LLLL yyyy" : "LLLL"
        let text = formatter.string(from: date)
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    private func toggleQuickFilter(_ type: TransactionType) {
        if quickFilter == type {
            quickFilter = nil
            viewModel.filters.type = nil
        } else {
            quickFilter = type
            viewModel.filters.type = type
        }
        Task { await viewModel.load(reset: true) }
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
}

private enum TransactionFormMode: Identifiable {
    case new
    case edit(TransactionSummaryDto)

    var id: String {
        switch self {
        case .new:
            return "new"
        case .edit(let transaction):
            return "edit-\(transaction.id)"
        }
    }

    var existing: TransactionSummaryDto? {
        switch self {
        case .new:
            return nil
        case .edit(let transaction):
            return transaction
        }
    }
}

private struct MonthSection: Identifiable {
    let id: String
    let title: String
    let items: [TransactionSummaryDto]
}
