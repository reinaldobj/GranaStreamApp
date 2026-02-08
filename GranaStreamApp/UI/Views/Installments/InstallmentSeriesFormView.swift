import SwiftUI

/// Formulário para criar/editar séries de parcelamento
/// Reutiliza InstallmentEntryFormContent como componente de UI
struct InstallmentSeriesFormView: View {
    let existing: InstallmentSeriesResponseDto?
    var onComplete: () -> Void

    @EnvironmentObject private var referenceStore: ReferenceDataStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = InstallmentSeriesViewModel()

    // State para o formulário
    @State private var firstDueDate = Date()
    @State private var categoryId = ""
    @State private var accountId = ""
    @State private var totalAmount = ""
    @State private var installments = ""
    @State private var description = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

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
            // Reutiliza o componente de conteúdo de parcelamento
            InstallmentEntryFormContent(
                firstDueDate: $firstDueDate,
                categoryId: $categoryId,
                accountId: $accountId,
                totalAmount: $totalAmount,
                installments: $installments,
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
        groupCategoriesForPicker(referenceStore.categories, transactionType: .expense)
    }

    private var isValid: Bool {
        guard CurrencyTextField.value(from: totalAmount) != nil else { return false }
        guard let installmentsValue = Int(installments), installmentsValue > 0 else { return false }
        return !categoryId.isEmpty
    }

    // MARK: - Prefill (para edição)

    private func prefill() {
        guard let existing else { return }
        description = existing.description ?? ""
        categoryId = existing.categoryId
        accountId = existing.accountDefaultId ?? ""
        totalAmount = CurrencyTextField.initialText(from: existing.totalAmount)
        installments = String(existing.installmentsPlanned)
        firstDueDate = existing.firstDueDate
    }

    // MARK: - Save

    private func save() async {
        isLoading = true
        defer { isLoading = false }

        guard let totalValue = CurrencyTextField.value(from: totalAmount),
              let installmentsValue = Int(installments),
              installmentsValue > 0 else {
            errorMessage = "Informe valores válidos."
            return
        }

        if let existing {
            // Update
            let request = UpdateInstallmentSeriesRequestDto(
                description: description.nilIfBlank,
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
            // Create
            let request = CreateInstallmentSeriesRequestDto(
                description: description.nilIfBlank,
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
