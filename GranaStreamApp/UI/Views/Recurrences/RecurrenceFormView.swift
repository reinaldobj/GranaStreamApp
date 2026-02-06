import SwiftUI

struct RecurrenceFormView: View {
    let existing: RecurrenceResponseDto?
    var onComplete: () -> Void

    @EnvironmentObject private var referenceStore: ReferenceDataStore
    @Environment(\.dismiss) private var dismiss

    @State private var type: TransactionType = .expense
    @State private var amount = ""
    @State private var description = ""
    @State private var accountId: String = ""
    @State private var categoryId: String = ""
    @State private var frequency: RecurrenceFrequency = .monthly
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var hasEndDate = false

    @State private var errorMessage: String?
    @StateObject private var viewModel = RecurrencesViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Transação modelo") {
                    Picker("Tipo", selection: $type) {
                        ForEach(TransactionType.allCases) { item in
                            Text(item.label).tag(item)
                        }
                    }
                    TextField("Valor", text: $amount)
                        .keyboardType(.decimalPad)
                    TextField("Descrição", text: $description)
                    Picker("Conta", selection: $accountId) {
                        Text("Selecione").tag("")
                        ForEach(referenceStore.accounts) { account in
                            Text(account.name ?? "Conta").tag(account.id)
                        }
                    }
                    Picker("Categoria", selection: $categoryId) {
                        Text("Selecione").tag("")
                        ForEach(referenceStore.categories) { category in
                            Text(category.name ?? "Categoria").tag(category.id)
                        }
                    }
                }

                Section("Recorrência") {
                    Picker("Frequência", selection: $frequency) {
                        ForEach(RecurrenceFrequency.allCases) { item in
                            Text(item.label).tag(item)
                        }
                    }
                    DatePicker("Início", selection: $startDate, displayedComponents: .date)
                    Toggle("Tem data fim", isOn: $hasEndDate)
                    if hasEndDate {
                        DatePicker("Fim", selection: $endDate, displayedComponents: .date)
                    }
                }
            }
            .listRowBackground(DS.Colors.surface)
            .scrollContentBackground(.hidden)
            .background(DS.Colors.background)
            .navigationTitle(existing == nil ? "Nova recorrência" : "Editar recorrência")
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
                    .disabled(!isValid)
                }
            }
            .task { prefill() }
            .errorAlert(message: $errorMessage)
        }
        .tint(DS.Colors.primary)
    }

    private var isValid: Bool {
        Double(amount.replacingOccurrences(of: ",", with: ".")) != nil && !accountId.isEmpty
    }

    private func prefill() {
        guard let existing else { return }
        type = existing.templateTransaction.type
        amount = String(format: "%.2f", existing.templateTransaction.amount)
        description = existing.templateTransaction.description ?? ""
        accountId = existing.templateTransaction.accountId ?? ""
        categoryId = existing.templateTransaction.categoryId ?? ""
        frequency = existing.frequency
        startDate = existing.startDate
        if let end = existing.endDate {
            hasEndDate = true
            endDate = end
        }
    }

    private func save() async {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            errorMessage = "Informe um valor válido."
            return
        }
        let template = RecurrenceTemplateTransactionRequestDto(
            type: type,
            amount: amountValue,
            description: description.isEmpty ? nil : description,
            accountId: accountId.isEmpty ? nil : accountId,
            categoryId: categoryId.isEmpty ? nil : categoryId
        )
        let dayOfMonth = Calendar.current.component(.day, from: startDate)

        if let existing {
            let request = UpdateRecurrenceRequestDto(
                templateTransaction: template,
                frequency: frequency,
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil,
                dayOfMonth: frequency == .monthly ? dayOfMonth : nil
            )
            let success = await viewModel.update(id: existing.id, request: request)
            if success {
                onComplete()
                dismiss()
            } else {
                errorMessage = viewModel.errorMessage
            }
        } else {
            let request = CreateRecurrenceRequestDto(
                templateTransaction: template,
                frequency: frequency,
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil,
                dayOfMonth: frequency == .monthly ? dayOfMonth : nil
            )
            let success = await viewModel.create(request: request)
            if success {
                onComplete()
                dismiss()
            } else {
                errorMessage = viewModel.errorMessage
            }
        }
    }
}
