# Arquitetura do GranaStreamApp

## Visão Geral

O GranaStreamApp segue o padrão **MVVM (Model-View-ViewModel)** com SwiftUI, utilizando `async/await` para operações assíncronas e `@MainActor` para garantir thread safety.

## Estrutura de Pastas

```
GranaStreamApp/
├── Config/           # Configurações do app (URLs, constantes)
├── DesignSystem/     # Tokens de design (cores, gradientes)
├── Models/           # DTOs e estruturas de dados
├── Networking/       # Cliente HTTP e tratamento de erros
├── Services/         # Serviços (Keychain, AppLock)
├── Stores/           # Estado global compartilhado
├── Theme/            # Tipografia, espaçamentos, raios
├── UI/
│   ├── Components/   # Componentes reutilizáveis
│   └── Views/        # Telas organizadas por feature
├── Utilities/        # Extensions e helpers
└── ViewModels/       # Lógica de negócio das telas
```

## Padrões e Convenções

### Views

- **Responsabilidade**: Apenas renderização de UI e binding com ViewModel
- **Tamanho máximo recomendado**: 300-400 linhas
- **Regras**:
  - Não fazer chamadas de API diretamente
  - Usar `@StateObject` para ViewModels próprios
  - Usar `@EnvironmentObject` para stores globais
  - Extrair subviews quando o body ficar complexo

```swift
struct ExampleView: View {
    @StateObject private var viewModel = ExampleViewModel()
    
    var body: some View {
        // UI apenas - lógica no ViewModel
    }
}
```

### ViewModels

- **Responsabilidade**: Lógica de negócio, estado da tela, chamadas de API
- **Regras**:
  - Sempre usar `@MainActor` na classe
  - Usar `ObservableObject` com `@Published`
  - Métodos públicos devem ser `async` quando fizerem I/O
  - Tratar erros e expor via `errorMessage: String?`

```swift
@MainActor
final class ExampleViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func load() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            items = try await APIClient.shared.request("/api/items")
        } catch {
            errorMessage = error.userMessage
        }
    }
}
```

### Models (DTOs)

- **Responsabilidade**: Estruturas de dados para API e domínio
- **Regras**:
  - Usar `Codable` para serialização
  - Sufixo `Dto` para objetos de transferência
  - Sufixo `RequestDto` / `ResponseDto` quando aplicável
  - Manter em arquivos separados por domínio

```swift
struct CreateItemRequestDto: Codable {
    let name: String
    let amount: Double
}

struct ItemResponseDto: Codable, Identifiable {
    let id: String
    let name: String
}
```

### Stores (Estado Global)

- **Responsabilidade**: Estado compartilhado entre múltiplas telas
- **Quando usar**:
  - Dados de referência (contas, categorias)
  - Estado de autenticação
  - Preferências do usuário
- **Regras**:
  - Singleton via `static let shared`
  - Injetar via `.environmentObject()` no app root

### Networking

- **APIClient**: Cliente HTTP centralizado
- **APIError**: Enum com todos os tipos de erro
- **Regras**:
  - Usar `error.userMessage` para mensagens ao usuário
  - Retry automático em 401 (token refresh)
  - Idempotency-Key em POST/PUT/PATCH

### Components

- **Responsabilidade**: UI reutilizável sem lógica de negócio
- **Regras**:
  - Aceitar dados via parâmetros (não acessar stores)
  - Usar closures para ações (`onTap`, `onDelete`)
  - Seguir design system (DS.Colors, AppTheme.Typography)

## Design System

### Cores
Usar `DS.Colors.*` para todas as cores:
- `DS.Colors.primary` - Cor principal
- `DS.Colors.background` - Fundo das telas
- `DS.Colors.surface` - Fundo de cards
- `DS.Colors.textPrimary` / `textSecondary` - Textos

### Tipografia
Usar `AppTheme.Typography.*`:
- `.title` - Títulos de tela (22pt semibold)
- `.section` - Títulos de seção (17pt semibold)
- `.body` - Texto padrão (15pt)
- `.caption` - Labels e textos menores (13pt)

### Espaçamentos
Usar `AppTheme.Spacing.*`:
- `.base` - 8pt (unidade base)
- `.item` - 12pt (entre itens)
- `.screen` - 16pt (padding de tela)

## Tratamento de Erros

1. **Captura**: No ViewModel, dentro do `catch`
2. **Conversão**: Usar `error.userMessage` (extension em `Error+UserMessage.swift`)
3. **Exibição**: Via `.errorAlert(message: $viewModel.errorMessage)`

```swift
do {
    // operação
} catch {
    errorMessage = error.userMessage // Nunca usar localizedDescription diretamente
}
```

## Testes (Futuro)

> ⚠️ O projeto ainda não possui testes. Priorizar:
> 1. Testes unitários nos ViewModels
> 2. Mockar APIClient via protocolo
> 3. Snapshot tests para componentes críticos

## Tech Debt Tracking

Usamos comentários `// TODO: [TECH-DEBT]` para rastrear dívidas técnicas.
Esses comentários aparecem no Xcode Issue Navigator.

Formato: `// TODO: [TECH-DEBT] Descrição do problema - sugestão de solução`

## Decisões Arquiteturais

| Decisão | Motivo |
|---------|--------|
| `async/await` em vez de Combine | Mais legível, melhor suporte a cancelamento |
| `@MainActor` em VMs | Garante thread safety sem `DispatchQueue.main` |
| Singletons com `.shared` | Simplicidade para MVP, migrar para DI no futuro |
| DTOs separados de Models | Desacoplar API de domínio interno |
