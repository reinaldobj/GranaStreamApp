import SwiftUI

struct TransactionRow: View {
    let transaction: TransactionSummaryDto

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.base) {
            HStack {
                Text(transaction.description ?? transaction.summary ?? "Sem descrição")
                    .font(AppTheme.Typography.section)
                    .foregroundColor(DS.Colors.textPrimary)
                Spacer()
                Text(CurrencyFormatter.string(from: transaction.amount))
                    .font(AppTheme.Typography.section)
                    .foregroundColor(amountColor)
            }
            HStack {
                Text(transaction.date.formattedDate())
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)
                Spacer()
                Text(transaction.categoryName ?? transaction.accountName ?? "")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)
            }
        }
    }

    private var amountColor: Color {
        switch transaction.type {
        case .income: return DS.Colors.success
        case .expense: return DS.Colors.error
        case .transfer: return DS.Colors.accent
        }
    }
}
