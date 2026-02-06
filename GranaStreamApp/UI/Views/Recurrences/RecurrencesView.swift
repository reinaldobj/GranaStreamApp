import SwiftUI

struct RecurrencesView: View {
    @StateObject private var viewModel = RecurrencesViewModel()
    @State private var showForm = false
    @State private var selectedRecurrence: RecurrenceResponseDto?

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.recurrences.isEmpty {
                SkeletonListView()
            } else {
                List {
                    ForEach(viewModel.recurrences) { recurrence in
                        AppCard {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.base) {
                                Text(recurrence.templateTransaction.description ?? "Recorrência")
                                    .font(AppTheme.Typography.section)
                                    .foregroundColor(DS.Colors.textPrimary)
                                Text("Próxima: \(recurrence.nextOccurrence?.formattedDate() ?? "-")")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(DS.Colors.textSecondary)
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing) {
                            Button {
                                selectedRecurrence = recurrence
                                showForm = true
                            } label: {
                                Label("Editar", systemImage: "pencil")
                            }
                            .tint(DS.Colors.primary)
                            if recurrence.isPaused {
                                Button {
                                    Task { await viewModel.resume(id: recurrence.id) }
                                } label: {
                                    Label("Retomar", systemImage: "play")
                                }
                                .tint(DS.Colors.success)
                            } else {
                                Button {
                                    Task { await viewModel.pause(id: recurrence.id) }
                                } label: {
                                    Label("Pausar", systemImage: "pause")
                                }
                                .tint(DS.Colors.warning)
                            }
                            Button(role: .destructive) {
                                Task { await viewModel.delete(id: recurrence.id) }
                            } label: {
                                Label("Excluir", systemImage: "trash")
                            }
                            .tint(DS.Colors.error)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(DS.Colors.background)
                .safeAreaInset(edge: .top) {
                    if viewModel.isLoading && !viewModel.recurrences.isEmpty {
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
        .navigationTitle("Recorrências")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    selectedRecurrence = nil
                    showForm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showForm) {
            RecurrenceFormView(existing: selectedRecurrence) {
                Task { await viewModel.load() }
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .errorAlert(message: $viewModel.errorMessage)
        .tint(DS.Colors.primary)
    }
}
