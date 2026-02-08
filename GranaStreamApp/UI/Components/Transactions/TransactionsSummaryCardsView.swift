import SwiftUI

/// Cards de resumo de transações (saldo, receita, despesa)
struct TransactionsSummaryCardsView: View {
    let totalBalance: Double
    let incomeTotal: Double
    let expenseTotal: Double
    let quickFilter: TransactionType?
    let onToggleFilter: (TransactionType) -> Void
    
    var body: some View {
        VStack(spacing: DS.Spacing.item) {
            TransactionSummaryCardLarge(
                title: "Saldo total",
                value: CurrencyFormatter.string(from: totalBalance)
            )

            HStack(spacing: DS.Spacing.item) {
                Button {
                    onToggleFilter(.income)
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
                    onToggleFilter(.expense)
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
}
