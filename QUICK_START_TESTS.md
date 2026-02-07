# ⚡ Quick Start - Testes

## 🎯 Configuração Rápida (5 minutos)

### Passo 1: Criar Target de Testes

1. Abra `GranaStreamApp.xcodeproj` no Xcode
2. **File → New → Target**
3. Selecione **"Unit Testing Bundle"**
4. Configure:
   - Product Name: `GranaStreamAppTests`
   - Target to be Tested: `GranaStreamApp`
5. **Finish**

### Passo 2: Adicionar Arquivos ao Target

**Via Xcode (Recomendado):**

1. No **Project Navigator** (painel esquerdo):
   - Clique com botão direito na pasta raiz do projeto
   - **Add Files to "GranaStreamApp"...**

2. Navegue até a pasta `GranaStreamAppTests` (no Finder)

3. Selecione a pasta inteira `GranaStreamAppTests`

4. **IMPORTANTE - Configure:**
   - ✅ Marque: **"Copy items if needed"**
   - ✅ Marque: **"Create groups"**
   - ✅ Em "Add to targets": marque **APENAS** `GranaStreamAppTests`
   - ❌ NÃO marque `GranaStreamApp`

5. **Add**

### Passo 3: Adicionar APIClientProtocol ao App Principal

1. No Project Navigator, selecione o arquivo:
   ```
   GranaStreamApp/Networking/APIClientProtocol.swift
   ```

2. No **File Inspector** (painel direito, ícone de documento):
   - Em **"Target Membership"**:
   - ✅ Marque `GranaStreamApp` (app principal)
   - ❌ NÃO marque `GranaStreamAppTests`

### Passo 4: Executar Testes

**No Xcode:**
```
Cmd + U
```

**Resultado esperado:**
- ✅ 40 testes passando
- TransactionsViewModelTests: 13/13 ✓
- AccountsViewModelTests: 14/14 ✓
- CategoriesViewModelTests: 13/13 ✓

---

## 🔧 Troubleshooting

### ❌ "No such module 'GranaStreamApp'"

**Causa:** Target de testes não tem dependência do app principal.

**Solução:**
1. Selecione o projeto no Project Navigator
2. Selecione target `GranaStreamAppTests`
3. Tab **"Build Phases"**
4. Em **"Dependencies"**, clique no **+**
5. Adicione `GranaStreamApp`
6. Clean Build Folder (`Cmd + Shift + K`)
7. Build (`Cmd + B`)

### ❌ "Cannot find 'MockAPIClient' in scope"

**Causa:** Arquivos de teste não foram adicionados corretamente ao target.

**Solução:**
1. Selecione `MockAPIClient.swift` no Project Navigator
2. No File Inspector (painel direito):
   - **Target Membership**
   - ✅ Marque `GranaStreamAppTests`
   - ❌ Desmarque `GranaStreamApp` (se estiver marcado)

### ❌ "Type 'APIClient' does not conform to protocol 'APIClientProtocol'"

**Causa:** `APIClientProtocol.swift` não está no target do app principal.

**Solução:**
1. Selecione `APIClientProtocol.swift`
2. File Inspector → Target Membership:
   - ✅ Marque `GranaStreamApp`
   - ❌ Desmarque `GranaStreamAppTests`

### ❌ Testes não aparecem no Test Navigator

**Solução:**
1. Product → Scheme → Manage Schemes
2. Certifique-se que `GranaStreamApp` está selecionado
3. Feche e reabra o Xcode
4. `Cmd + 6` para abrir Test Navigator

---

## 📊 Verificação Pós-Configuração

Execute este checklist:

```
□ Target GranaStreamAppTests criado
□ Pasta GranaStreamAppTests visível no Project Navigator
□ APIClientProtocol.swift em Target Membership: GranaStreamApp ✓
□ MockAPIClient.swift em Target Membership: GranaStreamAppTests ✓
□ Arquivos *Tests.swift em Target Membership: GranaStreamAppTests ✓
□ Build bem-sucedido (Cmd + B)
□ 40 testes executando (Cmd + U)
□ 40 testes passando ✓
```

---

## 🚀 Próximos Passos

1. **Executar os testes:** `Cmd + U`
2. **Ver cobertura de código:**
   - Product → Scheme → Edit Scheme
   - Test → Options → Gather coverage
   - Executar testes
   - Report Navigator (`Cmd + 9`) → Coverage tab

3. **Integrar com CI/CD:** Ver `GranaStreamAppTests/README.md`

---

## 📚 Documentação Completa

- **Guia Detalhado:** `GranaStreamAppTests/README.md`
- **Resumo da Implementação:** `TEST_IMPLEMENTATION_SUMMARY.md`
- **Arquitetura:** `ARCHITECTURE.md`
