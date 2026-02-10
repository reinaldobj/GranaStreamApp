import SwiftUI

/// Formulário para compra parcelada
struct InstallmentEntryFormContent: View {
    @Binding var firstDueDate: Date
    @Binding var categoryId: String
    @Binding var accountId: String
    @Binding var totalAmount: String
    @Binding var installments: String
    @Binding var description: String
    
    let accounts: [AccountResponseDto]
    let categorySections: [CategorySection]
    let accountNamesById: [String: String]
    let categoryNamesById: [String: String]
    
    var body: some View {
        VStack(spacing: DS.Spacing.item) {
            // Data da primeira parcela
            TransactionDateRow(label: "Primeira parcela", date: $firstDueDate)
            
            // Categoria
            TransactionPickerRow(
                label: "Categoria",
                value: categoryName(for: categoryId),
                placeholder: "Selecione a categoria"
            ) {
                CategoryMenuContent(sections: categorySections, selection: $categoryId)
            }
            
            // Conta (opcional)
            TransactionPickerRow(
                label: "Conta (opcional)",
                value: accountName(for: accountId),
                placeholder: "Opcional"
            ) {
                AccountMenuContent(accounts: accounts, selection: $accountId)
            }
            
            // Valor total
            TransactionField(label: "Valor total") {
                CurrencyMaskedTextField(text: $totalAmount, placeholder: "R$ 0,00")
            }
            
            // Número de parcelas
            TransactionField(label: "Parcelas") {
                TextField("Ex: 12", text: $installments)
                    .keyboardType(.numberPad)
            }
            
            // Descrição
            TransactionField(label: "Descrição") {
                TextField("Ex: Geladeira", text: $description)
                    .textInputAutocapitalization(.sentences)
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
