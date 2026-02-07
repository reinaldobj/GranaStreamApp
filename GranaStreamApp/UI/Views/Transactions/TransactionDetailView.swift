import SwiftUI

struct TransactionDetailView: View {
    let transaction: TransactionSummaryDto

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Tipo", value: transaction.type.label)
                    LabeledContent("Data", value: transaction.date.formattedDate())
                    LabeledContent("Valor", value: CurrencyFormatter.string(from: transaction.amount))
                    LabeledContent("Descrição", value: transaction.description ?? "-")
                } header: {
                    sectionHeader("Resumo", topPadding: 10)
                }

                Section {
                    LabeledContent("Conta", value: transaction.accountName ?? "-")
                    LabeledContent("Categoria", value: transaction.categoryName ?? "-")
                    LabeledContent("De", value: transaction.fromAccountName ?? "-")
                    LabeledContent("Para", value: transaction.toAccountName ?? "-")
                } header: {
                    sectionHeader("Detalhes")
                }
            }
            .listRowBackground(DS.Colors.surface)
            .scrollContentBackground(.hidden)
            .background(DS.Colors.background)
        }
        .tint(DS.Colors.primary)
    }

    private func sectionHeader(_ title: String, topPadding: CGFloat = 0) -> some View {
        Text(title)
            .textCase(nil)
            .font(AppTheme.Typography.section)
            .foregroundColor(DS.Colors.textPrimary)
            .padding(.top, topPadding)
    }
}
