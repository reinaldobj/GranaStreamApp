# Testes do GranaStreamApp

## Configuração Inicial

### 1. Adicionar Target de Testes no Xcode

1. Abra `GranaStreamApp.xcodeproj` no Xcode
2. File → New → Target
3. Selecione "Unit Testing Bundle"
4. Configure:
   - Product Name: `GranaStreamAppTests`
   - Team: Seu time
   - Organization Identifier: Mesmo do app
   - Target to be Tested: `GranaStreamApp`
5. Clique em "Finish"

### 2. Adicionar Arquivos de Teste ao Target

Os arquivos de teste já foram criados em:
```
GranaStreamAppTests/
├── Mocks/
│   └── MockAPIClient.swift
└── ViewModels/
    ├── TransactionsViewModelTests.swift
    ├── AccountsViewModelTests.swift
    └── CategoriesViewModelTests.swift
```

**Para adicionar ao Xcode:**
1. No Project Navigator, clique com botão direito em `GranaStreamAppTests`
2. Selecione "Add Files to GranaStreamAppTests..."
3. Navegue até a pasta `GranaStreamAppTests`
4. Selecione todos os arquivos `.swift`
5. **IMPORTANTE:** Marque a opção "Copy items if needed"
6. Em "Add to targets", marque apenas `GranaStreamAppTests`
7. Clique em "Add"

### 3. Adicionar Protocolo ao App Principal

O arquivo `APIClientProtocol.swift` deve estar no target principal:
1. Selecione o arquivo no Project Navigator
2. No File Inspector (painel direito), em "Target Membership"
3. Marque `GranaStreamApp` (app principal)
4. **NÃO** marque `GranaStreamAppTests`

### 4. Configurar Test Plan (Opcional)

Para organizar melhor os testes:
1. Product → Scheme → Edit Scheme
2. Selecione "Test" no painel esquerdo
3. Clique no "+" e adicione test plans por feature

## Estrutura de Testes

### Mocks

- **MockAPIClient**: Implementação fake do `APIClientProtocol` para testes
  - Permite configurar respostas simuladas (`mockResponse`)
  - Permite simular erros (`mockError`)
  - Rastreia chamadas de API (`requestCallCount`, `requestHistory`)
  - Suporta delay simulado (`requestDelay`)

### ViewModels Testados

#### TransactionsViewModelTests
- ✅ Inicialização
- ✅ Load (sucesso e falha)
- ✅ LoadMore (paginação)
- ✅ Delete
- ✅ Filtros
- ✅ Cálculos (income, expense, balance)

#### AccountsViewModelTests
- ✅ Inicialização
- ✅ Load
- ✅ Create (incluindo conta inativa)
- ✅ Update
- ✅ Delete
- ✅ Reactivate
- ✅ Search (case-insensitive)

#### CategoriesViewModelTests
- ✅ Inicialização
- ✅ Load
- ✅ Create
- ✅ Update
- ✅ Delete
- ✅ Seed
- ✅ Search (com hierarquia parent/child)

## Executando os Testes

### Via Xcode

1. **Executar todos os testes:**
   - `Cmd + U`

2. **Executar testes de uma classe:**
   - Clique no diamante ao lado do nome da classe
   - Ou: Product → Test (com o arquivo aberto)

3. **Executar um teste específico:**
   - Clique no diamante ao lado do método de teste

4. **Ver resultados:**
   - Abra o Test Navigator (`Cmd + 6`)
   - Veja logs detalhados no Report Navigator (`Cmd + 9`)

### Via Terminal

```bash
# Todos os testes
xcodebuild test -scheme GranaStreamApp -destination 'platform=iOS Simulator,name=iPhone 15'

# Apenas uma classe de teste
xcodebuild test -scheme GranaStreamApp -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:GranaStreamAppTests/TransactionsViewModelTests

# Teste específico
xcodebuild test -scheme GranaStreamApp -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:GranaStreamAppTests/TransactionsViewModelTests/testLoad_Success_UpdatesTransactions
```

## Cobertura de Código

### Habilitar Code Coverage

1. Product → Scheme → Edit Scheme
2. Selecione "Test" no painel esquerdo
3. Tab "Options"
4. Marque "Gather coverage for all targets"
5. Clique em "Close"

### Ver Relatório de Cobertura

1. Execute os testes (`Cmd + U`)
2. Abra Report Navigator (`Cmd + 9`)
3. Selecione o último test run
4. Clique na tab "Coverage"

**Meta de Cobertura:** 80%+ nos ViewModels principais

## Padrões de Teste

### Estrutura Given-When-Then

```swift
func testExemplo() async {
    // Given - Preparação
    mockAPIClient.mockResponse = mockData
    
    // When - Ação
    await sut.load()
    
    // Then - Verificação
    XCTAssertEqual(sut.items.count, 2)
}
```

### Nomenclatura

Padrão: `test[FunctionName]_[Scenario]_[ExpectedBehavior]`

Exemplos:
- `testLoad_Success_UpdatesTransactions`
- `testCreate_Failure_ReturnsFalse`
- `testDelete_Success_RemovesAccount`

### Setup e Teardown

```swift
override func setUp() async throws {
    mockAPIClient = MockAPIClient()
    sut = MyViewModel(apiClient: mockAPIClient)
}

override func tearDown() async throws {
    sut = nil
    mockAPIClient = nil
}
```

## Próximos Passos

### Testes Pendentes

- [ ] **SessionStore** - login, logout, refresh tokens
- [ ] **ReferenceDataStore** - refresh, upsert, remove
- [ ] **PayablesViewModel** - load, settle, undo
- [ ] **RecurrencesViewModel** - CRUD operations
- [ ] **InstallmentSeriesViewModel** - CRUD operations

### Melhorias Futuras

1. **Snapshot Testing**: Testar componentes visuais
2. **UI Tests**: Testes end-to-end
3. **Performance Tests**: `measure { }` para operações críticas
4. **Test Doubles**: Mocks para SessionStore e ReferenceDataStore
5. **CI/CD**: Executar testes automaticamente no GitHub Actions

## Troubleshooting

### "No such module 'GranaStreamApp'"

**Solução:** Verifique se o target de testes tem o app principal como dependência:
1. Selecione o projeto no Project Navigator
2. Selecione o target `GranaStreamAppTests`
3. Tab "Build Phases"
4. Em "Dependencies", adicione `GranaStreamApp`

### "Type 'MockAPIClient' cannot conform to 'APIClientProtocol'"

**Solução:** Adicione `@testable import GranaStreamApp` no topo do arquivo de teste.

### Testes lentos

**Solução:** Use `mockAPIClient.requestDelay = 0` (padrão) para evitar delays desnecessários.

### "Cannot find 'TransactionSummaryDto' in scope"

**Solução:** Certifique-se que o `@testable import GranaStreamApp` está presente e que o projeto compila sem erros.

## Recursos

- [Swift Testing Best Practices](https://developer.apple.com/documentation/xctest)
- [Testing Async Code](https://developer.apple.com/documentation/xctest/asynchronous_tests_and_expectations)
- [Code Coverage](https://developer.apple.com/documentation/xcode/code-coverage)
