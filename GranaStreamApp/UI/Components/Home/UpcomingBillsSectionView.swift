import SwiftUI

struct UpcomingBillsSectionView: View {
    let bills: [BillItem]

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.item) {
                AppSectionHeader(text: "Próximas contas a vencer")
                VStack(spacing: AppTheme.Spacing.base) {
                    ForEach(Array(bills.enumerated()), id: \.element.id) { index, bill in
                        BillRowView(bill: bill)
                        if index < bills.count - 1 {
                            Divider()
                                .overlay(DS.Colors.border)
                        }
                    }
                }
            }
        }
    }
}

struct BillRowView: View {
    let bill: BillItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(bill.title)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(DS.Colors.textPrimary)
                Text(bill.dueDateText)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)
            }
            Spacer()
            Text("R$ \(formatAmount(bill.amount))")
                .font(AppTheme.Typography.body)
                .foregroundColor(DS.Colors.error)
        }
    }

    private func formatAmount(_ amount: Double) -> String {
        let formatted = String(format: "%.2f", amount)
        return formatted.replacingOccurrences(of: ".", with: ",")
    }
}
