import SwiftUI

struct TransactionDetailView: View {
    let transaction: TransactionSummaryDto

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DS.Spacing.item) {
                        detailSection(
                            title: "Resumo",
                            rows: [
                                DetailRow(label: "Tipo", value: transaction.type.label),
                                DetailRow(label: "Data", value: transaction.date.formattedDate()),
                                DetailRow(label: "Valor", value: CurrencyFormatter.string(from: transaction.amount)),
                                DetailRow(label: "Descrição", value: transaction.description ?? "-")
                            ]
                        )

                        detailSection(
                            title: "Detalhes",
                            rows: [
                                DetailRow(label: "Conta", value: transaction.accountName ?? "-"),
                                DetailRow(label: "Categoria", value: transaction.categoryName ?? "-"),
                                DetailRow(label: "De", value: transaction.fromAccountName ?? "-"),
                                DetailRow(label: "Para", value: transaction.toAccountName ?? "-")
                            ]
                        )
                    }
                    .padding(.horizontal, DS.Spacing.screen)
                    .padding(.top, DS.Spacing.screen + 10)
                    .padding(.bottom, DS.Spacing.screen * 2)
                }
            }
        }
        .tint(DS.Colors.primary)
    }

    private func detailSection(title: String, rows: [DetailRow]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(DS.Typography.section)
                .foregroundColor(DS.Colors.textPrimary)

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    detailRow(label: row.label, value: row.value)

                    if index < rows.count - 1 {
                        Divider()
                            .overlay(DS.Colors.border)
                    }
                }
            }
        }
        .padding(20)
        .background(DS.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: DS.Colors.border.opacity(0.25), radius: 10, x: 0, y: 6)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(DS.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)

            Spacer(minLength: 8)

            Text(value)
                .font(DS.Typography.body)
                .foregroundColor(DS.Colors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 12)
    }
}

private struct DetailRow {
    let label: String
    let value: String
}
