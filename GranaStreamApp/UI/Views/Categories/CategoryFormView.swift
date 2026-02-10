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
            referenceStore: ReferenceDataStore.shared
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
            AppCard {
                VStack(spacing: DS.Spacing.item) {
                    AppFormField(label: "Tipo") {
                        Picker("Tipo", selection: $viewModel.type) {
                            ForEach(CategoryType.formSelectableCases) { item in
                                Text(item.label).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }

                    TransactionPickerRow(
                        label: "Categoria pai",
                        value: parentName,
                        placeholder: "Nenhuma"
                    ) {
                        Button("Nenhuma") {
                            viewModel.parentId = ""
                        }
                        ForEach(viewModel.parentOptions) { category in
                            Button(category.name ?? "Categoria") {
                                viewModel.parentId = category.id
                            }
                        }
                    }

                    AppFormField(label: "Nome") {
                        TextField("Nome", text: $viewModel.name)
                            .textInputAutocapitalization(.sentences)
                    }

                    AppFormField(label: "Descrição") {
                        TextField("Descrição", text: $viewModel.description)
                            .textInputAutocapitalization(.sentences)
                    }

                    TransactionPickerRow(
                        label: "Ordem",
                        value: "\(viewModel.sortOrder)",
                        placeholder: "0"
                    ) {
                        ForEach(0...4, id: \.self) { value in
                            Button("\(value)") {
                                viewModel.sortOrder = value
                            }
                        }
                    }
                }
            }
        }
        .tint(DS.Colors.primary)
        .task {
            await viewModel.loadReferenceDataIfNeeded()
        }
    }
}

private extension CategoryType {
    static var formSelectableCases: [CategoryType] {
        [.income, .expense]
    }
}

private extension CategoryFormView {
    var parentName: String? {
        guard !viewModel.parentId.isEmpty else { return nil }
        return viewModel.parentOptions.first(where: { $0.id == viewModel.parentId })?.name ?? "Categoria"
    }
}
