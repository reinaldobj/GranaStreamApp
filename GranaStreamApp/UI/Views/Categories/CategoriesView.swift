import SwiftUI

struct CategoriesView: View {
    @StateObject private var viewModel = CategoriesViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var formMode: CategoryFormMode?
    @State private var searchText = ""
    @State private var hasFinishedInitialLoad = false
    @State private var categoryPendingDelete: CategoryResponseDto?
    @State private var typeFilter: CategoryListTypeFilter = .all

    private let sectionSpacing = AppTheme.Spacing.item

    var body: some View {
        GeometryReader { proxy in
            let topBackgroundHeight = max(240, proxy.size.height * 0.34)

            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    DS.Colors.primary
                        .frame(height: topBackgroundHeight)
                        .frame(maxWidth: .infinity)

                    DS.Colors.surface2
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        topBlock
                            .padding(.top, 2)

                        categoriesSection(viewportHeight: proxy.size.height)
                            .padding(.top, sectionSpacing)
                    }
                }
                .refreshable {
                    await viewModel.load()
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $formMode) { mode in
            CategoryFormView(existing: mode.existing) {
                Task { await viewModel.load(syncReferenceData: true) }
            }
            .presentationDetents([.fraction(0.72)])
            .presentationDragIndicator(.visible)
        }
        .alert(
            "Excluir categoria?",
            isPresented: Binding(
                get: { categoryPendingDelete != nil },
                set: { isPresented in
                    if !isPresented { categoryPendingDelete = nil }
                }
            )
        ) {
            Button("Cancelar", role: .cancel) {
                categoryPendingDelete = nil
            }
            Button("Excluir", role: .destructive) {
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
            hasFinishedInitialLoad = true
        }
        .errorAlert(message: $viewModel.errorMessage)
        .tint(DS.Colors.primary)
        .simultaneousGesture(backSwipeGesture)
    }

    private var topBlock: some View {
        VStack(spacing: AppTheme.Spacing.item) {
            header
            typeFilterRow

            CategorySearchField(text: $searchText) {
                viewModel.applySearch(term: searchText)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.screen)
        .padding(.top, 6)
        .padding(.bottom, 0)
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(DS.Colors.surface.opacity(0.45))
                    .clipShape(Circle())
            }
            .foregroundColor(DS.Colors.onPrimary)

            Spacer()

            Text("Categorias")
                .font(AppTheme.Typography.title)
                .foregroundColor(DS.Colors.onPrimary)

            Spacer()

            HStack(spacing: 10) {
                Button {
                    Task { await viewModel.seed() }
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 40, height: 40)
                        .background(DS.Colors.surface.opacity(0.45))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Categorias padrão")

                Button {
                    formMode = .new
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 40, height: 40)
                        .background(DS.Colors.surface.opacity(0.45))
                        .clipShape(Circle())
                }
            }
            .foregroundColor(DS.Colors.onPrimary)
        }
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
            .padding(.horizontal, AppTheme.Spacing.screen)
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
                    .font(AppTheme.Typography.body)
                    .foregroundColor(DS.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                ForEach(Array(orderedParents.enumerated()), id: \.element.id) { index, parent in
                    if let section = sectionsById[parent.id] {
                        sectionHeader(for: section)
                            .padding(.leading, 4)
                            .padding(.top, index == 0 ? 14 : 0)

                        LazyVStack(spacing: 12) {
                            ForEach(Array(section.children.enumerated()), id: \.element.id) { rowIndex, child in
                                categoryRow(for: child)

                                if rowIndex < section.children.count - 1 {
                                    Divider()
                                        .overlay(DS.Colors.border)
                                }
                            }
                        }
                    } else if leafIds.contains(parent.id) {
                        categoryRow(for: parent)
                            .padding(.top, index == 0 ? 14 : 0)
                    }
                }

                ForEach(Array(otherSections.enumerated()), id: \.element.id) { sectionIndex, section in
                    sectionHeader(for: section)
                        .padding(.leading, 4)
                        .padding(.top, orderedParents.isEmpty && sectionIndex == 0 ? 14 : 0)

                    LazyVStack(spacing: 12) {
                        ForEach(Array(section.children.enumerated()), id: \.element.id) { rowIndex, child in
                            categoryRow(for: child)

                            if rowIndex < section.children.count - 1 {
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
            Button("Editar") {
                formMode = .edit(category)
            }
            Button("Excluir", role: .destructive) {
                categoryPendingDelete = category
            }
        }
    }

    private func sectionHeader(for section: CategorySection) -> some View {
        HStack(spacing: 8) {
            Text(section.title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)

            Spacer()

            if let parent = section.parent {
                Menu {
                    Button("Editar") {
                        formMode = .edit(parent)
                    }
                    Button("Excluir", role: .destructive) {
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

    private var grouping: (sections: [CategorySection], leafParents: [CategoryResponseDto]) {
        groupCategoriesForList(filteredCategoriesByType)
    }

    private var sectionsById: [String: CategorySection] {
        Dictionary(uniqueKeysWithValues: grouping.sections.map { ($0.id, $0) })
    }

    private var otherSections: [CategorySection] {
        grouping.sections.filter { $0.parent == nil }
    }

    private var leafIds: Set<String> {
        Set(grouping.leafParents.map(\.id))
    }

    private var orderedParents: [CategoryResponseDto] {
        filteredCategoriesByType
            .filter { $0.parentCategoryId == nil }
            .sorted { lhs, rhs in
                if lhs.sortOrder == rhs.sortOrder {
                    return (lhs.name ?? "").localizedCaseInsensitiveCompare(rhs.name ?? "") == .orderedAscending
                }
                return lhs.sortOrder < rhs.sortOrder
            }
    }

    private var filteredCategoriesByType: [CategoryResponseDto] {
        guard typeFilter != .all else { return viewModel.categories }

        return viewModel.categories.filter { category in
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

    private var hasRows: Bool {
        !grouping.sections.isEmpty || !grouping.leafParents.isEmpty
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
        return "Sem categorias cadastradas."
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(DS.Colors.primary)
            Text("Carregando categorias...")
                .font(AppTheme.Typography.body)
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
