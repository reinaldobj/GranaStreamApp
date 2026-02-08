import SwiftUI

/// Modelo para ação de header
struct HeaderAction {
    let id: String
    let systemImage: String
    let label: String?
    let accessibilityLabel: String?
    let action: () -> Void
    let isDestructive: Bool
    
    init(
        id: String,
        systemImage: String,
        label: String? = nil,
        accessibilityLabel: String? = nil,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.id = id
        self.systemImage = systemImage
        self.label = label
        self.accessibilityLabel = accessibilityLabel
        self.isDestructive = isDestructive
        self.action = action
    }
}

/// Header genérico reutilizável para list views
/// Suporta: título, busca, múltiplas ações
struct ListHeaderView: View {
    let title: String
    let searchText: Binding<String>
    let showSearch: Bool
    let actions: [HeaderAction]
    let onDismiss: (() -> Void)?
    
    init(
        title: String,
        searchText: Binding<String>,
        showSearch: Bool,
        actions: [HeaderAction],
        onDismiss: (() -> Void)? = nil
    ) {
        self.title = title
        self.searchText = searchText
        self.showSearch = showSearch
        self.actions = actions
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            // Header com título e ações
            HStack {
                // Botão voltar (esquerda)
                if let onDismiss = onDismiss {
                    Button(action: onDismiss) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: DS.Spacing.iconMedium, height: DS.Spacing.iconMedium)
                            .background(DS.Colors.surface.opacity(DS.Opacity.medium))
                            .clipShape(Circle())
                    }
                    .foregroundColor(DS.Colors.onPrimary)
                }
                
                Spacer()
                
                // Título
                Text(title)
                    .font(DS.Typography.title)
                    .foregroundColor(DS.Colors.onPrimary)
                
                Spacer()
                
                // Ações (direita)
                if actions.isEmpty {
                    // Placeholder para manter espaçamento
                    if onDismiss != nil {
                        Color.clear
                            .frame(width: DS.Spacing.iconMedium, height: DS.Spacing.iconMedium)
                    }
                } else if actions.count == 1 {
                    actionButton(actions[0])
                } else {
                    HStack(spacing: DS.Spacing.md) {
                        ForEach(actions, id: \.id) { action in
                            actionButton(action)
                        }
                    }
                }
            }
            
            // Barra de busca (opcional)
            if showSearch {
                SearchBar(text: searchText)
            }
        }
    }
    
    private func actionButton(_ action: HeaderAction) -> some View {
        Button(action: action.action) {
            Image(systemName: action.systemImage)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: DS.Spacing.iconMedium, height: DS.Spacing.iconMedium)
                .background(DS.Colors.surface.opacity(DS.Opacity.medium))
                .clipShape(Circle())
        }
        .foregroundColor(action.isDestructive ? DS.Colors.error : DS.Colors.onPrimary)
        .accessibilityLabel(action.accessibilityLabel ?? action.label ?? "")
    }
}

/// Barra de busca reutilizável
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(DS.Colors.textSecondary)
            
            TextField(L10n.Common.loading, text: $text)
                .font(DS.Typography.body)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DS.Colors.textSecondary)
                }
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
        .background(DS.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.field))
    }
}

#Preview {
    VStack(spacing: DS.Spacing.lg) {
        // Preview 1: Com title e ação única
        ListHeaderView(
            title: "Transações",
            searchText: .constant(""),
            showSearch: false,
            actions: [
                HeaderAction(
                    id: "add",
                    systemImage: "plus",
                    action: {}
                )
            ]
        )
        .padding()
        .background(DS.Colors.primary)
        
        // Preview 2: Com title, múltiplas ações e busca
        ListHeaderView(
            title: "Categorias",
            searchText: .constant(""),
            showSearch: true,
            actions: [
                HeaderAction(
                    id: "seed",
                    systemImage: "arrow.triangle.2.circlepath.circle.fill",
                    accessibilityLabel: "Categorias padrão",
                    action: {}
                ),
                HeaderAction(
                    id: "add",
                    systemImage: "plus",
                    action: {}
                )
            ]
        )
        .padding()
        .background(DS.Colors.primary)
        
        // Preview 3: Com botão voltar
        ListHeaderView(
            title: "Pendências",
            searchText: .constant(""),
            showSearch: false,
            actions: [],
            onDismiss: {}
        )
        .padding()
        .background(DS.Colors.primary)
        
        Spacer()
    }
}
