import SwiftUI

struct TransactionDetailView: View {
    let transaction: TransactionSummaryDto
    var onEdit: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Resumo") {
                    LabeledContent("Tipo", value: transaction.type.label)
                    LabeledContent("Data", value: transaction.date.formattedDate())
                    LabeledContent("Valor", value: CurrencyFormatter.string(from: transaction.amount))
                    LabeledContent("Descrição", value: transaction.description ?? "-")
                }

                Section("Detalhes") {
                    LabeledContent("Conta", value: transaction.accountName ?? "-")
                    LabeledContent("Categoria", value: transaction.categoryName ?? "-")
                    LabeledContent("De", value: transaction.fromAccountName ?? "-")
                    LabeledContent("Para", value: transaction.toAccountName ?? "-")
                }
            }
            .listRowBackground(DS.Colors.surface)
            .scrollContentBackground(.hidden)
            .background(DS.Colors.background)
            .navigationTitle("Detalhe")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Editar") {
                        dismiss()
                        onEdit?()
                    }
                }
            }
        }
        .tint(DS.Colors.primary)
    }
}
