import SwiftUI

struct CategoryFormView: View {
    let existing: CategoryResponseDto?
    @ObservedObject var parentViewModel: CategoriesViewModel
    var onComplete: () -> Void

    @EnvironmentObject private var referenceStore: ReferenceDataStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CategoryFormViewModel

    init(existing: CategoryResponseDto?, viewModel: CategoriesViewModel, onComplete: @escaping () -> Void = {}) {
        self.existing = existing
        self.parentViewModel = viewModel
        self.onComplete = onComplete
        _viewModel = StateObject(wrappedValue: CategoryFormViewModel(
            existing: existing,
            categoriesViewModel: viewModel,
            referenceStore: ReferenceDataStore()
        ))
    }

    var body: some View {
        FormViewContainer(
            viewModel: viewModel,
            onSaveSuccess: {
                onComplete()
                dismiss()
            }
        ) {
            VStack(spacing: DS.Spacing.item) {
                TextField("Nome", text: $viewModel.name)
                    .padding()
                    .background(DS.Colors.surface)
                    .cornerRadius(DS.Radius.field)
                
                TextField("Descrição", text: $viewModel.description)
                    .padding()
                    .background(DS.Colors.surface)
                    .cornerRadius(DS.Radius.field)
                
                Picker("Tipo", selection: $viewModel.type) {
                    ForEach(CategoryType.allCases) { item in
                        Text(item.label).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                
                Picker("Categoria pai", selection: $viewModel.parentId) {
                    Text("Nenhuma").tag("")
                    ForEach(viewModel.parentOptions) { category in
                        Text(category.name ?? "Categoria").tag(category.id)
                    }
                }
                .pickerStyle(.automatic)
                
                TextField("Ordem", text: $viewModel.sortOrder)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(DS.Colors.surface)
                    .cornerRadius(DS.Radius.field)
            }
        }
        .tint(DS.Colors.primary)
        .task {
            // Atualizar referenceStore se necessário
        }
    }
}
