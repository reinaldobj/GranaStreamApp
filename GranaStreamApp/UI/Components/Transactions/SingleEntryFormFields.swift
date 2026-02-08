import SwiftUI

/// Estado do formulário de lançamento único
struct SingleEntryState {
    var type: TransactionType = .expense
    var date = Date()
    var amount = ""
    var description = ""
    var accountId = ""
    var categoryId = ""
    var fromAccountId = ""
    var toAccountId = ""
}

/// Campos do formulário para lançamento único (receita, despesa ou transferência)
struct SingleEntryFormFields: View {
    @Binding var state: SingleEntryState
    let accounts: [AccountResponseDto]
    let categorySections: [CategorySection]
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.item) {
            typeSelector
            
            TransactionDateRow(label: "Data", date: $state.date)
            
            if state.type == .transfer {
                transferFields
            } else {
                standardFields
            }
            
            TransactionField(label: "Valor") {
                CurrencyMaskedTextField(text: $state.amount, placeholder: "R$ 0,00")
            }
            
            TransactionField(label: "Título") {
                TextField("Ex: Cinema", text: $state.description)
                    .textInputAutocapitalization(.sentences)
            }
        }
    }
    
    private var typeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tipo")
                .font(AppTheme.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)
            
            Picker("Tipo", selection: $state.type) {
                ForEach(TransactionType.allCases) { item in
                    Text(item.label).tag(item)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var transferFields: some View {
        Group {
            TransactionPickerRow(
                label: "De",
                value: accountName(for: state.fromAccountId),
                placeholder: "Selecione"
            ) {
                accountMenu(selection: $state.fromAccountId)
            }
            
            TransactionPickerRow(
                label: "Para",
                value: accountName(for: state.toAccountId),
                placeholder: "Selecione"
            ) {
                accountMenu(selection: $state.toAccountId)
            }
        }
    }
    
    private var standardFields: some View {
        Group {
            TransactionPickerRow(
                label: "Categoria",
                value: categoryName(for: state.categoryId),
                placeholder: "Selecione a categoria"
            ) {
                categoryMenu(selection: $state.categoryId)
            }
            
            TransactionPickerRow(
                label: "Conta",
                value: accountName(for: state.accountId),
                placeholder: "Selecione a conta"
            ) {
                accountMenu(selection: $state.accountId)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func accountName(for id: String) -> String? {
        guard !id.isEmpty else { return nil }
        return accounts.first(where: { $0.id == id })?.name
    }
    
    private func categoryName(for id: String) -> String? {
        guard !id.isEmpty else { return nil }
        return categorySections.flatMap(\.children).first(where: { $0.id == id })?.name
    }
    
    @ViewBuilder
    private func accountMenu(selection: Binding<String>) -> some View {
        Button("Limpar seleção") {
            selection.wrappedValue = ""
        }
        .disabled(selection.wrappedValue.isEmpty)
        
        if accounts.isEmpty {
            Text("Sem contas")
                .font(AppTheme.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)
        } else {
            ForEach(accounts) { account in
                Button(account.name ?? "Conta") {
                    selection.wrappedValue = account.id
                }
            }
        }
    }
    
    @ViewBuilder
    private func categoryMenu(selection: Binding<String>) -> some View {
        Button("Limpar seleção") {
            selection.wrappedValue = ""
        }
        .disabled(selection.wrappedValue.isEmpty)
        
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
                
                ForEach(section.children) { child in
                    Button(child.name ?? "Categoria") {
                        selection.wrappedValue = child.id
                    }
                }
            }
        }
    }
}

// MARK: - Validation

extension SingleEntryState {
    var isValid: Bool {
        guard CurrencyTextField.value(from: amount) != nil else { return false }
        if type == .transfer {
            return !fromAccountId.isEmpty &&
                   !toAccountId.isEmpty &&
                   fromAccountId != toAccountId
        }
        return !accountId.isEmpty
    }
}
