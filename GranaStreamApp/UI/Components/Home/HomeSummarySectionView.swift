import SwiftUI

struct HomeSummarySectionView: View {
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.item) {
                AppSectionHeader(text: "Resumo do mês")
                HStack(spacing: AppTheme.Spacing.item) {
                    MetricMiniCard(title: "Saldo", value: "R$ 1.250,00", valueColor: DS.Colors.success)
                    MetricMiniCard(title: "Entradas", value: "R$ 6.000,00", valueColor: DS.Colors.success)
                    MetricMiniCard(title: "Saídas", value: "R$ 4.750,00", valueColor: DS.Colors.error)
                }
            }
        }
    }
}

struct MetricMiniCard: View {
    let title: String
    let value: String
    let valueColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)
            Text(value)
                .font(AppTheme.Typography.body)
                .foregroundColor(valueColor)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Colors.background)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.field)
                .stroke(DS.Colors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.field))
    }
}
