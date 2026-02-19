import Foundation

/// Localização centralizada - Substitui hardcoded strings por NSLocalizedString
enum L10n {
    enum Common {
        static let save = NSLocalizedString("common.save", value: "Salvar", comment: "Botão salvar")
        static let cancel = NSLocalizedString("common.cancel", value: "Cancelar", comment: "Botão cancelar")
        static let delete = NSLocalizedString("common.delete", value: "Excluir", comment: "Botão excluir")
        static let edit = NSLocalizedString("common.edit", value: "Editar", comment: "Botão editar")
        static let loading = NSLocalizedString("common.loading", value: "Carregando...", comment: "Indicador de carregamento")
        static let ok = NSLocalizedString("common.ok", value: "OK", comment: "Botão OK")
        static let close = NSLocalizedString("common.close", value: "Fechar", comment: "Botão fechar")
    }

    enum Transactions {
        static let title = NSLocalizedString("transactions.title", value: "Transações", comment: "Título da tela")
        static let empty = NSLocalizedString("transactions.empty", value: "Sem transações neste período.", comment: "Mensagem quando não há transações")
        static let loading = NSLocalizedString("transactions.loading", value: "Carregando lançamentos...", comment: "Mensagem de carregamento")
        static let add = NSLocalizedString("transactions.add", value: "Adicionar transação", comment: "Botão adicionar")
        static let edit = NSLocalizedString("transactions.edit", value: "Editar lançamento", comment: "Menu editar")
        static let deleteConfirm = NSLocalizedString("transactions.delete.confirm", value: "Excluir lançamento?", comment: "Título do alerta")
        static let saving = NSLocalizedString("transactions.saving", value: "Salvando...", comment: "Estado de salvamento")
        static let filters = NSLocalizedString("transactions.filters", value: "Filtros", comment: "Botão filtros")
        
        static func deleteConfirmMessage(_ name: String) -> String {
            let format = NSLocalizedString("transactions.delete.confirm.message", value: "Você realmente quer excluir \"%@\"?", comment: "Mensagem com nome da transação")
            return String(format: format, name)
        }
        
        static let deleteDefault = NSLocalizedString("transactions.delete.default", value: "Você realmente quer excluir este lançamento?", comment: "Mensagem padrão")
        
        enum Summary {
            static let income = NSLocalizedString("transactions.summary.income", value: "Receita", comment: "Receita")
            static let expense = NSLocalizedString("transactions.summary.expense", value: "Despesa", comment: "Despesa")
            static let total = NSLocalizedString("transactions.summary.total", value: "Total", comment: "Total")
        }
    }

    enum Accounts {
        static let title = NSLocalizedString("accounts.title", value: "Contas", comment: "Título da tela")
        static let empty = NSLocalizedString("accounts.empty", value: "Nenhuma conta registrada.", comment: "Mensagem vazia")
        static let add = NSLocalizedString("accounts.add", value: "Adicionar conta", comment: "Botão adicionar")
        static let edit = NSLocalizedString("accounts.edit", value: "Editar conta", comment: "Menu editar")
        static let deleteConfirm = NSLocalizedString("accounts.delete.confirm", value: "Excluir conta?", comment: "Alerta de exclusão")
        static let loading = NSLocalizedString("accounts.loading", value: "Carregando contas...", comment: "Carregamento")
        static let new = NSLocalizedString("accounts.new", value: "Nova conta", comment: "Nova conta")

