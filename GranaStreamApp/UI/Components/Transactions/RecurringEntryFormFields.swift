import SwiftUI

/// Estado do formulário de lançamento recorrente
struct RecurringEntryState {
    var type: TransactionType = .expense
    var amount = ""
    var description = ""
    var accountId = ""
    var categoryId = ""
    var frequency: RecurrenceFrequency = .monthly
    var startDate = Date()
    var endDate = Date()
    var hasEndDate = false
}

/// Campos do formulário para lançamento recorrente
struct RecurringEntryFormFields: View {
    @Binding var state: RecurringEntryState
    let accounts: [AccountResponseDto]
    let categorySections: [CategorySection]
    
    /// Tipos permitidos para recorrência (sem transferência)
    private let allowedTypes: [TransactionType] = [.income, .expense]
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.item) {
            typeSelector
            frequencySelector
            
            TransactionDateRow(label: "Início", date: $state.startDate)
            
            endDateSection
            
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
            
            TransactionField(label: "Valor") {
                CurrencyMaskedTextField(text: $state.amount, placeholder: "R$ 0,00")
            }
            
            TransactionField(label: "Descrição") {
                TextField("Ex: Academia", text: $state.description)
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
                ForEach(allowedTypes, id: \.rawValue) { item in
                    Text(item.label).tag(item)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var frequencySelector: some View {
        TransactionPickerRow(
            label: "Frequência",
            value: state.frequency.label,
            placeholder: "Selecione"
        ) {
            ForEach(RecurrenceFrequency.allCases) { item in
                Button(item.label) {
                    state.frequency = item
                }
            }
        }
    }
    
    private var endDateSection: some View {
        Group {
            Toggle(isOn: $state.hasEndDate) {
                Text("Tem data fim")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)
            }
            .tint(DS.Colors.primary)
            
            if state.hasEndDate {
                TransactionDateRow(label: "Fim", date: $state.endDate)
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

extension RecurringEntryState {
    var isValid: Bool {
        guard CurrencyTextField.value(from: amount) != nil else { return false }
        guard !accountId.isEmpty else { return false }
        if hasEndDate {
            return endDate >= startDate
        }
        return true
    }
}
