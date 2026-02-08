import SwiftUI

struct AccountCardView: View {
    let account: AccountSummary

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.base) {
            Text(account.name)
                .font(DS.Typography.body)
                .foregroundColor(DS.Colors.textPrimary)
            Text("R$ \(formatAmount(account.balance))")
                .font(DS.Typography.section)
                .foregroundColor(account.balance >= 0 ? DS.Colors.success : DS.Colors.error)
        }
        .padding(DS.Spacing.item)
        .frame(width: 160, alignment: .leading)
        .background(DS.Colors.background)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.field)
                .stroke(DS.Colors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.field))
    }

    private func formatAmount(_ amount: Double) -> String {
        let formatted = String(format: "%.2f", amount)
        return formatted.replacingOccurrences(of: ".", with: ",")
    }
}
