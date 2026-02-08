import SwiftUI

struct RecurrenceFormView: View {
    let existing: RecurrenceResponseDto?
    var onComplete: () -> Void

    @EnvironmentObject private var referenceStore: ReferenceDataStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var parentViewModel = RecurrencesViewModel()
    @StateObject private var viewModel: RecurrenceFormViewModelImpl

    init(existing: RecurrenceResponseDto?, onComplete: @escaping () -> Void = {}) {
        self.existing = existing
        self.onComplete = onComplete
        let parent = RecurrencesViewModel()
        _parentViewModel = StateObject(wrappedValue: parent)
        _viewModel = StateObject(wrappedValue: RecurrenceFormViewModelImpl(existing: existing, recurrencesViewModel: parent))
    }

    var body: some View {
        FormViewContainer(
            viewModel: viewModel,
            onSaveSuccess: {
                onComplete()
                dismiss()
            }
        ) {
            VStack(spacing: DS.Spacing.item) {
                // Tipo
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tipo")
                        .font(DS.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)

                    Picker("Tipo", selection: $viewModel.type) {
                        ForEach(TransactionType.allCases, id: \.rawValue) { item in
                            Text(item.label).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Frequência
                TransactionPickerRow(
                    label: "Frequência",
                    value: viewModel.frequency.label,
                    placeholder: "Selecione"
                ) {
                    ForEach(RecurrenceFrequency.allCases) { item in
                        Button(item.label) {
                            viewModel.frequency = item
                        }
                    }
                }

                // Data início
                TransactionDateRow(label: "Início", date: $viewModel.startDate)

                // Toggle data fim
                Toggle(isOn: $viewModel.hasEndDate) {
                    Text("Tem data fim")
                        .font(DS.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)
                }
                .tint(DS.Colors.primary)

                // Data fim (condicional)
                if viewModel.hasEndDate {
                    TransactionDateRow(label: "Fim", date: $viewModel.endDate)
                }

                // Categoria
                TransactionPickerRow(
                    label: "Categoria",
                    value: categoryName,
                    placeholder: "Selecione a categoria"
                ) {
                    categoryMenu()
                }

                // Conta
                TransactionPickerRow(
                    label: "Conta",
                    value: accountName,
                    placeholder: "Selecione a conta"
                ) {
                    accountMenu()
                }

                // Valor
                TransactionField(label: "Valor") {
                    CurrencyTextField(placeholder: "R$ 0,00", text: $viewModel.amount)
                }

                // Descrição
                TransactionField(label: "Descrição") {
                    TextField("Ex: Aluguel", text: $viewModel.description)
                        .textInputAutocapitalization(.sentences)
                }
            }
            .task {
                await referenceStore.loadIfNeeded()
            }
        }
        .tint(DS.Colors.primary)
    }

    private var accountName: String? {
        referenceStore.accounts.first(where: { $0.id == viewModel.accountId })?.name
    }

    private var categoryName: String? {
        referenceStore.categories.first(where: { $0.id == viewModel.categoryId })?.name
    }

    @ViewBuilder
    private func accountMenu() -> some View {
        AccountMenuContent(
            accounts: referenceStore.accounts,
            selection: $viewModel.accountId
        )
    }

    @ViewBuilder
    private func categoryMenu() -> some View {
        CategoryMenuContent(
            sections: groupCategoriesForPicker(referenceStore.categories, transactionType: viewModel.type),
            selection: $viewModel.categoryId
        )
    }
}
