import SwiftUI

struct TransactionRow: View {
    let transaction: TransactionSummaryDto

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(amountColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(amountColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(transaction.description ?? transaction.summary ?? "Sem descrição")
                        .font(AppTheme.Typography.section)
                        .foregroundColor(DS.Colors.textPrimary)
                    Spacer()
                }

                HStack(spacing: 6) {
                    Text(dateText)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)
                        .frame(width: RowSizing.dateWidth, alignment: .leading)
                        .lineLimit(1)

                    separator

                    Text(transaction.categoryName ?? transaction.accountName ?? "Sem categoria")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)
                        .frame(width: RowSizing.categoryWidth, alignment: .leading)
                        .lineLimit(1)

                    separator

                    Text(amountText)
                        .font(AppTheme.Typography.section)
                        .foregroundColor(amountColor)
                        .frame(width: RowSizing.amountWidth, alignment: .trailing)
                        .lineLimit(1)
                }
            }
        }
    }

    private var amountColor: Color {
        switch transaction.type {
        case .income: return DS.Colors.primary
        case .expense: return DS.Colors.error
        case .transfer: return DS.Colors.accent
        }
    }

    private var amountText: String {
        switch transaction.type {
        case .expense:
            return CurrencyFormatter.string(from: abs(transaction.amount))
        default:
            return CurrencyFormatter.string(from: transaction.amount)
        }
    }

    private var iconName: String {
        switch transaction.type {
        case .income: return "arrow.down.left"
        case .expense: return "arrow.up.right"
        case .transfer: return "arrow.left.arrow.right"
        }
    }

    private var dateText: String {
        Self.shortDateFormatter.string(from: transaction.date)
    }

    private var separator: some View {
        Rectangle()
            .fill(DS.Colors.border)
            .frame(width: 1, height: 22)
    }

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.setLocalizedDateFormatFromTemplate("d MMM")
        return formatter
    }()

    private enum RowSizing {
        static let dateWidth: CGFloat = 78
        static let categoryWidth: CGFloat = 56
        static let amountWidth: CGFloat = 124
    }

}
