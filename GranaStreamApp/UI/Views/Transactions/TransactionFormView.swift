import SwiftUI

// TODO: [TECH-DEBT] accountMenu e categoryMenu duplicados com UnifiedEntryFormView - extrair para componentes reutilizáveis
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
            ZStack {
                DS.Colors.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.item) {
                        transactionCard
                    }
                    .padding(.horizontal, AppTheme.Spacing.screen)
                    .padding(.top, AppTheme.Spacing.screen + 10)
                    .padding(.bottom, AppTheme.Spacing.screen * 2)
                }
            }
            .task(id: existing?.id) { prefill() }
            .onChange(of: type) { newValue in
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
            .errorAlert(message: $errorMessage)
        }
        .tint(DS.Colors.primary)
    }

    private var transactionCard: some View {
        VStack(spacing: AppTheme.Spacing.item) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tipo")
                    .font(AppTheme.Typography.caption)
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
                title: isLoading ? "Salvando..." : "Salvar",
                isDisabled: !isValid || isLoading
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
        Button("Limpar seleção") {
            selection.wrappedValue = ""
        }
        .disabled(selection.wrappedValue.isEmpty)

        if filteredCategorySections.isEmpty {
            Text("Sem categorias")
                .font(AppTheme.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)
        } else {
            ForEach(filteredCategorySections) { section in
                Text(section.title)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)
                    .disabled(true)
                ForEach(section.children) { child in
                    Button(child.name ?? "Categoria") {
                        selection.wrappedValue = child.id
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func accountMenu(selection: Binding<String>) -> some View {
        Button("Limpar seleção") {
            selection.wrappedValue = ""
        }
        .disabled(selection.wrappedValue.isEmpty)

        if referenceStore.accounts.isEmpty {
            Text("Sem contas")
                .font(AppTheme.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)
        } else {
            ForEach(referenceStore.accounts) { account in
                Button(account.name ?? "Conta") {
                    selection.wrappedValue = account.id
                }
            }
        }
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
        isLoading = true
        defer { isLoading = false }
        guard let amountValue else {
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
            errorMessage = error.userMessage
        }
    }
}
