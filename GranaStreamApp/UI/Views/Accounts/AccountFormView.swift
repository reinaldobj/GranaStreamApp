import SwiftUI

struct AccountFormView: View {
    let existing: AccountResponseDto?
    var onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var type: AccountType = .contaCorrente
    @State private var initialBalance = ""
    @State private var errorMessage: String?

    @StateObject private var viewModel = AccountsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                TextField("Nome", text: $name)
                Picker("Tipo", selection: $type) {
                    ForEach(AccountType.allCases) { type in
                        Text(type.label).tag(type)
                    }
                }
                if existing == nil {
                    TextField("Saldo inicial", text: $initialBalance)
                        .keyboardType(.decimalPad)
                }
            }
            .listRowBackground(DS.Colors.surface)
            .scrollContentBackground(.hidden)
            .background(DS.Colors.background)
            .navigationTitle(existing == nil ? "Nova conta" : "Editar conta")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Salvar") {
                        Task { await save() }
                    }
                    .disabled(name.isEmpty || (existing == nil && initialBalance.isEmpty))
                }
            }
            .task { prefill() }
            .errorAlert(message: $errorMessage)
        }
        .tint(DS.Colors.primary)
    }

    private func prefill() {
        guard let existing else { return }
        name = existing.name ?? ""
        type = existing.accountType
    }

    private func save() async {
        let balanceValue = Double(initialBalance.replacingOccurrences(of: ",", with: ".")) ?? 0
        if let existing {
            let success = await viewModel.update(account: existing, name: name, type: type)
            if success {
                onComplete()
                dismiss()
            } else {
                errorMessage = viewModel.errorMessage
            }
        } else {
            let success = await viewModel.create(name: name, type: type, initialBalance: balanceValue)
            if success {
                onComplete()
                dismiss()
            } else {
                errorMessage = viewModel.errorMessage
            }
        }
    }
}
