import SwiftUI

/// Formulário para criar/editar recorrências
/// Reutiliza RecurringEntryFormContent como componente de UI
struct RecurrenceFormView: View {
    let existing: RecurrenceResponseDto?
    var onComplete: () -> Void

    @EnvironmentObject private var referenceStore: ReferenceDataStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = RecurrencesViewModel()

    // State para o formulário
    @State private var type: TransactionType = .expense
    @State private var frequency: RecurrenceFrequency = .monthly
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var hasEndDate = false
    @State private var categoryId = ""
    @State private var accountId = ""
    @State private var amount = ""
    @State private var description = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    init(existing: RecurrenceResponseDto?, onComplete: @escaping () -> Void = {}) {
        self.existing = existing
        self.onComplete = onComplete
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
                prefill()
            }
            .errorAlert(message: $errorMessage)
        }
        .tint(DS.Colors.primary)
    }

    // MARK: - Form Card

    private var formCard: some View {
        VStack(spacing: DS.Spacing.item) {
            // Reutiliza o componente de conteúdo de recorrência
            RecurringEntryFormContent(
                type: $type,
                frequency: $frequency,
                startDate: $startDate,
                endDate: $endDate,
                hasEndDate: $hasEndDate,
                categoryId: $categoryId,
                accountId: $accountId,
                amount: $amount,
                description: $description,
                accounts: referenceStore.accounts,
                categorySections: categorySections
            )

            // Botão salvar
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

    // MARK: - Helpers

    private var categorySections: [CategorySection] {
        groupCategoriesForPicker(referenceStore.categories, transactionType: type)
    }

    private var isValid: Bool {
        guard CurrencyTextField.value(from: amount) != nil else { return false }
        guard !accountId.isEmpty else { return false }
        if hasEndDate {
            return endDate >= startDate
        }
        return true
    }

    // MARK: - Prefill (para edição)

    private func prefill() {
        guard let existing else { return }
        type = existing.templateTransaction.type
        frequency = existing.frequency
        startDate = existing.startDate
        endDate = existing.endDate ?? Date()
        hasEndDate = existing.endDate != nil
        categoryId = existing.templateTransaction.categoryId ?? ""
        accountId = existing.templateTransaction.accountId ?? ""
        amount = CurrencyTextField.initialText(from: existing.templateTransaction.amount)
        description = existing.templateTransaction.description ?? ""
    }

    // MARK: - Save

    private func save() async {
        isLoading = true
        defer { isLoading = false }

        guard let amountValue = CurrencyTextField.value(from: amount) else {
            errorMessage = "Informe um valor válido."
            return
        }

        let template = RecurrenceTemplateTransactionRequestDto(
            type: type,
            amount: amountValue,
            description: description.nilIfBlank,
            accountId: accountId.nilIfBlank,
            categoryId: categoryId.nilIfBlank
        )

        let dayOfMonth = frequency == .monthly
            ? Calendar.current.component(.day, from: startDate)
            : nil

        if let existing {
            // Update
            let request = UpdateRecurrenceRequestDto(
                templateTransaction: template,
                frequency: frequency,
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil,
                dayOfMonth: dayOfMonth
            )
            let success = await viewModel.update(id: existing.id, request: request)
            if success {
                onComplete()
                dismiss()
            } else {
                errorMessage = viewModel.errorMessage
            }
        } else {
            // Create
            let request = CreateRecurrenceRequestDto(
                templateTransaction: template,
                frequency: frequency,
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil,
                dayOfMonth: dayOfMonth
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
