import SwiftUI
import Combine

/// Container genérico para formulários que implementam FormViewModel
/// Encapsula lógica comum: loading state, erro handling, botão salvar
struct FormViewContainer<ViewModel: FormViewModel, Content: View>: View {
    @ObservedObject var viewModel: ViewModel
    @State private var isSaving = false
    
    let title: String?
    let content: Content
    let onSaveSuccess: (() -> Void)?
    
    // MARK: - Init
    
    init(
        viewModel: ViewModel,
        title: String? = nil,
        onSaveSuccess: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.viewModel = viewModel
        self.title = title
        self.onSaveSuccess = onSaveSuccess
        self.content = content()
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            DS.Colors.surface2
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: DS.Spacing.lg) {
                    // Conteúdo do formulário
                    content
                        .padding(.horizontal, DS.Spacing.screen)
                    
                    // Botão salvar
                    saveButton
                        .padding(.horizontal, DS.Spacing.screen)
                        .padding(.bottom, DS.Spacing.lg)
                }
                .padding(.top, DS.Spacing.md)
            }
            
            // Overlay de loading
            if isSaving {
                loadingOverlay
            }
            
            // Alerta de erro
            if let error = viewModel.errorMessage, !error.isEmpty {
                errorBanner(message: error)
            }
        }
        .onChange(of: viewModel.isLoading) { _, newValue in
            isSaving = newValue
        }
    }
    
    // MARK: - Subviews
    
    private var saveButton: some View {
        Button(action: handleSave) {
            HStack(spacing: DS.Spacing.md) {
                if isSaving {
                    ProgressView()
                        .tint(DS.Colors.onPrimary)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                }
                Text(L10n.Common.save)
                    .font(AppTheme.Typography.section)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.md)
            .background(DS.Colors.primary)
            .foregroundColor(DS.Colors.onPrimary)
            .cornerRadius(DS.Radius.button)
        }
        .disabled(!viewModel.isValid || isSaving)
        .opacity((!viewModel.isValid || isSaving) ? 0.6 : 1.0)
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: DS.Spacing.md) {
                ProgressView()
                    .tint(DS.Colors.primary)
                Text(L10n.Common.loading)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(DS.Colors.textPrimary)
            }
            .padding(DS.Spacing.lg)
            .background(DS.Colors.surface)
            .cornerRadius(DS.Radius.card)
        }
    }
    
    private func errorBanner(message: String) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: DS.Spacing.md) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(DS.Colors.error)
                    .font(.system(size: 16, weight: .semibold))
                
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text(L10n.Alerts.error)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(DS.Colors.error)
                        .fontWeight(.semibold)
                    
                    Text(message)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)
                        .lineLimit(3)
                }
                
                Spacer()
                
                Button(action: { viewModel.clearError() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DS.Colors.textSecondary)
                }
            }
            .padding(DS.Spacing.md)
            .background(DS.Colors.surface)
            .cornerRadius(DS.Radius.card)
            .padding(DS.Spacing.md)
            
            Spacer()
        }
    }
    
    // MARK: - Actions
    
    private func handleSave() {
        viewModel.clearError()
        
        Task {
            do {
                try await viewModel.save()
                await MainActor.run {
                    onSaveSuccess?()
                }
            } catch {
                await MainActor.run {
                    if viewModel.errorMessage == nil {
                        viewModel.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let mockViewModel = MockFormViewModel()
    
    FormViewContainer(
        viewModel: mockViewModel,
        title: "Exemplo",
        onSaveSuccess: {}
    ) {
        VStack(spacing: DS.Spacing.md) {
            Text("Conteúdo do formulário")
                .font(AppTheme.Typography.body)
                .foregroundColor(DS.Colors.textPrimary)
            
            TextField("Campo", text: .constant(""))
                .padding()
                .background(DS.Colors.surface)
                .cornerRadius(DS.Radius.field)
        }
    }
}

// MARK: - Mock for Preview

private class MockFormViewModel: FormViewModel {
    @Published var isLoading = false
    @Published var errorMessage: String?
    var isValid: Bool { true }
    
    func save() async throws {
        isLoading = true
        try await Task.sleep(nanoseconds: 1_000_000_000)
        isLoading = false
    }
}
