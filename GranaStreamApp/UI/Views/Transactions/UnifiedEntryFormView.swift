import SwiftUI

struct UnifiedEntryFormView: View {
    var onComplete: (String) -> Void

    @EnvironmentObject private var referenceStore: ReferenceDataStore
    @Environment(\.dismiss) private var dismiss

    @State private var mode: UnifiedEntryMode
    @State private var single = SingleEntryState()
    @State private var installment = InstallmentEntryState()
    @State private var recurrence = RecurringEntryState()
    @State private var isLoading = false
    @State private var errorMessage: String?

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
                    VStack(spacing: AppTheme.Spacing.item) {
                        formCard
                    }
                    .padding(.horizontal, AppTheme.Spacing.screen)
                    .padding(.top, AppTheme.Spacing.screen + 10)
                    .padding(.bottom, AppTheme.Spacing.screen * 2)
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
            .errorAlert(message: $errorMessage)
        }
        .tint(DS.Colors.primary)
    }

    private var formCard: some View {
        VStack(spacing: AppTheme.Spacing.item) {
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
                title: isLoading ? "Salvando..." : "Salvar",
                isDisabled: !isCurrentModeValid || isLoading
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
        VStack(spacing: AppTheme.Spacing.item) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tipo")
                    .font(AppTheme.Typography.caption)
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
                    accountMenu(selection: $single.fromAccountId)
                }

                TransactionPickerRow(
                    label: "Para",
                    value: accountName(for: single.toAccountId),
                    placeholder: "Selecione"
                ) {
                    accountMenu(selection: $single.toAccountId)
                }
            } else {
                TransactionPickerRow(
                    label: "Categoria",
                    value: categoryName(for: single.categoryId),
                    placeholder: "Selecione a categoria"
                ) {
                    categoryMenu(
                        sections: singleCategorySections,
                        selection: $single.categoryId
                    )
                }

                TransactionPickerRow(
                    label: "Conta",
                    value: accountName(for: single.accountId),
                    placeholder: "Selecione a conta"
                ) {
                    accountMenu(selection: $single.accountId)
                }
            }

            TransactionField(label: "Valor") {
                CurrencyTextField(placeholder: "R$ 0,00", text: $single.amount)
            }

            TransactionField(label: "Título") {
                TextField("Ex: Cinema", text: $single.description)
                    .textInputAutocapitalization(.sentences)
            }
        }
    }

    private var installmentFields: some View {
        VStack(spacing: AppTheme.Spacing.item) {
            TransactionDateRow(label: "Primeiro vencimento", date: $installment.firstDueDate)

            TransactionPickerRow(
                label: "Categoria",
                value: categoryName(for: installment.categoryId),
                placeholder: "Selecione a categoria"
            ) {
                categoryMenu(
                    sections: installmentCategorySections,
                    selection: $installment.categoryId
                )
            }

            TransactionPickerRow(
                label: "Conta padrão",
                value: accountName(for: installment.accountId),
                placeholder: "Opcional"
            ) {
                accountMenu(selection: $installment.accountId)
            }

            TransactionField(label: "Valor total") {
                CurrencyTextField(placeholder: "R$ 0,00", text: $installment.totalAmount)
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
        VStack(spacing: AppTheme.Spacing.item) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tipo")
                    .font(AppTheme.Typography.caption)
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
                    .font(AppTheme.Typography.caption)
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
                categoryMenu(
                    sections: recurrenceCategorySections,
                    selection: $recurrence.categoryId
                )
            }

            TransactionPickerRow(
                label: "Conta",
                value: accountName(for: recurrence.accountId),
                placeholder: "Selecione a conta"
            ) {
                accountMenu(selection: $recurrence.accountId)
            }

            TransactionField(label: "Valor") {
                CurrencyTextField(placeholder: "R$ 0,00", text: $recurrence.amount)
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

    @ViewBuilder
    private func categoryMenu(
        sections: [CategorySection],
        selection: Binding<String>
    ) -> some View {
        Button("Limpar seleção") {
            selection.wrappedValue = ""
        }
        .disabled(selection.wrappedValue.isEmpty)

        if sections.isEmpty {
            Text("Sem categorias")
                .font(AppTheme.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)
        } else {
            ForEach(sections) { section in
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

    private func save() async {
        isLoading = true
        defer { isLoading = false }

        do {
            switch mode {
            case .single:
                try await saveSingle()
                onComplete("Lançamento salvo com sucesso.")
            case .installment:
                try await saveInstallment()
                onComplete("Compra parcelada salva com sucesso.")
            case .recurring:
                try await saveRecurring()
                onComplete("Recorrência salva com sucesso.")
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveSingle() async throws {
        guard let amountValue = CurrencyTextField.value(from: single.amount) else {
            throw FormValidationError.invalidAmount
        }

        if single.type == .transfer {
            guard !single.fromAccountId.isEmpty, !single.toAccountId.isEmpty else {
                throw FormValidationError.missingTransferAccount
            }
            guard single.fromAccountId != single.toAccountId else {
                throw FormValidationError.sameTransferAccount
            }
        } else {
            guard !single.accountId.isEmpty else {
                throw FormValidationError.missingAccount
            }
        }

        let request = CreateTransactionRequestDto(
            type: single.type,
            date: single.date,
            amount: amountValue,
            description: single.description.nilIfBlank,
            accountId: single.type == .transfer ? nil : single.accountId.nilIfBlank,
            categoryId: single.type == .transfer ? nil : single.categoryId.nilIfBlank,
            fromAccountId: single.type == .transfer ? single.fromAccountId.nilIfBlank : nil,
            toAccountId: single.type == .transfer ? single.toAccountId.nilIfBlank : nil
        )
        let _: CreateTransactionResponseDto = try await APIClient.shared.request(
            "/api/v1/transactions",
            method: "POST",
            body: AnyEncodable(request)
        )
    }

    private func saveInstallment() async throws {
        guard let totalAmount = CurrencyTextField.value(from: installment.totalAmount) else {
            throw FormValidationError.invalidAmount
        }
        guard let installments = Int(installment.installments), installments > 0 else {
            throw FormValidationError.invalidInstallments
        }
        guard !installment.categoryId.isEmpty else {
            throw FormValidationError.missingCategory
        }

        let request = CreateInstallmentSeriesRequestDto(
            description: installment.description.nilIfBlank,
            categoryId: installment.categoryId,
            accountDefaultId: installment.accountId.nilIfBlank,
            totalAmount: totalAmount,
            installmentsPlanned: installments,
            firstDueDate: installment.firstDueDate
        )
        let _: CreateInstallmentSeriesResponseDto = try await APIClient.shared.request(
            "/api/v1/installment-series",
            method: "POST",
            body: AnyEncodable(request)
        )
    }

    private func saveRecurring() async throws {
        guard let amountValue = CurrencyTextField.value(from: recurrence.amount) else {
            throw FormValidationError.invalidAmount
        }
        guard !recurrence.accountId.isEmpty else {
            throw FormValidationError.missingAccount
        }
        if recurrence.hasEndDate, recurrence.endDate < recurrence.startDate {
            throw FormValidationError.invalidDateRange
        }

        let template = RecurrenceTemplateTransactionRequestDto(
            type: recurrence.type,
            amount: amountValue,
            description: recurrence.description.nilIfBlank,
            accountId: recurrence.accountId.nilIfBlank,
            categoryId: recurrence.categoryId.nilIfBlank
        )
        let dayOfMonth = recurrence.frequency == .monthly
        ? Calendar.current.component(.day, from: recurrence.startDate)
        : nil

        let request = CreateRecurrenceRequestDto(
            templateTransaction: template,
            frequency: recurrence.frequency,
            startDate: recurrence.startDate,
            endDate: recurrence.hasEndDate ? recurrence.endDate : nil,
            dayOfMonth: dayOfMonth
        )
        let _: CreateRecurrenceResponseDto = try await APIClient.shared.request(
            "/api/v1/recurrences",
            method: "POST",
            body: AnyEncodable(request)
        )
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

private enum FormValidationError: LocalizedError {
    case invalidAmount
    case missingAccount
    case missingTransferAccount
    case sameTransferAccount
    case missingCategory
    case invalidInstallments
    case invalidDateRange

    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Informe um valor válido."
        case .missingAccount:
            return "Selecione uma conta para continuar."
        case .missingTransferAccount:
            return "Selecione as contas de origem e destino."
        case .sameTransferAccount:
            return "Escolha contas diferentes para a transferência."
        case .missingCategory:
            return "Selecione uma categoria para continuar."
        case .invalidInstallments:
            return "Informe uma quantidade de parcelas válida."
        case .invalidDateRange:
            return "A data fim precisa ser maior ou igual à data de início."
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
