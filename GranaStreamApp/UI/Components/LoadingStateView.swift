import SwiftUI

/// View genérica que gerencia estados de loading, loaded, error e idle
/// Encapsula lógica comum de exibição de skeleton, conteúdo e erro
struct LoadingStateView<T, Content: View>: View {
    let state: LoadingState<T>
    let content: (T) -> Content
    let skeletonView: AnyView
    let errorContent: (String) -> AnyView
    
    init(
        state: LoadingState<T>,
        content: @escaping (T) -> Content,
        @ViewBuilder skeletonView: () -> some View,
        @ViewBuilder errorContent: @escaping (String) -> some View
    ) {
        self.state = state
        self.content = content
        self.skeletonView = AnyView(skeletonView())
        self.errorContent = { message in AnyView(errorContent(message)) }
    }
    
    var body: some View {
        switch state {
        case .idle, .loading:
            skeletonView
            
        case .loaded(let data):
            content(data)
            
        case .error(let message):
            errorContent(message)
        }
    }
}

// MARK: - Convenience Initializer with Default Error View

extension LoadingStateView {
    init(
        state: LoadingState<T>,
        content: @escaping (T) -> Content,
        @ViewBuilder skeletonView: () -> some View
    ) {
        self.init(
            state: state,
            content: content,
            skeletonView: skeletonView,
            errorContent: { message in
                AnyView(
                    VStack(spacing: DS.Spacing.md) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(DS.Colors.error)
                        
                        VStack(spacing: DS.Spacing.xs) {
                            Text("Erro ao Carregar")
                                .font(DS.Typography.section)
                                .foregroundColor(DS.Colors.textPrimary)
                            
                            Text(message)
                                .font(DS.Typography.caption)
                                .foregroundColor(DS.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(DS.Spacing.lg)
                )
            }
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: DS.Spacing.lg) {
        Text("Loading State")
            .font(DS.Typography.section)
        
        LoadingStateView(
            state: LoadingState<String>.loading,
            content: { data in
                Text(data)
            },
            skeletonView: {
                SkeletonCard()
            }
        )
        
        Text("Loaded State")
            .font(DS.Typography.section)
            .padding(.top, DS.Spacing.lg)
        
        LoadingStateView(
            state: LoadingState<String>.loaded("Sucesso!"),
            content: { data in
                Text(data)
                    .font(DS.Typography.section)
                    .foregroundColor(DS.Colors.textPrimary)
            },
            skeletonView: {
                SkeletonCard()
            }
        )
    }
    .padding()
}
