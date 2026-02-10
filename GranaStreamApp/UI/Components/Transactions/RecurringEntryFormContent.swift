import SwiftUI

/// Formulário para lançamento recorrente
struct RecurringEntryFormContent: View {
    @Binding var type: TransactionType
    @Binding var frequency: RecurrenceFrequency
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var hasEndDate: Bool
    @Binding var categoryId: String
    @Binding var accountId: String
    @Binding var amount: String
    @Binding var description: String
    
    let accounts: [AccountResponseDto]
    let categorySections: [CategorySection]
    let accountNamesById: [String: String]
    let categoryNamesById: [String: String]
    
    /// Tipos permitidos para recorrência (exclui transferência)
    private var allowedTypes: [TransactionType] {
        [.income, .expense]
    }
    
    var body: some View {
        VStack(spacing: DS.Spacing.item) {
            // Tipo de transação
            VStack(alignment: .leading, spacing: 8) {
                Text("Tipo")
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)
                
                Picker("Tipo", selection: $type) {
                    ForEach(allowedTypes, id: \.rawValue) { item in
                        Text(item.label).tag(item)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Frequência
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
            
            // Data de início
            TransactionDateRow(label: "Início", date: $startDate)
            
            // Toggle para data fim
            Toggle(isOn: $hasEndDate) {
                Text("Tem data fim")
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)
            }
            .tint(DS.Colors.primary)
            
            // Data fim (condicional)
            if hasEndDate {
                TransactionDateRow(label: "Fim", date: $endDate)
            }
            
            // Categoria
            TransactionPickerRow(
                label: "Categoria",
                value: categoryName(for: categoryId),
                placeholder: "Selecione a categoria"
            ) {
                CategoryMenuContent(sections: categorySections, selection: $categoryId)
            }
            
            // Conta
            TransactionPickerRow(
                label: "Conta",
                value: accountName(for: accountId),
                placeholder: "Selecione a conta"
            ) {
                AccountMenuContent(accounts: accounts, selection: $accountId)
            }
            
            // Valor
            TransactionField(label: "Valor") {
                CurrencyMaskedTextField(text: $amount, placeholder: "R$ 0,00")
            }
            
            // Descrição
            TransactionField(label: "Descrição") {
                TextField("Ex: Academia", text: $description)
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