        enum Detail {
            static let title = NSLocalizedString("accounts.detail.title", value: "Detalhes da conta", comment: "Título da tela de detalhe")
            static let currentBalance = NSLocalizedString("accounts.detail.current.balance", value: "Saldo atual", comment: "Label saldo atual")
            static let adjust = NSLocalizedString("accounts.detail.adjust", value: "Reajustar", comment: "Botão reajustar saldo")
            static let accountInfo = NSLocalizedString("accounts.detail.account.info", value: "Informações da conta", comment: "Título seção")
            static let accountType = NSLocalizedString("accounts.detail.account.type", value: "Tipo da conta", comment: "Label tipo")
            static let initialBalance = NSLocalizedString("accounts.detail.initial.balance", value: "Saldo inicial", comment: "Label saldo inicial")
            static let monthlyOverview = NSLocalizedString("accounts.detail.monthly.overview", value: "Resumo do mês", comment: "Título seção resumo do mês")
            static let incomeCount = NSLocalizedString("accounts.detail.income.count", value: "Receitas", comment: "Quantidade de receitas")
            static let expenseCount = NSLocalizedString("accounts.detail.expense.count", value: "Despesas", comment: "Quantidade de despesas")
            static let transferCount = NSLocalizedString("accounts.detail.transfer.count", value: "Transferências", comment: "Quantidade de transferências")
            static let transactionsTitle = NSLocalizedString("accounts.detail.transactions.title", value: "Transações recentes", comment: "Título seção transações")
            static let transactionsEmpty = NSLocalizedString("accounts.detail.transactions.empty", value: "Sem transações neste mês.", comment: "Lista vazia")
            static let loading = NSLocalizedString("accounts.detail.loading", value: "Carregando detalhes da conta...", comment: "Carregando detalhe")
            static let errorDefault = NSLocalizedString("accounts.detail.error.default", value: "Não foi possível carregar os detalhes da conta.", comment: "Erro padrão detalhe")
            static let adjustSheetTitle = NSLocalizedString("accounts.detail.adjust.sheet.title", value: "Reajustar saldo", comment: "Título modal reajuste")
            static let adjustAmount = NSLocalizedString("accounts.detail.adjust.amount", value: "Valor do ajuste", comment: "Campo valor reajuste")
            static let adjustHint = NSLocalizedString("accounts.detail.adjust.hint", value: "A integração do reajuste estará disponível em breve.", comment: "Aviso integração futura")
            static let adjustConfirm = NSLocalizedString("accounts.detail.adjust.confirm", value: "Confirmar", comment: "Botão confirmar reajuste")
        }
    }

    enum Categories {
        static let title = NSLocalizedString("categories.title", value: "Categorias", comment: "Título da tela")
        static let empty = NSLocalizedString("categories.empty", value: "Nenhuma categoria registrada.", comment: "Mensagem vazia")
        static let add = NSLocalizedString("categories.add", value: "Adicionar categoria", comment: "Botão adicionar")
        static let edit = NSLocalizedString("categories.edit", value: "Editar categoria", comment: "Menu editar")
        static let deleteConfirm = NSLocalizedString("categories.delete.confirm", value: "Excluir categoria?", comment: "Alerta de exclusão")
        static let loading = NSLocalizedString("categories.loading", value: "Carregando categorias...", comment: "Carregamento")
        static let seed = NSLocalizedString("categories.seed", value: "Categorias padrão", comment: "Botão semear")
        
        enum CategoryType {
            static let income = NSLocalizedString("categories.income", value: "Receita", comment: "Tipo receita")
            static let expense = NSLocalizedString("categories.expense", value: "Despesa", comment: "Tipo despesa")
        }
    }

    enum Payables {
        static let title = NSLocalizedString("payables.title", value: "Pendências", comment: "Título da tela")
        static let empty = NSLocalizedString("payables.empty", value: "Nenhuma pendência.", comment: "Mensagem vazia")
        static let loading = NSLocalizedString("payables.loading", value: "Carregando pendências...", comment: "Carregamento")
        static let pending = NSLocalizedString("payables.pending", value: "Pendente", comment: "Status pendente")
        static let settled = NSLocalizedString("payables.settled", value: "Quitado", comment: "Status quitado")
        static let payable = NSLocalizedString("payables.payable", value: "Pagar", comment: "Tipo pagar")
        static let receivable = NSLocalizedString("payables.receivable", value: "Receber", comment: "Tipo receber")
        static let settle = NSLocalizedString("payables.settle", value: "Quitar", comment: "Ação quitar")
        static let settleConfirm = NSLocalizedString("payables.settle.confirm", value: "Quitar pendência?", comment: "Alerta de confirmação")
    }

