import SwiftUI

/// Menu de seleção de conta
struct AccountMenuContent: View {
    let accounts: [AccountResponseDto]
    let selection: Binding<String>
    
    var body: some View {
        Button("Limpar seleção") {
            selection.wrappedValue = ""
        }
        .disabled(selection.wrappedValue.isEmpty)

        if accounts.isEmpty {
            Text("Sem contas")
                .font(DS.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)
        } else {
            ForEach(accounts) { account in
                Button(account.name ?? "Conta") {
                    selection.wrappedValue = account.id
                }
            }
        }
    }
}

/// Menu de seleção de categoria
struct CategoryMenuContent: View {
    let sections: [CategorySection]
    let selection: Binding<String>
    
    var body: some View {
        Button("Limpar seleção") {
            selection.wrappedValue = ""
        }
        .disabled(selection.wrappedValue.isEmpty)

        if sections.isEmpty {
            Text("Sem categorias")
                .font(DS.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)
        } else {
            ForEach(sections) { section in
                Text(section.title)
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)
                    .disabled(true)
                ForEach(section.children) { child in
                    Button(child.name ?? "Categoria") {
                        selection.wrappedValue = child.id
                    }
                }
            }
        }
    }
}
