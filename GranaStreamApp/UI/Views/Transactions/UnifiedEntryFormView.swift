import SwiftUI

/// Formulário unificado para criar lançamentos únicos, parcelados ou recorrentes
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
                handleSingleTypeChange(newValue)
            }
            .onChange(of: recurrence.type) { _, newValue in
                handleRecurrenceTypeChange(newValue)
            }
            .errorAlert(message: $errorMessage)
        }
        .tint(DS.Colors.primary)
    }

    // MARK: - Form Card

    private var formCard: some View {
        VStack(spacing: AppTheme.Spacing.item) {
            EntryModePicker(selection: $mode)

            formFields

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

    @ViewBuilder
    private var formFields: some View {
        switch mode {
        case .single:
            SingleEntryFormFields(
                state: $single,
                accounts: referenceStore.accounts,
                categorySections: singleCategorySections
            )
        case .installment:
            InstallmentEntryFormFields(
                state: $installment,
                accounts: referenceStore.accounts,
                categorySections: installmentCategorySections
            )
        case .recurring:
            RecurringEntryFormFields(
                state: $recurrence,
                accounts: referenceStore.accounts,
                categorySections: recurrenceCategorySections
            )
        }
    }

    // MARK: - Category Sections

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

    // MARK: - Validation

    private var isCurrentModeValid: Bool {
        switch mode {
        case .single:
            return single.isValid
        case .installment:
            return installment.isValid
        case .recurring:
            return recurrence.isValid
        }
    }

    // MARK: - Type Change Handlers

    private func handleSingleTypeChange(_ newValue: TransactionType) {
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

    private func handleRecurrenceTypeChange(_ newValue: TransactionType) {
        let validIds = Set(
            groupCategoriesForPicker(referenceStore.categories, transactionType: newValue)
                .flatMap { $0.children.map(\.id) }
        )
        if !recurrence.categoryId.isEmpty && !validIds.contains(recurrence.categoryId) {
            recurrence.categoryId = ""
        }
    }

    // MARK: - Save Actions

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
            errorMessage = error.userMessage
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
        guard let installmentCount = Int(installment.installments), installmentCount > 0 else {
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
            installmentsPlanned: installmentCount,
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
