import Foundation

/// Estados genéricos para gerenciar loading em qualquer tipo de dados
enum LoadingState<T> {
    /// Estado inicial - sem requisição iniciada
    case idle
    
    /// Carregando dados (mantendo opcionalmente o que já estava na tela)
    case loading(previousData: T? = nil)
    
    /// Dados carregados com sucesso
    case loaded(T)
    
    /// Erro durante carregamento
    case error(String)
    
    /// Indica se está em estado de carregamento
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }

    /// Indica se está carregando sem dados anteriores
    var isInitialLoading: Bool {
        if case .loading(let previousData) = self {
            return previousData == nil
        }
        return false
    }
    
    /// Indica se tem dados carregados
    var isLoaded: Bool {
        if case .loaded = self {
            return true
        }
        return false
    }
    
    /// Indica se tem erro
    var isError: Bool {
        if case .error = self {
            return true
        }
        return false
    }
    
    /// Extrai dados carregados, se existirem
    var data: T? {
        if case .loaded(let data) = self {
            return data
        }
        if case .loading(let previousData) = self {
            return previousData
        }
        return nil
    }
    
    /// Extrai mensagem de erro, se existir
    var errorMessage: String? {
        if case .error(let message) = self {
            return message
        }
        return nil
    }
}
