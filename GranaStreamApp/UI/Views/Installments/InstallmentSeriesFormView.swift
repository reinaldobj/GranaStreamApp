import SwiftUI

struct InstallmentSeriesFormView: View {
    let existing: InstallmentSeriesResponseDto?
    var onComplete: () -> Void

    @EnvironmentObject private var referenceStore: ReferenceDataStore
    @Environment(\.dismiss) private var dismiss

    @State private var description = ""
    @State private var categoryId: String = ""
    @State private var accountId: String = ""
    @State private var totalAmount = ""
    @State private var installments = ""
    @State private var firstDueDate = Date()
    @State private var errorMessage: String?

    @StateObject private var viewModel = InstallmentSeriesViewModel()

    var body: some View {
        NavigationStack {
            Form {
                TextField("Descrição", text: $description)
                Picker("Categoria", selection: $categoryId) {
                    Text("Selecione").tag("")
                    ForEach(referenceStore.categories) { category in
                        Text(category.name ?? "Categoria").tag(category.id)
                    }
                }
                Picker("Conta padrão", selection: $accountId) {
                    Text("Nenhuma").tag("")
                    ForEach(referenceStore.accounts) { account in
                        Text(account.name ?? "Conta").tag(account.id)
                    }
                }
                TextField("Valor total", text: $totalAmount)
                    .keyboardType(.decimalPad)
                TextField("Parcelas", text: $installments)
                    .keyboardType(.numberPad)
                DatePicker("Primeiro vencimento", selection: $firstDueDate, displayedComponents: .date)
            }
            .listRowBackground(DS.Colors.surface)
            .scrollContentBackground(.hidden)
            .background(DS.Colors.background)
            .navigationTitle(existing == nil ? "Nova parcelada" : "Editar parcelada")
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
        Double(totalAmount.replacingOccurrences(of: ",", with: ".")) != nil && Int(installments) != nil && !categoryId.isEmpty
    }

    private func prefill() {
        guard let existing else { return }
        description = existing.description ?? ""
        categoryId = existing.categoryId
        accountId = existing.accountDefaultId ?? ""
        totalAmount = String(format: "%.2f", existing.totalAmount)
        installments = String(existing.installmentsPlanned)
        firstDueDate = existing.firstDueDate
    }

    private func save() async {
        guard let totalValue = Double(totalAmount.replacingOccurrences(of: ",", with: ".")),
              let installmentsValue = Int(installments) else {
            errorMessage = "Informe valores válidos."
            return
        }

        if let existing {
            let request = UpdateInstallmentSeriesRequestDto(
                description: description.isEmpty ? nil : description,
                categoryId: categoryId.isEmpty ? nil : categoryId,
                accountDefaultId: accountId.isEmpty ? nil : accountId,
                totalAmount: totalValue,
                installmentsPlanned: installmentsValue,
                firstDueDate: firstDueDate
            )
            let success = await viewModel.update(id: existing.id, request: request)
            if success {
                onComplete()
                dismiss()
            } else {
                errorMessage = viewModel.errorMessage
            }
        } else {
            let request = CreateInstallmentSeriesRequestDto(
                description: description.isEmpty ? nil : description,
                categoryId: categoryId,
                accountDefaultId: accountId.isEmpty ? nil : accountId,
                totalAmount: totalValue,
                installmentsPlanned: installmentsValue,
                firstDueDate: firstDueDate
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