    enum Recurrences {
        static let title = NSLocalizedString("recurrences.title", value: "Recorrências", comment: "Título da tela")
        static let empty = NSLocalizedString("recurrences.empty", value: "Nenhuma recorrência registrada.", comment: "Mensagem vazia")
        static let add = NSLocalizedString("recurrences.add", value: "Adicionar recorrência", comment: "Botão adicionar")
        static let edit = NSLocalizedString("recurrences.edit", value: "Editar recorrência", comment: "Menu editar")
        static let deleteConfirm = NSLocalizedString("recurrences.delete.confirm", value: "Excluir recorrência?", comment: "Alerta")
        static let loading = NSLocalizedString("recurrences.loading", value: "Carregando recorrências...", comment: "Carregamento")
    }

    enum Installments {
        static let title = NSLocalizedString("installments.title", value: "Parceladas", comment: "Título da tela")
        static let empty = NSLocalizedString("installments.empty", value: "Nenhuma série de parcelas registrada.", comment: "Mensagem vazia")
        static let add = NSLocalizedString("installments.add", value: "Adicionar série", comment: "Botão adicionar")
        static let edit = NSLocalizedString("installments.edit", value: "Editar série", comment: "Menu editar")
        static let deleteConfirm = NSLocalizedString("installments.delete.confirm", value: "Excluir série?", comment: "Alerta")
        static let loading = NSLocalizedString("installments.loading", value: "Carregando séries...", comment: "Carregamento")
    }

    enum Budget {
        static let title = NSLocalizedString("budget.title", value: "Orçamento", comment: "Título")
        static let month = NSLocalizedString("budget.month", value: "Mês", comment: "Rótulo mês")
        static let save = NSLocalizedString("budget.save", value: "Salvar orçamento", comment: "Botão salvar")
        static let saving = NSLocalizedString("budget.saving", value: "Salvando orçamento...", comment: "Estado")
        static let copyPrevious = NSLocalizedString("budget.copy.previous", value: "Copiar mês anterior", comment: "Botão copiar")
        static let comingSoon = NSLocalizedString("budget.coming.soon", value: "Em breve", comment: "Status")
        static let success = NSLocalizedString("budget.success", value: "Orçamento", comment: "Alerta título")
        static let notFound = NSLocalizedString("budget.not.found", value: "Orçamento não encontrado para esse usuário", comment: "Erro")
    }

    enum Home {
        static let title = NSLocalizedString("home.title", value: "Home", comment: "Título da home")
        static let welcome = NSLocalizedString("home.welcome", value: "Olá", comment: "Saudação")
        static let overview = NSLocalizedString("home.overview", value: "Acompanhe suas finanças", comment: "Subtítulo da home")
        static let accountsTitle = NSLocalizedString("home.accounts.title", value: "Contas", comment: "Título seção de contas")
        static let totalBalance = NSLocalizedString("home.total.balance", value: "Saldo total", comment: "Saldo total")
        static let totalExpense = NSLocalizedString("home.total.expense", value: "Despesa total", comment: "Despesa total")
        static let budgetUsage = NSLocalizedString("home.budget.usage", value: "Uso do orçamento", comment: "Título de uso do orçamento")
        static let chartTitle = NSLocalizedString("home.chart.title", value: "Evolução do período", comment: "Título do gráfico")
        static let chartEmpty = NSLocalizedString("home.chart.empty", value: "Sem dados para mostrar no gráfico.", comment: "Gráfico vazio")
        static let recentTitle = NSLocalizedString("home.recent.title", value: "Lançamentos recentes", comment: "Título da lista recente")
        static let recentEmpty = NSLocalizedString("home.recent.empty", value: "Sem lançamentos recentes neste período.", comment: "Lista vazia")
        static let loading = NSLocalizedString("home.loading", value: "Carregando sua home...", comment: "Estado de carregamento")
        static let retry = NSLocalizedString("home.retry", value: "Tentar novamente", comment: "Ação de tentar novamente")
        static let errorDefault = NSLocalizedString("home.error.default", value: "Não foi possível carregar a home.", comment: "Erro padrão")

