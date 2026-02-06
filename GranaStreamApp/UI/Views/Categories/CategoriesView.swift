import SwiftUI

struct CategoriesView: View {
    @StateObject private var viewModel = CategoriesViewModel()
    @State private var showForm = false
    @State private var selectedCategory: CategoryResponseDto?

    var body: some View {
        List {
            ForEach(viewModel.categories) { category in
                AppCard {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.base) {
                        Text(category.name ?? "Categoria")
                            .font(AppTheme.Typography.section)
                            .foregroundColor(DS.Colors.textPrimary)
                        Text(category.categoryTypeLabel)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(DS.Colors.textSecondary)
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)
                .swipeActions(edge: .leading) {
                    Button {
                        selectedCategory = category
                        showForm = true
                    } label: {
                        Label("Editar", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        Task { await viewModel.delete(category: category) }
                    } label: {
                        Label("Excluir", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(DS.Colors.background)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Categorias padrão") {
                    Task { await viewModel.seed() }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    selectedCategory = nil
                    showForm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showForm) {
            CategoryFormView(existing: selectedCategory) {
                Task { await viewModel.load() }
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .errorAlert(message: $viewModel.errorMessage)
        .tint(DS.Colors.primary)
    }
}
