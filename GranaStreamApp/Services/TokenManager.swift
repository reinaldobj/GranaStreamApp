import Foundation

/// Gerencia tokens de autenticação (access, refresh, expiry)
@MainActor
final class TokenManager {
    private let keychain = KeychainService()
    private let accessTokenKey = "gs_access_token"
    private let refreshTokenKey = "gs_refresh_token"
    private let expiresAtKey = "gs_expires_at"
    private let refreshLeeway: TimeInterval = 60
    
    private(set) var accessToken: String?
    private(set) var refreshToken: String?
    private(set) var expiresAt: Date?
    
    init() {
        loadFromKeychain()
    }
    
    var hasValidToken: Bool {
        accessToken != nil
    }
    
    func isTokenExpiringSoon(now: Date = Date()) -> Bool {
        guard let expiresAt else { return true }
        return now >= expiresAt.addingTimeInterval(-refreshLeeway)
    }
    
    func store(accessToken: String, refreshToken: String, expiresIn: Int) {
        let expiry = Date().addingTimeInterval(TimeInterval(expiresIn))
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiry
        
        do {
            try keychain.set(accessToken, for: accessTokenKey)
            try keychain.set(refreshToken, for: refreshTokenKey)
            try keychain.set(DateCoder.string(from: expiry), for: expiresAtKey)
        } catch {
            // Log erro mas não falha - tokens estão em memória
            print("⚠️ Falha ao armazenar tokens no Keychain: \(error)")
        }
    }
    
    func clear() {
        accessToken = nil
        refreshToken = nil
        expiresAt = nil
        
        do {
            try keychain.delete(accessTokenKey)
            try keychain.delete(refreshTokenKey)
            try keychain.delete(expiresAtKey)
        } catch {
            // Log erro mas continua - tokens foram limpos em memória
            print("⚠️ Falha ao deletar tokens do Keychain: \(error)")
        }
    }
    
    private func loadFromKeychain() {
        do {
            accessToken = try keychain.get(accessTokenKey)
            refreshToken = try keychain.get(refreshTokenKey)

            if let expiresAtString = try keychain.get(expiresAtKey) {
                expiresAt = DateCoder.parseDate(expiresAtString)
            }
        } catch {
            // Log erro mas continua - pode ser primeiro acesso
            print("ℹ️ Nenhum token armazenado no Keychain ou erro na recuperação: \(error)")
        }
    }
}
