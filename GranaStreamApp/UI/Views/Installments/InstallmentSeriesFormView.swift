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
    @State private var isLoading = false
    @State private var errorMessage: String?

    @StateObject private var viewModel = InstallmentSeriesViewModel()

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
            .task(id: existing?.id) {
                await referenceStore.loadIfNeeded()
                prefill()
            }
            .errorAlert(message: $errorMessage)
        }
        .tint(DS.Colors.primary)
    }

    private var formCard: some View {
        VStack(spacing: DS.Spacing.item) {
            TransactionDateRow(label: "Primeiro vencimento", date: $firstDueDate)

            TransactionPickerRow(
                label: "Categoria",
                value: categoryName,
                placeholder: "Selecione a categoria"
            ) {
                categoryMenu()
            }

            TransactionPickerRow(
                label: "Conta padrão",
                value: accountName,
                placeholder: "Opcional"
            ) {
                accountMenu()
            }

            TransactionField(label: "Valor total") {
                CurrencyTextField(placeholder: "R$ 0,00", text: $totalAmount)
            }

            TransactionField(label: "Parcelas") {
                TextField("Ex: 12", text: $installments)
                    .keyboardType(.numberPad)
            }

            TransactionField(label: "Descrição") {
                TextField("Ex: Geladeira", text: $description)
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
        guard CurrencyTextField.value(from: totalAmount) != nil else { return false }
        guard let installmentsValue = Int(installments), installmentsValue > 0 else { return false }
        return !categoryId.isEmpty
    }

    private var accountName: String? {
        referenceStore.accounts.first(where: { $0.id == accountId })?.name
    }

    private var categoryName: String? {
        referenceStore.categories.first(where: { $0.id == categoryId })?.name
    }

    @ViewBuilder
    private func categoryMenu() -> some View {
        Button("Limpar seleção") {
            categoryId = ""
        }
        .disabled(categoryId.isEmpty)

        let sections = groupCategoriesForPicker(referenceStore.categories, transactionType: .expense)
        if sections.isEmpty {
            Text("Sem categorias")
                .font(DS.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)
        } else {
            ForEach(sections) { section in
                Text(section.title)
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)
                    .disabled(true)

                ForEach(section.children) { child in
                    Button(child.name ?? "Categoria") {
                        categoryId = child.id
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func accountMenu() -> some View {
        Button("Limpar seleção") {
            accountId = ""
        }
        .disabled(accountId.isEmpty)

        if referenceStore.accounts.isEmpty {
            Text("Sem contas")
                .font(DS.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)
        } else {
            ForEach(referenceStore.accounts) { account in
                Button(account.name ?? "Conta") {
                    accountId = account.id
                }
            }
        }
    }

    private func prefill() {
        description = ""
        categoryId = ""
        accountId = ""
        totalAmount = ""
        installments = ""
        firstDueDate = Date()

        guard let existing else { return }
        description = existing.description ?? ""
        categoryId = existing.categoryId
        accountId = existing.accountDefaultId ?? ""
        totalAmount = CurrencyTextField.initialText(from: existing.totalAmount)
        installments = String(existing.installmentsPlanned)
        firstDueDate = existing.firstDueDate
    }

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
