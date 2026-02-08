import SwiftUI

/// Formulário para criar/editar transações
struct TransactionFormView: View {
    let existing: TransactionSummaryDto?
    var onComplete: () -> Void

    @StateObject private var viewModel = TransactionFormViewModel()
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

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DS.Spacing.item) {
                        transactionCard
                    }
                    .padding(.horizontal, DS.Spacing.screen)
                    .padding(.top, DS.Spacing.screen + 10)
                    .padding(.bottom, DS.Spacing.screen * 2)
                }
            }
            .task(id: existing?.id) { prefill() }
            .onChange(of: type) { _, newValue in
                guard newValue != .transfer else {
                    categoryId = ""
                    return
                }
                let validIds = Set(
                    groupCategoriesForPicker(referenceStore.categories, transactionType: newValue)
                        .flatMap { $0.children.map(\.id) }
                )
                if !categoryId.isEmpty && !validIds.contains(categoryId) {
                    categoryId = ""
                }
            }
            .errorAlert(message: $viewModel.errorMessage)
        }
        .tint(DS.Colors.primary)
    }

    private var transactionCard: some View {
        VStack(spacing: DS.Spacing.item) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tipo")
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)

                Picker("Tipo", selection: $type) {
                    ForEach(TransactionType.allCases) { item in
                        Text(item.label).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(existing != nil)
            }

            TransactionDateRow(label: "Data", date: $date)

            if type == .transfer {
                TransactionPickerRow(
                    label: "De",
                    value: fromAccountName,
                    placeholder: "Selecione"
                ) {
                    accountMenu(selection: $fromAccountId)
                }

                TransactionPickerRow(
                    label: "Para",
                    value: toAccountName,
                    placeholder: "Selecione"
                ) {
                    accountMenu(selection: $toAccountId)
                }
            } else {
                TransactionPickerRow(
                    label: "Categoria",
                    value: categoryName,
                    placeholder: "Selecione a categoria"
                ) {
                    categoryMenu(selection: $categoryId)
                }

                TransactionPickerRow(
                    label: "Conta",
                    value: accountName,
                    placeholder: "Selecione a conta"
                ) {
                    accountMenu(selection: $accountId)
                }
            }

            TransactionField(label: "Valor") {
                CurrencyTextField(placeholder: "R$ 0,00", text: $amount)
            }

            TransactionField(label: "Título") {
                TextField("Ex: Cinema", text: $description)
                    .textInputAutocapitalization(.sentences)
            }

            TransactionPrimaryButton(
                title: viewModel.isLoading ? "Salvando..." : "Salvar",
                isDisabled: !isValid || viewModel.isLoading
            ) {
                Task { await save() }
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(DS.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: DS.Colors.border.opacity(0.35), radius: 12, x: 0, y: 6)
    }

    private var filteredCategorySections: [CategorySection] {
        guard type != .transfer else { return [] }
        return groupCategoriesForPicker(referenceStore.categories, transactionType: type)
    }

    private var isValid: Bool {
        if amountValue == nil { return false }
        if type == .transfer {
            return !fromAccountId.isEmpty && !toAccountId.isEmpty
        }
        return !accountId.isEmpty
    }

    private var amountValue: Double? {
        CurrencyTextField.value(from: amount)
    }

    private var accountName: String? {
        referenceStore.accounts.first(where: { $0.id == accountId })?.name
    }

    private var fromAccountName: String? {
        referenceStore.accounts.first(where: { $0.id == fromAccountId })?.name
    }

    private var toAccountName: String? {
        referenceStore.accounts.first(where: { $0.id == toAccountId })?.name
    }

    private var categoryName: String? {
        referenceStore.categories.first(where: { $0.id == categoryId })?.name
    }

    @ViewBuilder
    private func categoryMenu(selection: Binding<String>) -> some View {
        CategoryMenuContent(sections: filteredCategorySections, selection: selection)
    }

    @ViewBuilder
    private func accountMenu(selection: Binding<String>) -> some View {
        AccountMenuContent(accounts: referenceStore.accounts, selection: selection)
    }

    private func prefill() {
        type = .expense
        date = Date()
        amount = ""
        description = ""
        accountId = ""
        categoryId = ""
        fromAccountId = ""
        toAccountId = ""

        guard let existing else { return }
        type = existing.type
        date = existing.date
        amount = CurrencyFormatter.string(from: existing.amount)
        description = existing.description ?? ""
        accountId = existing.accountId ?? ""
        categoryId = existing.categoryId ?? ""
        fromAccountId = existing.fromAccountId ?? ""
        toAccountId = existing.toAccountId ?? ""
    }

    private func save() async {
        viewModel.isLoading = true
        defer { viewModel.isLoading = false }

        do {
            if let existing {
                try await viewModel.updateTransaction(
                    id: existing.id,
                    amount: amount,
                    date: date,
                    description: description,
                    categoryId: categoryId,
                    fromAccountId: fromAccountId,
                    toAccountId: toAccountId
                )
            } else {
                try await viewModel.createTransaction(
                    type: type,
                    date: date,
                    amount: amount,
                    description: description,
                    accountId: accountId,
                    categoryId: categoryId,
                    fromAccountId: fromAccountId,
                    toAccountId: toAccountId
                )
            }
            onComplete()
            dismiss()
        } catch {
            viewModel.errorMessage = error.userMessage
        }
    }
}
