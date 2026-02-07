import SwiftUI

struct AccountFormView: View {
    let existing: AccountResponseDto?
    @ObservedObject var viewModel: AccountsViewModel
    var onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var type: AccountType = .contaCorrente
    @State private var initialBalance = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

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
            .task(id: existing?.id) { prefill() }
            .errorAlert(message: $errorMessage)
            .alert(item: $viewModel.inactiveAccount) { info in
                Alert(
                    title: Text(info.title),
                    message: Text(info.detail),
                    primaryButton: .default(Text("Reativar")) {
                        Task {
                            let success = await viewModel.reactivate(accountId: info.id)
                            if success {
                                onComplete()
                                dismiss()
                            }
                        }
                    },
                    secondaryButton: .cancel(Text("Cancelar"))
                )
            }
        }
        .tint(DS.Colors.primary)
    }

    private var formCard: some View {
        VStack(spacing: AppTheme.Spacing.item) {
            AccountField(label: "Nome") {
                TextField("Nome da conta", text: $name)
                    .textInputAutocapitalization(.words)
            }

            Menu {
                ForEach(AccountType.allCases) { item in
                    Button(item.label) {
                        type = item
                    }
                }
            } label: {
                AccountField(label: "Tipo") {
                    Text(type.label)
                        .foregroundColor(DS.Colors.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DS.Colors.textSecondary)
                }
            }
            .buttonStyle(.plain)

            if existing == nil {
                AccountField(label: "Saldo inicial") {
                    CurrencyMaskedTextField(text: $initialBalance, placeholder: "R$ 0,00")
                }
            }

            AccountPrimaryButton(
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
        if existing == nil {
            return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && CurrencyTextFieldHelper.value(from: initialBalance) != nil
        }
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func prefill() {
        name = ""
        type = .contaCorrente
        initialBalance = ""

        guard let existing else { return }
        name = existing.name ?? ""
        type = existing.accountType
    }

    private func save() async {
        isLoading = true
        defer { isLoading = false }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let balanceValue = CurrencyTextFieldHelper.value(from: initialBalance) ?? 0

        if let existing {
            let success = await viewModel.update(
                account: existing,
                name: trimmedName,
                type: type,
                reloadAfterChange: false
            )
            if success {
                onComplete()
                dismiss()
            } else {
                errorMessage = viewModel.errorMessage
            }
        } else {
            let success = await viewModel.create(
                name: trimmedName,
                type: type,
                initialBalance: balanceValue,
                reloadAfterChange: false
            )
            if success {
                onComplete()
                dismiss()
            } else {
                errorMessage = viewModel.errorMessage
            }
        }
    }
}
