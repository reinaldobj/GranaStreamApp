import Foundation

/// Protocolo para gerenciamento de sessão e autenticação
/// Permite injeção de dependência e facilita testes
protocol SessionManager: AnyObject {
    // MARK: - State
    
    /// Indica se o usuário está autenticado
    var isAuthenticated: Bool { get }
    
    /// Usuário autenticado atual
    var currentUser: AuthenticatedUserDto? { get }
    
    /// Perfil do usuário autenticado
    var profile: UserProfileResponseDto? { get }
    
    // MARK: - Authentication
    
    /// Realiza login com email e senha
    /// - Parameters:
    ///   - email: Email do usuário
    ///   - password: Senha do usuário
    /// - Throws: APIError se falhar
    func login(email: String, password: String) async throws
    
    /// Realiza signup (registro) do usuário
    /// - Parameters:
    ///   - name: Nome completo
    ///   - email: Email do usuário
    ///   - password: Senha desejada
    /// - Throws: APIError se falhar
    func signup(name: String, email: String, password: String) async throws
    
    /// Realiza logout do usuário (chamada API + limpeza local)
    func logout() async
    
    /// Realiza logout local sem chamar API
    func logoutLocal()
    
    // MARK: - Token Management
    
    /// Obtém o token de acesso atual
    /// - Returns: Token de acesso ou nil se não autenticado
    func getAccessToken() -> String?
    
    /// Atualiza tokens se necessário (expiração)
    /// - Returns: true se tokens válidos, false se falhou
    func refreshTokensIfNeeded() async -> Bool
    
    // MARK: - User Profile
    
    /// Carrega o perfil completo do usuário
    /// - Throws: APIError se falhar
    func loadProfile() async throws
    
    /// Atualiza o perfil do usuário
    /// - Parameters:
    ///   - name: Novo nome (opcional)
    ///   - email: Novo email (opcional)
    /// - Throws: APIError se falhar
    func updateProfile(name: String, email: String?) async throws
    
    /// Altera a senha do usuário
    /// - Parameters:
    ///   - currentPassword: Senha atual
    ///   - newPassword: Nova senha
    /// - Throws: APIError se falhar
    func changePassword(currentPassword: String, newPassword: String) async throws
}

// MARK: - Default Implementation Extension

extension SessionManager {
    /// Atualiza perfil com apenas o nome
    func updateProfile(name: String) async throws {
        try await updateProfile(name: name, email: nil)
    }
}
