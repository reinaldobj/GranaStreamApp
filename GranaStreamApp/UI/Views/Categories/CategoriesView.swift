import SwiftUI

struct CategoriesView: View {
    @StateObject private var viewModel = CategoriesViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var formMode: CategoryFormMode?
    @State private var searchText = ""
    @State private var hasFinishedInitialLoad = false
    @State private var categoryPendingDelete: CategoryResponseDto?
    @State private var typeFilter: CategoryListTypeFilter = .all
    @State private var projection = CategoryProjection.empty

    private let sectionSpacing = DS.Spacing.item

    var body: some View {
        ListViewContainer(primaryBackgroundHeight: max(240, UIScreen.main.bounds.height * 0.34)) {
            VStack(spacing: 0) {
                topBlock
                    .padding(.top, DS.Spacing.sm)

                categoriesSection(viewportHeight: UIScreen.main.bounds.height)
                    .padding(.top, sectionSpacing)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $formMode) { mode in
            CategoryFormView(existing: mode.existing, viewModel: viewModel) { }
            .presentationDetents([.fraction(0.72)])
            .presentationDragIndicator(.visible)
        }
        .alert(
            L10n.Categories.deleteConfirm,
            isPresented: Binding(
                get: { categoryPendingDelete != nil },
                set: { isPresented in
                    if !isPresented { categoryPendingDelete = nil }
                }
            )
        ) {
            Button(L10n.Common.cancel, role: .cancel) {
                categoryPendingDelete = nil
            }
            Button(L10n.Common.delete, role: .destructive) {
                guard let category = categoryPendingDelete else { return }
                categoryPendingDelete = nil
                Task { await viewModel.delete(category: category) }
            }
        } message: {
            Text(deleteMessage)
        }
        .task {
            searchText = viewModel.activeSearchTerm
            await viewModel.load()
            rebuildProjection()
            hasFinishedInitialLoad = true
        }
        .onChange(of: typeFilter) { _, _ in
            rebuildProjection()
        }
        .onReceive(viewModel.$loadingState) { _ in
            rebuildProjection()
        }
        .errorAlert(message: $viewModel.errorMessage)
        .tint(DS.Colors.primary)
        .simultaneousGesture(backSwipeGesture)
    }

    private var topBlock: some View {
        VStack(spacing: DS.Spacing.item) {
            ListHeaderView(
                title: L10n.Categories.title,
                searchText: $searchText,
                showSearch: false,
                actions: [
                    HeaderAction(
                        id: "seed",
                        systemImage: "arrow.triangle.2.circlepath.circle.fill",
                        accessibilityLabel: L10n.Categories.seed,
                        action: { Task { await viewModel.seed() } }
                    ),
                    HeaderAction(
                        id: "add",
                        systemImage: "plus",
                        action: { formMode = .new }
                    )
                ],
                onDismiss: { dismiss() }
            )
            
            typeFilterRow

            CategorySearchField(text: $searchText) {
                viewModel.applySearch(term: searchText)
            }

            if viewModel.isLoading && !viewModel.categories.isEmpty {
                HStack {
                    Spacer()
                    LoadingPillView()
                    Spacer()
                }
            }
        }
        .padding(.horizontal, DS.Spacing.screen)
        .padding(.top, 6)
        .padding(.bottom, 0)
    }

    private var typeFilterRow: some View {
        Picker("Tipo", selection: $typeFilter) {
            ForEach(CategoryListTypeFilter.allCases) { item in
                Text(item.title).tag(item)
            }
        }
        .pickerStyle(.segmented)
    }

    private var backSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 16, coordinateSpace: .local)
            .onEnded { value in
                let fromLeftEdge = value.startLocation.x < 28
                let hasHorizontalIntent = value.translation.width > 80 && abs(value.translation.height) < 60
                guard fromLeftEdge && hasHorizontalIntent else { return }
                dismiss()
            }
    }

    private func categoriesSection(viewportHeight: CGFloat) -> some View {
        let emptyMinHeight = max(320, viewportHeight * 0.52)

        return categoriesCard
            .padding(.horizontal, DS.Spacing.screen)
            .padding(.top, 6)
            .frame(
                maxWidth: .infinity,
                minHeight: !hasRows ? emptyMinHeight : nil,
                alignment: .top
            )
            .topSectionStyle()
    }

    private var categoriesCard: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            if shouldShowLoadingState {
                loadingState
            } else if !hasRows {
                Text(emptyMessage)
                    .font(DS.Typography.body)
                    .foregroundColor(DS.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                let firstParentId = projection.orderedParents.first?.id

                ForEach(projection.orderedParents) { parent in
                    if let section = projection.sectionsById[parent.id] {
                        let lastChildId = section.children.last?.id

                        sectionHeader(for: section)
                            .padding(.leading, 4)
                            .padding(.top, parent.id == firstParentId ? 14 : 0)

                        LazyVStack(spacing: 12) {
                            ForEach(section.children) { child in
                                categoryRow(for: child)

                                if child.id != lastChildId {
                                    Divider()
                                        .overlay(DS.Colors.border)
                                }
                            }
                        }
                    } else if projection.leafIds.contains(parent.id) {
                        categoryRow(for: parent)
                            .padding(.top, parent.id == firstParentId ? 14 : 0)
                    }
                }

                let firstOtherSectionId = projection.otherSections.first?.id

                ForEach(projection.otherSections) { section in
                    let lastChildId = section.children.last?.id

                    sectionHeader(for: section)
                        .padding(.leading, 4)
                        .padding(.top, projection.orderedParents.isEmpty && section.id == firstOtherSectionId ? 14 : 0)

                    LazyVStack(spacing: 12) {
                        ForEach(section.children) { child in
                            categoryRow(for: child)

                            if child.id != lastChildId {
                                Divider()
                                    .overlay(DS.Colors.border)
                            }
                        }
                    }
                }
            }
        }
        .padding(.top, 14)
    }

    private func categoryRow(for category: CategoryResponseDto) -> some View {
        TransactionSwipeRow(
            onTap: {},
            onEdit: {
                formMode = .edit(category)
            },
            onDelete: {
                categoryPendingDelete = category
            }
        ) {
            CategoryRowView(category: category)
        }
        .contextMenu {
            Button(L10n.Common.edit) {
                formMode = .edit(category)
            }
            Button(L10n.Common.delete, role: .destructive) {
                categoryPendingDelete = category
            }
        }
    }

    private func sectionHeader(for section: CategorySection) -> some View {
        HStack(spacing: 8) {
            Text(section.title)
                .font(DS.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)

            Spacer()

            if let parent = section.parent {
                Menu {
                    Button(L10n.Common.edit) {
                        formMode = .edit(parent)
                    }
                    Button(L10n.Common.delete, role: .destructive) {
                        categoryPendingDelete = parent
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(DS.Colors.textSecondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var hasRows: Bool {
        projection.hasRows
    }

    private var shouldShowLoadingState: Bool {
        !hasFinishedInitialLoad || (viewModel.isLoading && viewModel.categories.isEmpty)
    }

    private var emptyMessage: String {
        if !viewModel.activeSearchTerm.isEmpty {
            return "Nenhuma categoria encontrada."
        }
        if typeFilter != .all {
            return "Nenhuma categoria deste tipo."
        }
        return L10n.Categories.empty
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(DS.Colors.primary)
            Text("Carregando categorias...")
                .font(DS.Typography.body)
                .foregroundColor(DS.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 24)
    }

    private var deleteMessage: String {
        let name = categoryPendingDelete?.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let name, !name.isEmpty {
            return "Você realmente quer excluir a categoria \"\(name)\"?"
        }
        return "Você realmente quer excluir esta categoria?"
    }

    private func rebuildProjection() {
        projection = CategoryProjection.build(
            from: viewModel.categories,
            typeFilter: typeFilter
        )
    }
}

private enum CategoryFormMode: Identifiable {
    case new
    case edit(CategoryResponseDto)

    var id: String {
        switch self {
        case .new:
            return "new"
        case .edit(let category):
            return "edit-\(category.id)"
        }
    }

    var existing: CategoryResponseDto? {
        switch self {
        case .new:
            return nil
        case .edit(let category):
            return category
        }
    }
}

private enum CategoryListTypeFilter: String, CaseIterable, Identifiable {
    case all
    case income
    case expense

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "Todas"
        case .income:
            return "Receita"
        case .expense:
            return "Despesa"
        }
    }
}

private struct CategoryProjection {
    let orderedParents: [CategoryResponseDto]
    let sectionsById: [String: CategorySection]
    let otherSections: [CategorySection]
    let leafIds: Set<String>

    static let empty = CategoryProjection(
        orderedParents: [],
        sectionsById: [:],
        otherSections: [],
        leafIds: []
    )

    var hasRows: Bool {
        !orderedParents.isEmpty || !otherSections.isEmpty || !leafIds.isEmpty
    }

    static func build(from categories: [CategoryResponseDto], typeFilter: CategoryListTypeFilter) -> CategoryProjection {
        let filteredCategories: [CategoryResponseDto]
        if typeFilter == .all {
            filteredCategories = categories
        } else {
            filteredCategories = categories.filter { category in
                switch typeFilter {
                case .all:
                    return true
                case .income:
                    return category.categoryType == .income || category.categoryType == .both
                case .expense:
                    return category.categoryType == .expense || category.categoryType == .both
                }
            }
        }

        let grouping = groupCategoriesForList(filteredCategories)
        let sectionsById = Dictionary(uniqueKeysWithValues: grouping.sections.map { ($0.id, $0) })
        let otherSections = grouping.sections.filter { $0.parent == nil }
        let leafIds = Set(grouping.leafParents.map(\.id))

        let orderedParents = filteredCategories
            .filter { $0.parentCategoryId == nil }
            .sorted { lhs, rhs in
                if lhs.sortOrder == rhs.sortOrder {
                    return (lhs.name ?? "").localizedCaseInsensitiveCompare(rhs.name ?? "") == .orderedAscending
                }
                return lhs.sortOrder < rhs.sortOrder
            }

        return CategoryProjection(
            orderedParents: orderedParents,
            sectionsById: sectionsById,
            otherSections: otherSections,
            leafIds: leafIds
        )
    }
}
