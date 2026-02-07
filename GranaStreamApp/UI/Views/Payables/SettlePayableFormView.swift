import SwiftUI

struct SettlePayableFormView: View {
    let payable: PayableListItemDto
    let actionTitle: String
    let transactionType: TransactionType
    let onConfirm: (SettlePayableRequestDto) async -> Bool

    @EnvironmentObject private var referenceStore: ReferenceDataStore
    @Environment(\.dismiss) private var dismiss

    @State private var accountId: String
    @State private var categoryId: String
    @State private var paidDate: Date
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(
        payable: PayableListItemDto,
        actionTitle: String,
        transactionType: TransactionType,
        onConfirm: @escaping (SettlePayableRequestDto) async -> Bool
    ) {
        self.payable = payable
        self.actionTitle = actionTitle
        self.transactionType = transactionType
        self.onConfirm = onConfirm
        _accountId = State(initialValue: payable.accountId ?? "")
        _categoryId = State(initialValue: payable.categoryId ?? "")
        _paidDate = State(initialValue: payable.dueDate)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.item) {
                        detailsCard
                        formCard
                    }
                    .padding(.horizontal, AppTheme.Spacing.screen)
                    .padding(.top, AppTheme.Spacing.screen)
                    .padding(.bottom, AppTheme.Spacing.screen * 2)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await referenceStore.loadIfNeeded()
            }
            .errorAlert(message: $errorMessage)
        }
        .tint(DS.Colors.primary)
    }

    private var detailsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.base) {
                Text(displayDescription)
                    .font(AppTheme.Typography.section)
                    .foregroundColor(DS.Colors.textPrimary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text("Vencimento: \(payable.dueDate.formattedDate())")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)
                    Spacer(minLength: 8)
                    Text(CurrencyFormatter.string(from: payable.amount))
                        .font(AppTheme.Typography.section)
                        .foregroundColor(DS.Colors.textPrimary)
                }
            }
        }
    }

    private var formCard: some View {
        VStack(spacing: AppTheme.Spacing.item) {
            TransactionPickerRow(
                label: "Conta",
                value: accountName(for: accountId),
                placeholder: "Selecione a conta"
            ) {
                accountMenu
            }

            TransactionPickerRow(
                label: "Categoria",
                value: categoryName(for: categoryId),
                placeholder: "Selecione a categoria"
            ) {
                categoryMenu
            }

            TransactionDateRow(label: "Data do pagamento", date: $paidDate)

            TransactionPrimaryButton(
                title: isSaving ? "Processando..." : actionTitle,
                isDisabled: isSaving || !isValid
            ) {
                Task { await submit() }
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(DS.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: DS.Colors.border.opacity(0.25), radius: 10, x: 0, y: 6)
    }

    private var isValid: Bool {
        !accountId.isEmpty && !categoryId.isEmpty
    }

    @ViewBuilder
    private var accountMenu: some View {
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
    private var categoryMenu: some View {
        Button("Limpar seleção") {
            categoryId = ""
        }
        .disabled(categoryId.isEmpty)

        if categorySections.isEmpty {
            Text("Sem categorias")
                .font(AppTheme.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)
        } else {
            ForEach(categorySections) { section in
                Text(section.title)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)
                    .disabled(true)

                ForEach(section.children) { category in
                    Button(category.name ?? "Categoria") {
                        categoryId = category.id
                    }
                }
            }
        }
    }

    private var categorySections: [CategorySection] {
        groupCategoriesForPicker(referenceStore.categories, transactionType: transactionType)
    }

    private var displayDescription: String {
        let trimmed = payable.description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Sem descrição" : trimmed
    }

    private func accountName(for id: String) -> String? {
        guard !id.isEmpty else { return nil }
        return referenceStore.accounts.first(where: { $0.id == id })?.name
    }

    private func categoryName(for id: String) -> String? {
        guard !id.isEmpty else { return nil }
        return referenceStore.categories.first(where: { $0.id == id })?.name
    }

    private func submit() async {
        guard isValid else {
            errorMessage = "Selecione conta e categoria para continuar."
            return
        }

        isSaving = true
        defer { isSaving = false }

        let request = SettlePayableRequestDto(
            accountId: accountId,
            categoryId: categoryId,
            paidDate: paidDate
        )

        let succeeded = await onConfirm(request)
        if succeeded {
            dismiss()
            return
        }

        errorMessage = "Não foi possível concluir agora. Tente novamente."
    }
}
