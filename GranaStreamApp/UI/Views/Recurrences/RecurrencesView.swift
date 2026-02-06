import SwiftUI

struct RecurrencesView: View {
    @StateObject private var viewModel = RecurrencesViewModel()
    @State private var showForm = false
    @State private var selectedRecurrence: RecurrenceResponseDto?

    var body: some View {
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
                .swipeActions(edge: .leading) {
                    Button {
                        selectedRecurrence = recurrence
                        showForm = true
                    } label: {
                        Label("Editar", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        Task { await viewModel.delete(id: recurrence.id) }
                    } label: {
                        Label("Excluir", systemImage: "trash")
                    }
                }
                .swipeActions {
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
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(DS.Colors.background)
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
