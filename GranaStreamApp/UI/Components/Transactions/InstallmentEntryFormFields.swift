import SwiftUI

/// Estado do formulário de compra parcelada
struct InstallmentEntryState {
    var description = ""
    var categoryId = ""
    var accountId = ""
    var totalAmount = ""
    var installments = ""
    var firstDueDate = Date()
}

/// Campos do formulário para compra parcelada
struct InstallmentEntryFormFields: View {
    @Binding var state: InstallmentEntryState
    let accounts: [AccountResponseDto]
    let categorySections: [CategorySection]
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.item) {
            TransactionDateRow(label: "Primeiro vencimento", date: $state.firstDueDate)
            
            TransactionPickerRow(
                label: "Categoria",
                value: categoryName(for: state.categoryId),
                placeholder: "Selecione a categoria"
            ) {
                categoryMenu(selection: $state.categoryId)
            }
            
            TransactionPickerRow(
                label: "Conta padrão",
                value: accountName(for: state.accountId),
                placeholder: "Opcional"
            ) {
                accountMenu(selection: $state.accountId)
            }
            
            TransactionField(label: "Valor total") {
                CurrencyMaskedTextField(text: $state.totalAmount, placeholder: "R$ 0,00")
            }
            
            TransactionField(label: "Parcelas") {
                TextField("Ex: 12", text: $state.installments)
                    .keyboardType(.numberPad)
            }
            
            TransactionField(label: "Descrição") {
                TextField("Ex: Geladeira", text: $state.description)
                    .textInputAutocapitalization(.sentences)
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

extension InstallmentEntryState {
    var isValid: Bool {
        guard CurrencyTextField.value(from: totalAmount) != nil else { return false }
        guard let installmentCount = Int(installments), installmentCount > 0 else { return false }
        return !categoryId.isEmpty
    }
}
