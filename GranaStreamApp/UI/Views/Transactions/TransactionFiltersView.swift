import SwiftUI

struct TransactionFiltersView: View {
    @Binding var filters: TransactionFilters
    var onApply: () -> Void

    @EnvironmentObject private var referenceStore: ReferenceDataStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Período") {
                    DatePicker("Início", selection: $filters.startDate, displayedComponents: .date)
                    DatePicker("Fim", selection: $filters.endDate, displayedComponents: .date)
                }

                Section("Tipo") {
                    Picker("Tipo", selection: Binding(
                        get: { filters.type ?? TransactionType.income },
                        set: { filters.type = $0 }
                    )) {
                        ForEach(TransactionType.allCases) { type in
                            Text(type.label).tag(type)
                        }
                    }
                    Toggle("Todos os tipos", isOn: Binding(
                        get: { filters.type == nil },
                        set: { filters.type = $0 ? nil : TransactionType.income }
                    ))
                }

                Section("Conta") {
                    Picker("Conta", selection: Binding(
                        get: { filters.accountId ?? "" },
                        set: { filters.accountId = $0.isEmpty ? nil : $0 }
                    )) {
                        Text("Todas").tag("")
                        ForEach(referenceStore.accounts) { account in
                            Text(account.name ?? "Conta").tag(account.id)
                        }
                    }
                }

                Section("Categoria") {
                    Picker("Categoria", selection: Binding(
                        get: { filters.categoryId ?? "" },
                        set: { filters.categoryId = $0.isEmpty ? nil : $0 }
                    )) {
                        Text("Todas").tag("")
                        ForEach(referenceStore.categories) { category in
                            Text(category.name ?? "Categoria").tag(category.id)
                        }
                    }
                }

                Section("Busca") {
                    TextField("Descrição", text: $filters.searchText)
                }
            }
            .listRowBackground(DS.Colors.surface)
            .scrollContentBackground(.hidden)
            .background(DS.Colors.background)
            .navigationTitle("Filtros")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Aplicar") {
                        onApply()
                        dismiss()
                    }
                }
            }
        }
        .tint(DS.Colors.primary)
    }
}
