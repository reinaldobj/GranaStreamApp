import SwiftUI

struct TransactionFormView: View {
    let existing: TransactionSummaryDto?
    var onComplete: () -> Void

    @EnvironmentObject private var referenceStore: ReferenceDataStore
    @Environment(\.dismiss) private var dismiss

    @State private var type: TransactionType = .expense
    @State private var date = Date()
    @State private var amount = ""
    @State private var description = ""
    @State private var accountId: String = ""
    @State private var categoryId: String = ""
    @State private var fromAccountId: String = ""
    @State private var toAccountId: String = ""

    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Tipo") {
                    Picker("Tipo", selection: $type) {
                        ForEach(TransactionType.allCases) { item in
                            Text(item.label).tag(item)
                        }
                    }
                    .disabled(existing != nil)
                }

                Section("Dados") {
                    DatePicker("Data", selection: $date, displayedComponents: .date)
                    TextField("Valor", text: $amount)
                        .keyboardType(.decimalPad)
                    TextField("Descrição", text: $description)
                }

                if type == .transfer {
                    Section("Contas") {
                        Picker("De", selection: $fromAccountId) {
                            Text("Selecione").tag("")
                            ForEach(referenceStore.accounts) { account in
                                Text(account.name ?? "Conta").tag(account.id)
                            }
                        }
                        Picker("Para", selection: $toAccountId) {
                            Text("Selecione").tag("")
                            ForEach(referenceStore.accounts) { account in
                                Text(account.name ?? "Conta").tag(account.id)
                            }
                        }
                    }
                } else {
                    Section("Conta") {
                        Picker("Conta", selection: $accountId) {
                            Text("Selecione").tag("")
                            ForEach(referenceStore.accounts) { account in
                                Text(account.name ?? "Conta").tag(account.id)
                            }
                        }
                    }

                    Section("Categoria") {
                        Picker("Categoria", selection: $categoryId) {
                            Text("Selecione").tag("")
                            ForEach(referenceStore.categories) { category in
                                Text(category.name ?? "Categoria").tag(category.id)
                            }
                        }
                    }
                }
            }
            .listRowBackground(DS.Colors.surface)
            .scrollContentBackground(.hidden)
            .background(DS.Colors.background)
            .navigationTitle(existing == nil ? "Novo lançamento" : "Editar lançamento")
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
        if Double(amount.replacingOccurrences(of: ",", with: ".")) == nil { return false }
        if type == .transfer {
            return !fromAccountId.isEmpty && !toAccountId.isEmpty
        }
        return !accountId.isEmpty
    }

    private func prefill() {
        guard let existing else { return }
        type = existing.type
        date = existing.date
        amount = String(format: "%.2f", existing.amount)
        description = existing.description ?? ""
        accountId = existing.accountId ?? ""
        categoryId = existing.categoryId ?? ""
        fromAccountId = existing.fromAccountId ?? ""
        toAccountId = existing.toAccountId ?? ""
    }

    private func save() async {
        isLoading = true
        defer { isLoading = false }
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            errorMessage = "Informe um valor válido."
            return
        }

        do {
            if let existing {
                let request = UpdateTransactionRequestDto(
                    amount: amountValue,
                    date: date,
                    description: description.isEmpty ? nil : description,
                    categoryId: categoryId.isEmpty ? nil : categoryId,
                    fromAccountId: fromAccountId.isEmpty ? nil : fromAccountId,
                    toAccountId: toAccountId.isEmpty ? nil : toAccountId
                )
                let _: TransactionResponseDto = try await APIClient.shared.request(
                    "/api/v1/transactions/\(existing.id)",
                    method: "PATCH",
                    body: AnyEncodable(request)
                )
            } else {
                let request = CreateTransactionRequestDto(
                    type: type,
                    date: date,
                    amount: amountValue,
                    description: description.isEmpty ? nil : description,
                    accountId: type == .transfer ? nil : (accountId.isEmpty ? nil : accountId),
                    categoryId: type == .transfer ? nil : (categoryId.isEmpty ? nil : categoryId),
                    fromAccountId: type == .transfer ? (fromAccountId.isEmpty ? nil : fromAccountId) : nil,
                    toAccountId: type == .transfer ? (toAccountId.isEmpty ? nil : toAccountId) : nil
                )
                let _: CreateTransactionResponseDto = try await APIClient.shared.request(
                    "/api/v1/transactions",
                    method: "POST",
                    body: AnyEncodable(request)
                )
            }
            onComplete()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
