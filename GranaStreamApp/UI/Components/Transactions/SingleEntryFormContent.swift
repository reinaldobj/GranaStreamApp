import SwiftUI

/// Formulário para lançamento único (despesa, receita ou transferência)
struct SingleEntryFormContent: View {
    @Binding var type: TransactionType
    @Binding var date: Date
    @Binding var amount: String
    @Binding var description: String
    @Binding var accountId: String
    @Binding var categoryId: String
    @Binding var fromAccountId: String
    @Binding var toAccountId: String
    
    let accounts: [AccountResponseDto]
    let categorySections: [CategorySection]
    let accountNamesById: [String: String]
    let categoryNamesById: [String: String]
    
    var body: some View {
        VStack(spacing: DS.Spacing.item) {
            // Tipo de transação
            VStack(alignment: .leading, spacing: 8) {
                Text("Tipo")
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)
                
                Picker("Tipo", selection: $type) {
                    ForEach(TransactionType.allCases) { item in
                        Text(item.label).tag(item)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Data
            TransactionDateRow(label: "Data", date: $date)
            
            // Campos específicos por tipo
            if type == .transfer {
                transferFields
            } else {
                regularTransactionFields
            }
            
            // Valor
            TransactionField(label: "Valor") {
                CurrencyMaskedTextField(text: $amount, placeholder: "R$ 0,00")
            }
            
            // Descrição
            TransactionField(label: "Descrição") {
                TextField("Ex: Cinema", text: $description)
                    .textInputAutocapitalization(.sentences)
            }
        }
    }
    
    // MARK: - Transfer Fields
    
    private var transferFields: some View {
        Group {
            TransactionPickerRow(
                label: "De",
                value: accountName(for: fromAccountId),
                placeholder: "Selecione"
            ) {
                AccountMenuContent(accounts: accounts, selection: $fromAccountId)
            }
            
            TransactionPickerRow(
                label: "Para",
                value: accountName(for: toAccountId),
                placeholder: "Selecione"
            ) {
                AccountMenuContent(accounts: accounts, selection: $toAccountId)
            }
        }
    }
    
    // MARK: - Regular Transaction Fields
    
    private var regularTransactionFields: some View {
        Group {
            TransactionPickerRow(
                label: "Categoria",
                value: categoryName(for: categoryId),
                placeholder: "Selecione a categoria"
            ) {
                CategoryMenuContent(sections: categorySections, selection: $categoryId)
            }
            
            TransactionPickerRow(
                label: "Conta",
                value: accountName(for: accountId),
                placeholder: "Selecione a conta"
            ) {
                AccountMenuContent(accounts: accounts, selection: $accountId)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func accountName(for id: String) -> String? {
        guard !id.isEmpty else { return nil }
        return accountNamesById[id]
    }
    
    private func categoryName(for id: String) -> String? {
        guard !id.isEmpty else { return nil }
        return categoryNamesById[id]
    }
}
