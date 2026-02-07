import SwiftUI

struct RecurrenceFormView: View {
    let existing: RecurrenceResponseDto?
    var onComplete: () -> Void

    @EnvironmentObject private var referenceStore: ReferenceDataStore
    @Environment(\.dismiss) private var dismiss

    @State private var type: TransactionType = .expense
    @State private var amount = ""
    @State private var description = ""
    @State private var accountId: String = ""
    @State private var categoryId: String = ""
    @State private var frequency: RecurrenceFrequency = .monthly
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var hasEndDate = false
    @State private var isLoading = false

    @State private var errorMessage: String?
    @StateObject private var viewModel = RecurrencesViewModel()

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
                prefill()
            }
            .errorAlert(message: $errorMessage)
        }
        .tint(DS.Colors.primary)
    }

    private var formCard: some View {
        VStack(spacing: AppTheme.Spacing.item) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tipo")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)

                Picker("Tipo", selection: $type) {
                    ForEach(recurringTypes, id: \.rawValue) { item in
                        Text(item.label).tag(item)
                    }
                }
                .pickerStyle(.segmented)
            }

            TransactionPickerRow(
                label: "Frequência",
                value: frequency.label,
                placeholder: "Selecione"
            ) {
                ForEach(RecurrenceFrequency.allCases) { item in
                    Button(item.label) {
                        frequency = item
                    }
                }
            }

            TransactionDateRow(label: "Início", date: $startDate)

            Toggle(isOn: $hasEndDate) {
                Text("Tem data fim")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)
            }
            .tint(DS.Colors.primary)

            if hasEndDate {
                TransactionDateRow(label: "Fim", date: $endDate)
            }

            TransactionPickerRow(
                label: "Categoria",
                value: categoryName,
                placeholder: "Selecione a categoria"
            ) {
                categoryMenu()
            }

            TransactionPickerRow(
                label: "Conta",
                value: accountName,
                placeholder: "Selecione a conta"
            ) {
                accountMenu()
            }

            TransactionField(label: "Valor") {
                CurrencyMaskedTextField(text: $amount, placeholder: "R$ 0,00")
            }

            TransactionField(label: "Descrição") {
                TextField("Ex: Academia", text: $description)
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

    private var isValid: Bool {
        guard CurrencyTextFieldHelper.value(from: amount) != nil else { return false }
        guard !accountId.isEmpty else { return false }
        if hasEndDate {
            return endDate >= startDate
        }
        return true
    }

    private func prefill() {
        guard let existing else { return }
        type = existing.templateTransaction.type
        amount = CurrencyTextFieldHelper.initialText(from: existing.templateTransaction.amount) ?? ""
        description = existing.templateTransaction.description ?? ""
        accountId = existing.templateTransaction.accountId ?? ""
        categoryId = existing.templateTransaction.categoryId ?? ""
        frequency = existing.frequency
        startDate = existing.startDate
        if let end = existing.endDate {
            hasEndDate = true
            endDate = end
        }
    }

    private func save() async {
        guard let amountValue = CurrencyTextFieldHelper.value(from: amount) else {
            errorMessage = "Informe um valor válido."
            return
        }
        isLoading = true
        defer { isLoading = false }
        let template = RecurrenceTemplateTransactionRequestDto(
            type: type,
            amount: amountValue,
            description: description.isEmpty ? nil : description,
            accountId: accountId.isEmpty ? nil : accountId,
            categoryId: categoryId.isEmpty ? nil : categoryId
        )
        let dayOfMonth = Calendar.current.component(.day, from: startDate)

        if let existing {
            let request = UpdateRecurrenceRequestDto(
                templateTransaction: template,
                frequency: frequency,
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil,
                dayOfMonth: frequency == .monthly ? dayOfMonth : nil
            )
            let success = await viewModel.update(id: existing.id, request: request)
            if success {
                onComplete()
                dismiss()
            } else {
                errorMessage = viewModel.errorMessage
            }
        } else {
            let request = CreateRecurrenceRequestDto(
                templateTransaction: template,
                frequency: frequency,
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil,
                dayOfMonth: frequency == .monthly ? dayOfMonth : nil
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

    private var accountName: String? {
        referenceStore.accounts.first(where: { $0.id == accountId })?.name
    }
    private var categoryName: String? {
        referenceStore.categories.first(where: { $0.id == categoryId })?.name
    }

    private var recurringTypes: [TransactionType] { [.income, .expense] }

    @ViewBuilder
    private func accountMenu() -> some View {
        Button("Limpar seleção") {
            accountId = ""
        }
        .disabled(accountId.isEmpty)

        if referenceStore.accounts.isEmpty {
            Text("Sem contas")
                .font(AppTheme.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)
        } else {
            ForEach(referenceStore.accounts) { account in
                Button(account.name ?? "Conta") {
                    accountId = account.id
                }
            }
        }
    }

    @ViewBuilder
    private func categoryMenu() -> some View {
        Button("Limpar seleção") {
            categoryId = ""
        }
        .disabled(categoryId.isEmpty)

        if referenceStore.categories.isEmpty {
            Text("Sem categorias")
                .font(AppTheme.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)
        } else {
            ForEach(referenceStore.categories) { category in
                Button(category.name ?? "Categoria") {
                    categoryId = category.id
                }
            }
        }
    }
}

