import SwiftUI

struct QuickActionsView: View {
    @EnvironmentObject private var referenceStore: ReferenceDataStore
    @State private var showTransactionForm = false
    @State private var successMessage: String?
    @State private var successTask: Task<Void, Never>?

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: DS.Spacing.item) {
                AppSectionHeader(text: "Atalhos rápidos")
                HStack(spacing: DS.Spacing.item) {
                    QuickActionButton(title: "+ Transação") {
                        Task {
                            await referenceStore.loadIfNeeded()
                            showTransactionForm = true
                        }
                    }
                    NavigationLink {
                        AccountsView()
                    } label: {
                        QuickActionLabel(title: "Nova conta")
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        CategoriesView()
                    } label: {
                        QuickActionLabel(title: "Categorias")
                    }
                    .buttonStyle(.plain)
                }

                if let successMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(DS.Colors.success)
                        Text(successMessage)
                            .font(DS.Typography.caption)
                            .foregroundColor(DS.Colors.textSecondary)
                    }
                    .transition(.opacity)
                }
            }
        }
        .sheet(isPresented: $showTransactionForm) {
            UnifiedEntryFormView(initialMode: .single) { message in
                showSuccessMessage(message)
            }
            .presentationDetents([.fraction(0.90)])
            .presentationDragIndicator(.visible)
        }
        .onDisappear {
            successTask?.cancel()
            successTask = nil
        }
    }

    private func showSuccessMessage(_ message: String) {
        successTask?.cancel()
        withAnimation(.easeInOut(duration: 0.2)) {
            successMessage = message
        }

        successTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    successMessage = nil
                }
            }
        }
    }
}

struct QuickActionLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(DS.Typography.caption)
            .foregroundColor(DS.Colors.primary)
            .frame(maxWidth: .infinity, minHeight: 36)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.field)
                    .stroke(DS.Colors.border, lineWidth: 1)
            )
    }
}

struct QuickActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            QuickActionLabel(title: title)
        }
    }
}
