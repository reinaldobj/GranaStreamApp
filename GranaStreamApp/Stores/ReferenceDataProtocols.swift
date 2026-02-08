import Foundation

// MARK: - Account Provider

/// Protocolo para acesso aos dados de contas
protocol AccountProvider {
    /// Lista de contas em cache
    var accounts: [AccountResponseDto] { get }
    
    /// Recarrega as contas do servidor
    func refreshAccounts() async
    
    /// Substitui todas as contas
    func replaceAccounts(_ items: [AccountResponseDto])
    
    /// Adiciona ou atualiza uma conta
    func upsertAccount(_ item: AccountResponseDto)
    
    /// Remove uma conta
    func removeAccount(id: String)
}

// MARK: - Category Provider

/// Protocolo para acesso aos dados de categorias
protocol CategoryProvider {
    /// Lista de categorias em cache
    var categories: [CategoryResponseDto] { get }
    
    /// Recarrega as categorias do servidor
    func refreshCategories() async
    
    /// Substitui todas as categorias
    func replaceCategories(_ items: [CategoryResponseDto])
    
    /// Adiciona ou atualiza uma categoria
    func upsertCategory(_ item: CategoryResponseDto)
    
    /// Remove uma categoria
    func removeCategory(id: String)
}

// MARK: - Reference Data Provider

/// Protocolo unificado para dados de referência
protocol ReferenceDataProvider: AccountProvider, CategoryProvider {
    /// Recarrega todos os dados de referência
    func refresh() async
    
    /// Carrega dados se necessário (lazy loading)
    func loadIfNeeded() async
}

// MARK: - Observable Providers (para SwiftUI)

/// Protocolo para providers observáveis (compatível com @EnvironmentObject)
protocol ObservableAccountProvider: AccountProvider, ObservableObject {
    // Herda métodos de AccountProvider
}

/// Protocolo para providers observáveis de categorias
protocol ObservableCategoryProvider: CategoryProvider, ObservableObject {
    // Herda métodos de CategoryProvider
}

/// Protocolo para referência de dados observável
protocol ObservableReferenceDataProvider: ReferenceDataProvider, ObservableObject {
    // Herda métodos de ReferenceDataProvider
}
