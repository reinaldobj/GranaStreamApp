import SwiftUI

struct CategoryFormView: View {
    let existing: CategoryResponseDto?
    var onComplete: () -> Void

    @EnvironmentObject private var referenceStore: ReferenceDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var type: CategoryType = .expense
    @State private var parentId: String = ""
    @State private var sortOrder = "0"
    @State private var errorMessage: String?

    @StateObject private var viewModel = CategoriesViewModel()

    var body: some View {
        NavigationStack {
            Form {
                TextField("Nome", text: $name)
                TextField("Descrição", text: $description)
                Picker("Tipo", selection: $type) {
                    ForEach(CategoryType.allCases) { item in
                        Text(item.label).tag(item)
                    }
                }
                Picker("Categoria pai", selection: $parentId) {
                    Text("Nenhuma").tag("")
                    ForEach(referenceStore.categories) { category in
                        Text(category.name ?? "Categoria").tag(category.id)
                    }
                }
                TextField("Ordem", text: $sortOrder)
                    .keyboardType(.numberPad)
            }
            .listRowBackground(DS.Colors.surface)
            .scrollContentBackground(.hidden)
            .background(DS.Colors.background)
            .navigationTitle(existing == nil ? "Nova categoria" : "Editar categoria")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Salvar") {
                        Task { await save() }
                    }
                    .disabled(name.isEmpty)
                }
            }
            .task { prefill() }
            .errorAlert(message: $errorMessage)
        }
        .tint(DS.Colors.primary)
    }

    private func prefill() {
        guard let existing else { return }
        name = existing.name ?? ""
        description = existing.description ?? ""
        parentId = existing.parentCategoryId ?? ""
        sortOrder = String(existing.sortOrder)
    }

    private func save() async {
        let orderValue = Int(sortOrder) ?? 0
        let parent = parentId.isEmpty ? nil : parentId
        if let existing {
            let success = await viewModel.update(
                category: existing,
                name: name,
                description: description,
                type: type,
                parentId: parent,
                sortOrder: orderValue
            )
            if success {
                onComplete()
                dismiss()
            } else {
                errorMessage = viewModel.errorMessage
            }
        } else {
            let success = await viewModel.create(
                name: name,
                description: description,
                type: type,
                parentId: parent,
                sortOrder: orderValue
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
