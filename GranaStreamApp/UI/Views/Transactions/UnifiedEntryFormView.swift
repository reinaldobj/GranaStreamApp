import SwiftUI

// TODO: [TECH-DEBT] View monolítica com 571 linhas - Extrair SingleEntryForm, InstallmentEntryForm, RecurringEntryForm como Views separadas
struct UnifiedEntryFormView: View {
    var onComplete: (String) -> Void

    @StateObject private var viewModel = UnifiedEntryFormViewModel()
    @EnvironmentObject private var referenceStore: ReferenceDataStore
    @Environment(\.dismiss) private var dismiss

    @State private var mode: UnifiedEntryMode
    @State private var single = SingleEntryState()
    @State private var installment = InstallmentEntryState()
    @State private var recurrence = RecurringEntryState()

    init(
        initialMode: UnifiedEntryMode = .single,
        onComplete: @escaping (String) -> Void = { _ in }
    ) {
        self.onComplete = onComplete
        _mode = State(initialValue: initialMode)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DS.Spacing.item) {
                        formCard
                    }
                    .padding(.horizontal, DS.Spacing.screen)
                    .padding(.top, DS.Spacing.screen + 10)
                    .padding(.bottom, DS.Spacing.screen * 2)
                }
            }
            .task {
                await referenceStore.loadIfNeeded()
            }
            .onChange(of: single.type) { _, newValue in
                guard newValue != .transfer else {
                    single.categoryId = ""
                    return
                }
                let validIds = Set(
                    groupCategoriesForPicker(referenceStore.categories, transactionType: newValue)
                        .flatMap { $0.children.map(\.id) }
                )
                if !single.categoryId.isEmpty && !validIds.contains(single.categoryId) {
                    single.categoryId = ""
                }
            }
            .onChange(of: recurrence.type) { _, newValue in
                let validIds = Set(
                    groupCategoriesForPicker(referenceStore.categories, transactionType: newValue)
                        .flatMap { $0.children.map(\.id) }
                )
                if !recurrence.categoryId.isEmpty && !validIds.contains(recurrence.categoryId) {
                    recurrence.categoryId = ""
                }
            }
            .errorAlert(message: $viewModel.errorMessage)
        }
        .tint(DS.Colors.primary)
    }

    private var formCard: some View {
        VStack(spacing: DS.Spacing.item) {
            EntryModePicker(selection: $mode)

            switch mode {
            case .single:
                singleFields
            case .installment:
                installmentFields
            case .recurring:
                recurringFields
            }

            TransactionPrimaryButton(
                title: viewModel.isLoading ? "Salvando..." : "Salvar",
                isDisabled: !isCurrentModeValid || viewModel.isLoading
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

    private var singleFields: some View {
        VStack(spacing: DS.Spacing.item) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tipo")
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)

                Picker("Tipo", selection: $single.type) {
                    ForEach(TransactionType.allCases) { item in
                        Text(item.label).tag(item)
                    }
                }
                .pickerStyle(.segmented)
            }

            TransactionDateRow(label: "Data", date: $single.date)

            if single.type == .transfer {
                TransactionPickerRow(
                    label: "De",
                    value: accountName(for: single.fromAccountId),
                    placeholder: "Selecione"
                ) {
                    AccountMenuContent(accounts: referenceStore.accounts, selection: $single.fromAccountId)
                }

                TransactionPickerRow(
                    label: "Para",
                    value: accountName(for: single.toAccountId),
                    placeholder: "Selecione"
                ) {
                    AccountMenuContent(accounts: referenceStore.accounts, selection: $single.toAccountId)
                }
            } else {
                TransactionPickerRow(
                    label: "Categoria",
                    value: categoryName(for: single.categoryId),
                    placeholder: "Selecione a categoria"
                ) {
                    CategoryMenuContent(sections: singleCategorySections, selection: $single.categoryId)
                }

                TransactionPickerRow(
                    label: "Conta",
                    value: accountName(for: single.accountId),
                    placeholder: "Selecione a conta"
                ) {
                    AccountMenuContent(accounts: referenceStore.accounts, selection: $single.accountId)
                }
            }

            TransactionField(label: "Valor") {
                CurrencyMaskedTextField(text: $single.amount, placeholder: "R$ 0,00")
            }

            TransactionField(label: "Descrição") {
                TextField("Ex: Cinema", text: $single.description)
                    .textInputAutocapitalization(.sentences)
            }
        }
    }

    private var installmentFields: some View {
        VStack(spacing: DS.Spacing.item) {
            TransactionDateRow(label: "Primeira parcela", date: $installment.firstDueDate)

            TransactionPickerRow(
                label: "Categoria",
                value: categoryName(for: installment.categoryId),
                placeholder: "Selecione a categoria"
            ) {
                CategoryMenuContent(sections: installmentCategorySections, selection: $installment.categoryId)
            }

            TransactionPickerRow(
                label: "Conta (opcional)",
                value: accountName(for: installment.accountId),
                placeholder: "Opcional"
            ) {
                AccountMenuContent(accounts: referenceStore.accounts, selection: $installment.accountId)
            }

            TransactionField(label: "Valor total") {
                CurrencyMaskedTextField(text: $installment.totalAmount, placeholder: "R$ 0,00")
            }

            TransactionField(label: "Parcelas") {
                TextField("Ex: 12", text: $installment.installments)
                    .keyboardType(.numberPad)
            }

            TransactionField(label: "Descrição") {
                TextField("Ex: Geladeira", text: $installment.description)
                    .textInputAutocapitalization(.sentences)
            }
        }
    }

    private var recurringFields: some View {
        VStack(spacing: DS.Spacing.item) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tipo")
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)

                Picker("Tipo", selection: $recurrence.type) {
                    ForEach(recurringTypes, id: \.rawValue) { item in
                        Text(item.label).tag(item)
                    }
                }
                .pickerStyle(.segmented)
            }

            TransactionPickerRow(
                label: "Frequência",
                value: recurrence.frequency.label,
                placeholder: "Selecione"
            ) {
                ForEach(RecurrenceFrequency.allCases) { item in
                    Button(item.label) {
                        recurrence.frequency = item
                    }
                }
            }

            TransactionDateRow(label: "Início", date: $recurrence.startDate)

            Toggle(isOn: $recurrence.hasEndDate) {
                Text("Tem data fim")
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)
            }
            .tint(DS.Colors.primary)

            if recurrence.hasEndDate {
                TransactionDateRow(label: "Fim", date: $recurrence.endDate)
            }

            TransactionPickerRow(
                label: "Categoria",
                value: categoryName(for: recurrence.categoryId),
                placeholder: "Selecione a categoria"
            ) {
                CategoryMenuContent(sections: recurrenceCategorySections, selection: $recurrence.categoryId)
            }

            TransactionPickerRow(
                label: "Conta",
                value: accountName(for: recurrence.accountId),
                placeholder: "Selecione a conta"
            ) {
                AccountMenuContent(accounts: referenceStore.accounts, selection: $recurrence.accountId)
            }

            TransactionField(label: "Valor") {
                CurrencyMaskedTextField(text: $recurrence.amount, placeholder: "R$ 0,00")
            }

            TransactionField(label: "Descrição") {
                TextField("Ex: Academia", text: $recurrence.description)
                    .textInputAutocapitalization(.sentences)
            }
        }
    }

    private var singleCategorySections: [CategorySection] {
        guard single.type != .transfer else { return [] }
        return groupCategoriesForPicker(referenceStore.categories, transactionType: single.type)
    }

    private var installmentCategorySections: [CategorySection] {
        groupCategoriesForPicker(referenceStore.categories, transactionType: .expense)
    }

    private var recurrenceCategorySections: [CategorySection] {
        groupCategoriesForPicker(referenceStore.categories, transactionType: recurrence.type)
    }

    private var recurringTypes: [TransactionType] {
        [.income, .expense]
    }

    private var isCurrentModeValid: Bool {
        switch mode {
        case .single:
            return isSingleValid
        case .installment:
            return isInstallmentValid
        case .recurring:
            return isRecurringValid
        }
    }

    private var isSingleValid: Bool {
        guard CurrencyTextField.value(from: single.amount) != nil else { return false }
        if single.type == .transfer {
            return !single.fromAccountId.isEmpty &&
            !single.toAccountId.isEmpty &&
            single.fromAccountId != single.toAccountId
        }
        return !single.accountId.isEmpty
    }

    private var isInstallmentValid: Bool {
        guard CurrencyTextField.value(from: installment.totalAmount) != nil else { return false }
        guard let installments = Int(installment.installments), installments > 0 else { return false }
        return !installment.categoryId.isEmpty
    }

    private var isRecurringValid: Bool {
        guard CurrencyTextField.value(from: recurrence.amount) != nil else { return false }
        guard !recurrence.accountId.isEmpty else { return false }
        if recurrence.hasEndDate {
            return recurrence.endDate >= recurrence.startDate
        }
        return true
    }

    private func accountName(for id: String) -> String? {
        guard !id.isEmpty else { return nil }
        return referenceStore.accounts.first(where: { $0.id == id })?.name
    }

    private func categoryName(for id: String) -> String? {
        guard !id.isEmpty else { return nil }
        return referenceStore.categories.first(where: { $0.id == id })?.name
    }

    private func save() async {
        viewModel.isLoading = true
        defer { viewModel.isLoading = false }

        do {
            switch mode {
            case .single:
                try await viewModel.saveSingle(
                    type: single.type,
                    date: single.date,
                    amount: single.amount,
                    description: single.description,
                    accountId: single.accountId,
                    categoryId: single.categoryId,
                    fromAccountId: single.fromAccountId,
                    toAccountId: single.toAccountId
                )
                onComplete("Lançamento salvo com sucesso.")
            case .installment:
                try await viewModel.saveInstallment(
                    description: installment.description,
                    categoryId: installment.categoryId,
                    accountId: installment.accountId,
                    totalAmount: installment.totalAmount,
                    installments: installment.installments,
                    firstDueDate: installment.firstDueDate
                )
                onComplete("Compra parcelada salva com sucesso.")
            case .recurring:
                try await viewModel.saveRecurring(
                    type: recurrence.type,
                    amount: recurrence.amount,
                    description: recurrence.description,
                    accountId: recurrence.accountId,
                    categoryId: recurrence.categoryId,
                    frequency: recurrence.frequency,
                    startDate: recurrence.startDate,
                    endDate: recurrence.endDate,
                    hasEndDate: recurrence.hasEndDate
                )
                onComplete("Recorrência salva com sucesso.")
            }
            dismiss()
        } catch {
            viewModel.errorMessage = error.userMessage
        }
    }
}

private struct SingleEntryState {
    var type: TransactionType = .expense
    var date = Date()
    var amount = ""
    var description = ""
    var accountId = ""
    var categoryId = ""
    var fromAccountId = ""
    var toAccountId = ""
}

private struct InstallmentEntryState {
    var description = ""
    var categoryId = ""
    var accountId = ""
    var totalAmount = ""
    var installments = ""
    var firstDueDate = Date()
}

private struct RecurringEntryState {
    var type: TransactionType = .expense
    var amount = ""
    var description = ""
    var accountId = ""
    var categoryId = ""
    var frequency: RecurrenceFrequency = .monthly
    var startDate = Date()
    var endDate = Date()
    var hasEndDate = false
}
