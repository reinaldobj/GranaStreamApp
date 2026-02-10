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
                            ForEach(CategoryType.allCases) { item in
                                Text(item.label).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }

                    AppFormField(label: "Categoria pai") {
                        Picker("Categoria pai", selection: $viewModel.parentId) {
                            Text("Nenhuma").tag("")
                            ForEach(viewModel.parentOptions) { category in
                                Text(category.name ?? "Categoria").tag(category.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    AppFormField(label: "Nome") {
                        TextField("Nome", text: $viewModel.name)
                            .textInputAutocapitalization(.sentences)
                    }

                    AppFormField(label: "Descrição") {
                        TextField("Descrição", text: $viewModel.description)
                            .textInputAutocapitalization(.sentences)
                    }

                    AppFormField(label: "Ordem") {
                        Picker("Ordem", selection: $viewModel.sortOrder) {
                            ForEach(0...4, id: \.self) { value in
                                Text("\(value)").tag(value)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
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
