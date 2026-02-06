import SwiftUI

struct CategoriesView: View {
    @StateObject private var viewModel = CategoriesViewModel()
    @State private var showCreateForm = false
    @State private var selectedCategory: CategoryResponseDto?

    var body: some View {
        let grouping = groupCategoriesForList(viewModel.categories)
        let sectionsById = Dictionary(uniqueKeysWithValues: grouping.sections.map { ($0.id, $0) })
        let leafIds = Set(grouping.leafParents.map(\.id))
        let orderedParents = viewModel.categories
            .filter { $0.parentCategoryId == nil }
            .sorted { lhs, rhs in
                if lhs.sortOrder == rhs.sortOrder {
                    return (lhs.name ?? "").localizedCaseInsensitiveCompare(rhs.name ?? "") == .orderedAscending
                }
                return lhs.sortOrder < rhs.sortOrder
            }

        Group {
            if viewModel.isLoading && viewModel.categories.isEmpty {
                SkeletonListView()
            } else {
                List {
                    ForEach(orderedParents) { parent in
                        if let section = sectionsById[parent.id] {
                            Section(header: sectionHeader(for: section)) {
                                ForEach(section.children) { child in
                                    AppCard {
                                        VStack(alignment: .leading, spacing: AppTheme.Spacing.base) {
                                            Text(child.name ?? "Categoria")
                                                .font(AppTheme.Typography.section)
                                                .foregroundColor(DS.Colors.textPrimary)
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                            Text(child.categoryTypeLabel)
                                                .font(AppTheme.Typography.caption)
                                                .foregroundColor(DS.Colors.textSecondary)
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                        }
                                        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                                        .padding(.leading, 12)
                                    }
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .listRowBackground(Color.clear)
                                    .contentShape(Rectangle())
                                    .swipeActions(edge: .trailing) {
                                        Button {
                                            selectedCategory = child
                                        } label: {
                                            Label("Editar", systemImage: "pencil")
                                        }
                                        .tint(DS.Colors.primary)
                                        Button(role: .destructive) {
                                            Task { await viewModel.delete(category: child) }
                                        } label: {
                                            Label("Excluir", systemImage: "trash")
                                        }
                                        .tint(DS.Colors.error)
                                    }
                                }
                            }
                        } else if leafIds.contains(parent.id) {
                            AppCard {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.base) {
                                    Text(parent.name ?? "Categoria")
                                        .font(AppTheme.Typography.section)
                                        .foregroundColor(DS.Colors.textPrimary)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                    Text(parent.categoryTypeLabel)
                                        .font(AppTheme.Typography.caption)
                                        .foregroundColor(DS.Colors.textSecondary)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                                .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear)
                            .contentShape(Rectangle())
                            .swipeActions(edge: .trailing) {
                                Button {
                                    selectedCategory = parent
                                } label: {
                                    Label("Editar", systemImage: "pencil")
                                }
                                .tint(DS.Colors.primary)
                                Button(role: .destructive) {
                                    Task { await viewModel.delete(category: parent) }
                                } label: {
                                    Label("Excluir", systemImage: "trash")
                                }
                                .tint(DS.Colors.error)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(DS.Colors.background)
                .safeAreaInset(edge: .top) {
                    if viewModel.isLoading && !viewModel.categories.isEmpty {
                        HStack {
                            Spacer()
                            LoadingPillView()
                            Spacer()
                        }
                        .padding(.top, 6)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Categorias padrão") {
                    Task { await viewModel.seed() }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreateForm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateForm) {
            CategoryFormView(existing: nil) {
                Task { await viewModel.load() }
            }
        }
        .sheet(item: $selectedCategory) { category in
            CategoryFormView(existing: category) {
                Task { await viewModel.load() }
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .errorAlert(message: $viewModel.errorMessage)
        .tint(DS.Colors.primary)
    }

    @ViewBuilder
    private func sectionHeader(for section: CategorySection) -> some View {
        HStack(spacing: 8) {
            Text(section.title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)

            Spacer()

            if let parent = section.parent {
                Menu {
                    Button {
                        selectedCategory = parent
                    } label: {
                        Label("Editar", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        Task { await viewModel.delete(category: parent) }
                    } label: {
                        Label("Excluir", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(DS.Colors.textSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .textCase(nil)
    }
}
