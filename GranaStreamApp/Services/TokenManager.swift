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
        
        keychain.set(accessToken, for: accessTokenKey)
        keychain.set(refreshToken, for: refreshTokenKey)
        keychain.set(DateCoder.string(from: expiry), for: expiresAtKey)
    }
    
    func clear() {
        accessToken = nil
        refreshToken = nil
        expiresAt = nil
        
        keychain.delete(accessTokenKey)
        keychain.delete(refreshTokenKey)
        keychain.delete(expiresAtKey)
    }
    
    private func loadFromKeychain() {
        accessToken = keychain.get(accessTokenKey)
        refreshToken = keychain.get(refreshTokenKey)
        
        if let expiresAtString = keychain.get(expiresAtKey) {
            expiresAt = DateCoder.formatterWithFraction.date(from: expiresAtString)
                ?? DateCoder.formatterNoFraction.date(from: expiresAtString)
        }
    }
}
