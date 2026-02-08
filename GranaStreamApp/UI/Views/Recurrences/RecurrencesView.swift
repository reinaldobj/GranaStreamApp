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

    private let sectionSpacing = DS.Spacing.item

    var body: some View {
        ListViewContainer(primaryBackgroundHeight: max(240, UIScreen.main.bounds.height * 0.34)) {
            VStack(spacing: 0) {
                topBlock
                    .padding(.top, DS.Spacing.sm)

                recurrencesSection(viewportHeight: UIScreen.main.bounds.height)
                    .padding(.top, sectionSpacing)
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
            L10n.Recurrences.deleteConfirm,
            isPresented: Binding(
                get: { recurrencePendingDelete != nil },
                set: { isPresented in
                    if !isPresented { recurrencePendingDelete = nil }
                }
            )
        ) {
            Button(L10n.Common.cancel, role: .cancel) {
                recurrencePendingDelete = nil
            }
            Button(L10n.Common.delete, role: .destructive) {
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
        VStack(spacing: DS.Spacing.item) {
            ListHeaderView(
                title: L10n.Recurrences.title,
                searchText: $searchText,
                showSearch: false,
                actions: [
                    HeaderAction(
                        id: "add",
                        systemImage: "plus",
                        action: { 
                            selectedRecurrence = nil
                            showForm = true 
                        }
                    )
                ],
                onDismiss: { dismiss() }
            )
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
        .padding(.horizontal, DS.Spacing.screen)
        .padding(.top, DS.Spacing.sm)
        .padding(.bottom, 0)
    }

    // ...existing code...

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
            .padding(.horizontal, DS.Spacing.screen)
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
                Text(activeSearchTerm.isEmpty ? L10n.Recurrences.empty : "Nenhuma recorrência encontrada.")
                    .font(DS.Typography.body)
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
                        Button(L10n.Common.edit) {
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
                        Button(L10n.Common.delete, role: .destructive) {
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
            VStack(alignment: .leading, spacing: DS.Spacing.base) {
                Text(recurrence.templateTransaction.description ?? "Recorrência")
                    .font(DS.Typography.section)
                    .foregroundColor(DS.Colors.textPrimary)

                HStack(spacing: 8) {
                    Text("Próxima: \(recurrence.nextOccurrence?.formattedDate() ?? "-")")
                        .font(DS.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)
                    Spacer(minLength: 8)
                    Text(recurrence.isPaused ? "Pausada" : "Ativa")
                        .font(DS.Typography.caption)
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
            Text(L10n.Recurrences.loading)
                .font(DS.Typography.body)
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