        enum Period {
            static let daily = NSLocalizedString("home.period.daily", value: "Diário", comment: "Período diário")
            static let weekly = NSLocalizedString("home.period.weekly", value: "Semanal", comment: "Período semanal")
            static let monthly = NSLocalizedString("home.period.monthly", value: "Mensal", comment: "Período mensal")
            static let yearly = NSLocalizedString("home.period.yearly", value: "Anual", comment: "Período anual")
        }
    }

    enum Settings {
        static let title = NSLocalizedString("settings.title", value: "Configurações", comment: "Título da tela")
        static let profile = NSLocalizedString("settings.profile", value: "Perfil", comment: "Menu perfil")
        static let password = NSLocalizedString("settings.password", value: "Alterar senha", comment: "Menu senha")
        static let logout = NSLocalizedString("settings.logout", value: "Sair", comment: "Botão logout")
        static let logoutConfirm = NSLocalizedString("settings.logout.confirm", value: "Tem certeza?", comment: "Alerta título")
        static let logoutMessage = NSLocalizedString("settings.logout.message", value: "Você será desconectado da sua conta.", comment: "Alerta mensagem")
        
        enum Security {
            static let title = NSLocalizedString("settings.security", value: "Segurança", comment: "Seção")
            static let biometric = NSLocalizedString("settings.biometric", value: "Biometria", comment: "Opção")
            static let appLock = NSLocalizedString("settings.app.lock", value: "Bloqueio de app", comment: "Opção")
        }
    }

    enum Alerts {
        static let success = NSLocalizedString("alert.success", value: "Sucesso!", comment: "Título")
        static let error = NSLocalizedString("alert.error", value: "Erro", comment: "Título")
        static let warning = NSLocalizedString("alert.warning", value: "Aviso", comment: "Título")
        static let info = NSLocalizedString("alert.info", value: "Informação", comment: "Título")
        static let deleteSuccess = NSLocalizedString("alert.delete.success", value: "Excluído com sucesso", comment: "Mensagem")
        static let saveSuccess = NSLocalizedString("alert.save.success", value: "Salvo com sucesso", comment: "Mensagem")
        static let updateSuccess = NSLocalizedString("alert.update.success", value: "Atualizado com sucesso", comment: "Mensagem")
    }

    enum Validation {
        static let required = NSLocalizedString("validation.required", value: "Campo obrigatório", comment: "Erro validação")
        static let invalidEmail = NSLocalizedString("validation.invalid.email", value: "Email inválido", comment: "Erro validação")
        static let invalidAmount = NSLocalizedString("validation.invalid.amount", value: "Valor inválido", comment: "Erro validação")
        static let passwordsMismatch = NSLocalizedString("validation.passwords.mismatch", value: "As senhas não coincidem", comment: "Erro validação")
        static let weakPassword = NSLocalizedString("validation.weak.password", value: "Senha fraca", comment: "Erro validação")
    }

    enum Navigation {
        static let back = NSLocalizedString("nav.back", value: "Voltar", comment: "Botão")
        static let next = NSLocalizedString("nav.next", value: "Próximo", comment: "Botão")
        static let previous = NSLocalizedString("nav.previous", value: "Anterior", comment: "Botão")
        static let skip = NSLocalizedString("nav.skip", value: "Pular", comment: "Botão")
        static let done = NSLocalizedString("nav.done", value: "Concluído", comment: "Botão")
    }
}
