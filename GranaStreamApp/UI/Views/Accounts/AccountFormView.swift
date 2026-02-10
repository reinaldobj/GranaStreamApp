import SwiftUI

struct AccountFormView: View {
    let existing: AccountResponseDto?
    @ObservedObject var parentViewModel: AccountsViewModel
    var onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AccountFormViewModel

    init(existing: AccountResponseDto?, viewModel: AccountsViewModel, onComplete: @escaping () -> Void) {
        self.existing = existing
        self.parentViewModel = viewModel
        self.onComplete = onComplete
        _viewModel = StateObject(wrappedValue: AccountFormViewModel(existing: existing, accountsViewModel: viewModel))
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
                AccountField(label: "Nome") {
                    TextField("Nome da conta", text: $viewModel.name)
                        .textInputAutocapitalization(.words)
                }

                TransactionPickerRow(
                    label: "Tipo",
                    value: viewModel.type.label,
                    placeholder: "Selecione"
                ) {
                    ForEach(AccountType.allCases) { item in
                        Button(item.label) {
                            viewModel.type = item
                        }
                    }
                }

                if existing == nil {
                    AccountField(label: "Saldo inicial") {
                        CurrencyMaskedTextField(text: $viewModel.initialBalance, placeholder: "R$ 0,00")
                    }
                }
            }
        }
        .tint(DS.Colors.primary)
    }
}
