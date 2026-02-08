import SwiftUI

struct RecentTransactionsSectionView: View {
    let transactions: [TransactionItem]

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: DS.Spacing.item) {
                AppSectionHeader(text: "Últimas transações")
                VStack(spacing: DS.Spacing.base) {
                    ForEach(Array(transactions.enumerated()), id: \.element.id) { index, item in
                        RecentTransactionRowView(item: item)
                        if index < transactions.count - 1 {
                            Divider()
                                .overlay(DS.Colors.border)
                        }
                    }
                }
            }
        }
    }
}

struct RecentTransactionRowView: View {
    let item: TransactionItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(DS.Typography.body)
                    .foregroundColor(DS.Colors.textPrimary)
                Text(item.category)
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)
            }
            Spacer()
            Text("R$ \(formatAmount(item.amount))")
                .font(DS.Typography.body)
                .foregroundColor(item.kind == .income ? DS.Colors.success : DS.Colors.error)
        }
    }

    private func formatAmount(_ amount: Double) -> String {
        let formatted = String(format: "%.2f", amount)
        return formatted.replacingOccurrences(of: ".", with: ",")
    }
}
