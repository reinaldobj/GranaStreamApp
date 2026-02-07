import SwiftUI

struct RecurrencesView: View {
    @StateObject private var viewModel = RecurrencesViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var showForm = false
    @State private var selectedRecurrence: RecurrenceResponseDto?
    @State private var recurrencePendingDelete: RecurrenceResponseDto?
    @State private var searchText = ""
    @State private var activeSearchTerm = ""
    @State private var hasFinishedInitialLoad = false

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

                        recurrencesSection(viewportHeight: proxy.size.height)
                            .padding(.top, sectionSpacing)
                    }
                }
                .refreshable {
                    await viewModel.load()
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showForm) {
            RecurrenceFormView(existing: selectedRecurrence) {
                Task { await viewModel.load() }
            }
            .presentationDetents([.fraction(0.86)])
            .presentationDragIndicator(.visible)
        }
        .alert(
            "Excluir recorrência?",
            isPresented: Binding(
                get: { recurrencePendingDelete != nil },
                set: { isPresented in
                    if !isPresented { recurrencePendingDelete = nil }
                }
            )
        ) {
            Button("Cancelar", role: .cancel) {
                recurrencePendingDelete = nil
            }
            Button("Excluir", role: .destructive) {
                guard let recurrence = recurrencePendingDelete else { return }
                recurrencePendingDelete = nil
                Task { await viewModel.delete(id: recurrence.id) }
            }
        } message: {
            Text(deleteMessage)
        }
        .task {
            await viewModel.load()
            hasFinishedInitialLoad = true
        }
        .onChange(of: searchText) { _, newValue in
            applySearch(term: newValue)
        }
        .errorAlert(message: $viewModel.errorMessage)
        .tint(DS.Colors.primary)
        .simultaneousGesture(backSwipeGesture)
    }

    private var topBlock: some View {
        VStack(spacing: AppTheme.Spacing.item) {
            header
            AppSearchField(
                placeholder: "Buscar recorrência por nome",
                text: $searchText
            ) {
                applySearch(term: searchText)
            }
            if viewModel.isLoading && !viewModel.recurrences.isEmpty {
                HStack {
                    Spacer()
                    LoadingPillView()
                    Spacer()
                }
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

            Text("Recorrências")
                .font(AppTheme.Typography.title)
                .foregroundColor(DS.Colors.onPrimary)

            Spacer()

            Button {
                selectedRecurrence = nil
                showForm = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(DS.Colors.surface.opacity(0.45))
                    .clipShape(Circle())
            }
            .foregroundColor(DS.Colors.onPrimary)
        }
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

    private func recurrencesSection(viewportHeight: CGFloat) -> some View {
        let emptyMinHeight = max(320, viewportHeight * 0.52)

        return recurrencesCard
            .padding(.horizontal, AppTheme.Spacing.screen)
            .padding(.top, 6)
            .frame(
                maxWidth: .infinity,
                minHeight: filteredRecurrences.isEmpty ? emptyMinHeight : nil,
                alignment: .top
            )
            .topSectionStyle()
    }

    private var recurrencesCard: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            if shouldShowLoadingState {
                loadingState
            } else if filteredRecurrences.isEmpty {
                Text(activeSearchTerm.isEmpty ? "Sem recorrências cadastradas." : "Nenhuma recorrência encontrada.")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(DS.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                ForEach(Array(filteredRecurrences.enumerated()), id: \.element.id) { index, recurrence in
                    TransactionSwipeRow(
                        onTap: {},
                        onEdit: {
                            selectedRecurrence = recurrence
                            showForm = true
                        },
                        onDelete: {
                            recurrencePendingDelete = recurrence
                        }
                    ) {
                        recurrenceRow(recurrence: recurrence)
                    }
                    .contextMenu {
                        Button("Editar") {
                            selectedRecurrence = recurrence
                            showForm = true
                        }
                        if recurrence.isPaused {
                            Button("Retomar") {
                                Task { await viewModel.resume(id: recurrence.id) }
                            }
                        } else {
                            Button("Pausar") {
                                Task { await viewModel.pause(id: recurrence.id) }
                            }
                        }
                        Button("Excluir", role: .destructive) {
                            recurrencePendingDelete = recurrence
                        }
                    }

                    if index < filteredRecurrences.count - 1 {
                        Divider()
                            .overlay(DS.Colors.border)
                    }
                }
            }
        }
        .padding(.top, 14)
    }

    private func recurrenceRow(recurrence: RecurrenceResponseDto) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.base) {
                Text(recurrence.templateTransaction.description ?? "Recorrência")
                    .font(AppTheme.Typography.section)
                    .foregroundColor(DS.Colors.textPrimary)

                HStack(spacing: 8) {
                    Text("Próxima: \(recurrence.nextOccurrence?.formattedDate() ?? "-")")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)
                    Spacer(minLength: 8)
                    Text(recurrence.isPaused ? "Pausada" : "Ativa")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(recurrence.isPaused ? DS.Colors.warning : DS.Colors.success)
                }
            }
        }
    }

    private var filteredRecurrences: [RecurrenceResponseDto] {
        let term = activeSearchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return viewModel.recurrences }

        return viewModel.recurrences.filter { recurrence in
            let title = recurrence.templateTransaction.description ?? ""
            return title.localizedCaseInsensitiveContains(term)
        }
    }

    private var shouldShowLoadingState: Bool {
        !hasFinishedInitialLoad || (viewModel.isLoading && viewModel.recurrences.isEmpty)
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(DS.Colors.primary)
            Text("Carregando recorrências...")
                .font(AppTheme.Typography.body)
                .foregroundColor(DS.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 24)
    }

    private var deleteMessage: String {
        let label = recurrencePendingDelete?.templateTransaction.description?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let label, !label.isEmpty {
            return "Você realmente quer excluir \"\(label)\"?"
        }
        return "Você realmente quer excluir esta recorrência?"
    }

    private func applySearch(term: String) {
        activeSearchTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
