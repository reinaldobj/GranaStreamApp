import SwiftUI

struct SettlePayableFormView: View {
    let payable: PayableListItemDto
    let actionTitle: String
    let transactionType: TransactionType
    let onConfirm: (SettlePayableRequestDto) async -> Bool

    @EnvironmentObject private var referenceStore: ReferenceDataStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SettlePayableFormViewModelImpl

    init(
        payable: PayableListItemDto,
        actionTitle: String,
        transactionType: TransactionType,
        onConfirm: @escaping (SettlePayableRequestDto) async -> Bool
    ) {
        self.payable = payable
        self.actionTitle = actionTitle
        self.transactionType = transactionType
        self.onConfirm = onConfirm
        _viewModel = StateObject(wrappedValue: SettlePayableFormViewModelImpl(
            payable: payable,
            actionTitle: actionTitle,
            transactionType: transactionType,
            onConfirm: onConfirm
        ))
    }

    var body: some View {
        FormViewContainer(
            viewModel: viewModel,
            onSaveSuccess: {
                dismiss()
            }
        ) {
            VStack(spacing: DS.Spacing.item) {
                // Detalhes do pagável
                detailsCard

                // Campos do formulário
                TransactionPickerRow(
                    label: "Conta",
                    value: accountName,
                    placeholder: "Selecione a conta"
                ) {
                    AccountMenuContent(
                        accounts: referenceStore.accounts,
                        selection: $viewModel.accountId
                    )
                }

                TransactionPickerRow(
                    label: "Categoria",
                    value: categoryName,
                    placeholder: "Selecione a categoria"
                ) {
                    CategoryMenuContent(
                        sections: groupCategoriesForPicker(referenceStore.categories, transactionType: transactionType),
                        selection: $viewModel.categoryId
                    )
                }

                TransactionDateRow(label: "Data de Pagamento", date: $viewModel.paidDate)
            }
            .task {
                await referenceStore.loadIfNeeded()
            }
        }
        .tint(DS.Colors.primary)
    }

    private var detailsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: DS.Spacing.base) {
                HStack {
                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        Text("Pagável")
                            .font(DS.Typography.caption)
                            .foregroundColor(DS.Colors.textSecondary)
                        Text(payable.description ?? "N/A")
                            .font(DS.Typography.section)
                            .foregroundColor(DS.Colors.textPrimary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: DS.Spacing.xs) {
                        Text("Valor")
                            .font(DS.Typography.caption)
                            .foregroundColor(DS.Colors.textSecondary)
                        Text(CurrencyFormatter.string(from: payable.amount))
                            .font(DS.Typography.section)
                            .foregroundColor(DS.Colors.textPrimary)
                    }
                }

                Divider()
                    .padding(.vertical, DS.Spacing.xs)

                HStack {
                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        Text("Data de Vencimento")
                            .font(DS.Typography.caption)
                            .foregroundColor(DS.Colors.textSecondary)
                        Text(payable.dueDate.formatted(date: .abbreviated, time: .omitted))
                            .font(DS.Typography.body)
                            .foregroundColor(DS.Colors.textPrimary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: DS.Spacing.xs) {
                        Text("Status")
                            .font(DS.Typography.caption)
                            .foregroundColor(DS.Colors.textSecondary)
                        Text(payable.status.label)
                            .font(DS.Typography.body)
                            .foregroundColor(payable.status == .pending ? DS.Colors.warning : DS.Colors.success)
                    }
                }
            }
        }
    }

    private var accountName: String? {
        referenceStore.accounts.first(where: { $0.id == viewModel.accountId })?.name
    }

    private var categoryName: String? {
        referenceStore.categories.first(where: { $0.id == viewModel.categoryId })?.name
    }
}
