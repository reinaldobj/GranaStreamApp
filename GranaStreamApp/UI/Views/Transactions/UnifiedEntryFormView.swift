import SwiftUI

/// View unificada para criação de lançamentos (único, parcelado ou recorrente)
/// Refatorada para usar componentes extraídos
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
                handleSingleTypeChange(newValue)
            }
            .onChange(of: recurrence.type) { _, newValue in
                handleRecurrenceTypeChange(newValue)
            }
            .errorAlert(message: $viewModel.errorMessage)
        }
        .tint(DS.Colors.primary)
    }

    // MARK: - Form Card

    private var formCard: some View {
        VStack(spacing: DS.Spacing.item) {
            EntryModePicker(selection: $mode)

            formContent

            saveButton
        }
        .padding(20)
        .background(DS.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: DS.Colors.border.opacity(0.35), radius: 12, x: 0, y: 6)
    }

    // MARK: - Form Content (delegando para componentes)

    @ViewBuilder
    private var formContent: some View {
        switch mode {
        case .single:
            SingleEntryFormContent(
                type: $single.type,
                date: $single.date,
                amount: $single.amount,
                description: $single.description,
                accountId: $single.accountId,
                categoryId: $single.categoryId,
                fromAccountId: $single.fromAccountId,
                toAccountId: $single.toAccountId,
                accounts: referenceStore.accounts,
                categorySections: singleCategorySections
            )
        case .installment:
            InstallmentEntryFormContent(
                firstDueDate: $installment.firstDueDate,
                categoryId: $installment.categoryId,
                accountId: $installment.accountId,
                totalAmount: $installment.totalAmount,
                installments: $installment.installments,
                description: $installment.description,
                accounts: referenceStore.accounts,
                categorySections: installmentCategorySections
            )
        case .recurring:
            RecurringEntryFormContent(
                type: $recurrence.type,
                frequency: $recurrence.frequency,
                startDate: $recurrence.startDate,
                endDate: $recurrence.endDate,
                hasEndDate: $recurrence.hasEndDate,
                categoryId: $recurrence.categoryId,
                accountId: $recurrence.accountId,
                amount: $recurrence.amount,
                description: $recurrence.description,
                accounts: referenceStore.accounts,
                categorySections: recurrenceCategorySections
            )
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        TransactionPrimaryButton(
            title: viewModel.isLoading ? "Salvando..." : "Salvar",
            isDisabled: !isCurrentModeValid || viewModel.isLoading
        ) {
            Task { await save() }
        }
        .padding(.top, 8)
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

    // MARK: - Save Action

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

// MARK: - State Structs

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
