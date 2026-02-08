import SwiftUI

/// Seção superior da view de transações com resumo e filtros
struct TransactionsTopBarView: View {
    let totalBalance: Double
    let incomeTotal: Double
    let expenseTotal: Double
    let quickFilter: TransactionType?
    let onShowFilters: () -> Void
    let onAddTransaction: () -> Void
    let onToggleFilter: (TransactionType) -> Void

    private let sectionSpacing = DS.Spacing.item

    var body: some View {
        VStack(spacing: sectionSpacing) {
            ListHeaderView(
                title: L10n.Transactions.title,
                searchText: .constant(""),
                showSearch: false,
                actions: [
                    HeaderAction(
                        id: "filter",
                        systemImage: "line.3.horizontal.decrease.circle.fill",
                        action: onShowFilters
                    ),
                    HeaderAction(
                        id: "add",
                        systemImage: "plus",
                        action: onAddTransaction
                    )
                ]
            )

            TransactionsSummaryCardsView(
                totalBalance: totalBalance,
                incomeTotal: incomeTotal,
                expenseTotal: expenseTotal,
                quickFilter: quickFilter,
                onToggleFilter: onToggleFilter
            )

            TransactionQuickFiltersView()
        }
        .padding(.horizontal, DS.Spacing.screen)
        .padding(.top, DS.Spacing.sm)
        .padding(.bottom, 0)
    }
}

#Preview {
    TransactionsTopBarView(
        totalBalance: 1000.0,
        incomeTotal: 2000.0,
        expenseTotal: 1000.0,
        quickFilter: nil,
        onShowFilters: {},
        onAddTransaction: {},
        onToggleFilter: { _ in }
    )
}
