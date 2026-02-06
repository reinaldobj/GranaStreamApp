import SwiftUI

struct AccountCardView: View {
    let account: AccountSummary

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.base) {
            Text(account.name)
                .font(AppTheme.Typography.body)
                .foregroundColor(DS.Colors.textPrimary)
            Text("R$ \(formatAmount(account.balance))")
                .font(AppTheme.Typography.section)
                .foregroundColor(account.balance >= 0 ? DS.Colors.success : DS.Colors.error)
        }
        .padding(AppTheme.Spacing.item)
        .frame(width: 160, alignment: .leading)
        .background(DS.Colors.background)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.field)
                .stroke(DS.Colors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.field))
    }

    private func formatAmount(_ amount: Double) -> String {
        let formatted = String(format: "%.2f", amount)
        return formatted.replacingOccurrences(of: ".", with: ",")
    }
}
