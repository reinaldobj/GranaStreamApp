import Foundation

/// Protocolo para ViewModels que suportam busca/filtro local
protocol SearchableViewModel: ObservableObject {
    /// Termo de busca ativo
    var activeSearchTerm: String { get }
    
    /// Aplica um termo de busca nos dados
    func applySearch(term: String)
}

// MARK: - Helpers

/// Utilitários para normalização de strings em buscas
enum SearchHelper {
    /// Normaliza string para comparação (remove acentos, lowercase)
    static func normalized(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "pt_BR"))
            .lowercased()
    }
    
    /// Verifica se o valor contém o termo de busca (normalizado)
    static func matches(_ value: String, searchTerm: String) -> Bool {
        let normalizedValue = normalized(value)
        let normalizedTerm = normalized(searchTerm)
        return normalizedValue.contains(normalizedTerm)
    }
    
    /// Limpa e normaliza o termo de busca
    static func cleanSearchTerm(_ term: String) -> String {
        term.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
