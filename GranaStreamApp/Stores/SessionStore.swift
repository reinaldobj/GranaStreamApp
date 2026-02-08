import Foundation
import SwiftUI
import Combine

/// Gerencia autenticação e perfil do usuário
/// Implementa SessionManager protocol para permitir injeção de dependência
@MainActor
final class SessionStore: NSObject, SessionManager, ObservableObject {
    static let shared = SessionStore()

    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentUser: AuthenticatedUserDto?
    @Published private(set) var profile: UserProfileResponseDto?

    private let keychain = KeychainService()
    private let accessTokenKey = "gs_access_token"
    private let refreshTokenKey = "gs_refresh_token"
    private let expiresAtKey = "gs_expires_at"
    private let refreshLeeway: TimeInterval = 60

    private var accessToken: String?
    private var refreshToken: String?
    private var expiresAt: Date?
    private var refreshTask: Task<Bool, Never>?

    override init() {
        super.init()
        loadFromKeychain()
        isAuthenticated = accessToken != nil
        if refreshToken != nil && (accessToken == nil || isTokenExpiringSoon()) {
            Task { _ = await refreshTokens() }
        }
    }

    func getAccessToken() -> String? {
        accessToken
    }

    func refreshTokensIfNeeded() async -> Bool {
        if accessToken == nil || isTokenExpiringSoon() {
            guard refreshToken != nil else {
                clearTokens()
                return false
            }
            return await refreshTokens()
        }
        return true
    }

    func login(email: String, password: String) async throws {
        let request = LoginRequestDto(email: email, password: password)
        let response: LoginResponseDto = try await APIClient.shared.request(
            "/api/v1/Auth/login",
            method: "POST",
            body: AnyEncodable(request),
            requiresAuth: false
        )
        try storeTokens(from: response)
        currentUser = response.user
        isAuthenticated = true
    }

    func signup(name: String, email: String, password: String) async throws {
        let request = SignupRequestDto(name: name, email: email, password: password)
        let _: SignupResponseDto = try await APIClient.shared.request(
            "/api/v1/Auth/register",
            method: "POST",
            body: AnyEncodable(request),
            requiresAuth: false
        )
        try await login(email: email, password: password)
    }

    func logout() async {
        guard let refreshToken else {
            clearTokens()
            return
        }
        let request = LogoutRequestDto(refreshToken: refreshToken)
        try? await APIClient.shared.requestNoResponse(
            "/api/v1/Auth/logout",
            method: "POST",
            body: AnyEncodable(request)
        )
        clearTokens()
    }

    func logoutLocal() {
        clearTokens()
    }

    func refreshTokens() async -> Bool {
        if let refreshTask {
            return await refreshTask.value
        }
        guard let refreshToken else {
            clearTokens()
            return false
        }
        let task = Task<Bool, Never> {
            do {
                let request = RefreshTokenRequestDto(refreshToken: refreshToken)
                let response: LoginResponseDto = try await APIClient.shared.request(
                    "/api/v1/Auth/refresh",
                    method: "POST",
                    body: AnyEncodable(request),
                    requiresAuth: false,
                    retryOnAuthFailure: false
                )
                try storeTokens(from: response)
                currentUser = response.user
                isAuthenticated = true
                return true
            } catch {
                clearTokens()
                return false
            }
        }
        refreshTask = task
        let result = await task.value
        refreshTask = nil
        return result
    }

    func loadProfile() async throws {
        let profile: UserProfileResponseDto = try await APIClient.shared.request("/api/v1/users/me")
        self.profile = profile
        if let currentUser = currentUser {
            self.currentUser = AuthenticatedUserDto(
                id: currentUser.id,
                name: profile.name ?? currentUser.name,
                email: profile.email ?? currentUser.email
            )
        } else {
            self.currentUser = AuthenticatedUserDto(
                id: profile.id,
                name: profile.name,
                email: profile.email
            )
        }
    }

    func updateProfile(name: String, email: String? = nil) async throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let request = UpdateUserRequestDto(
            name: trimmedName.isEmpty ? nil : trimmedName,
            email: email
        )
        let profile: UserProfileResponseDto = try await APIClient.shared.request(
            "/api/v1/users/me",
            method: "PATCH",
            body: AnyEncodable(request)
        )
        self.profile = profile
        if let currentUser = currentUser {
            self.currentUser = AuthenticatedUserDto(
                id: currentUser.id,
                name: profile.name ?? currentUser.name,
                email: profile.email ?? currentUser.email
            )
        } else {
            self.currentUser = AuthenticatedUserDto(
                id: profile.id,
                name: profile.name,
                email: profile.email
            )
        }
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {
        let request = ChangePasswordRequestDto(
            currentPassword: currentPassword,
            newPassword: newPassword
        )
        try await APIClient.shared.requestNoResponse(
            "/api/v1/users/me/password",
            method: "PATCH",
            body: AnyEncodable(request)
        )
    }

    private func storeTokens(from response: LoginResponseDto) throws {
        guard let accessToken = response.accessToken, let refreshToken = response.refreshToken else {
            throw APIError.decodingError
        }
        let expiry = Date().addingTimeInterval(TimeInterval(response.expiresIn))
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiry
        
        do {
            try keychain.set(accessToken, for: accessTokenKey)
            try keychain.set(refreshToken, for: refreshTokenKey)
            try keychain.set(DateCoder.string(from: expiry), for: expiresAtKey)
        } catch {
            // Log erro mas não falha - tokens ainda estão em memória
            print("⚠️ Falha ao armazenar tokens no Keychain: \(error)")
        }
    }

    private func isTokenExpiringSoon(now: Date = .init()) -> Bool {
        guard let expiresAt else { return true }
        return now >= expiresAt.addingTimeInterval(-refreshLeeway)
    }

    private func loadFromKeychain() {
        do {
            accessToken = try keychain.get(accessTokenKey)
            refreshToken = try keychain.get(refreshTokenKey)
            if let expiresAtString = try keychain.get(expiresAtKey),
               let date = DateCoder.formatterWithFraction.date(from: expiresAtString) ?? DateCoder.formatterNoFraction.date(from: expiresAtString) {
                expiresAt = date
            }
        } catch {
            // Log erro mas continua - pode ser primeiro acesso
            print("ℹ️ Nenhum token armazenado no Keychain ou erro na recuperação: \(error)")
        }
    }

    private func clearTokens() {
        accessToken = nil
        refreshToken = nil
        expiresAt = nil
        currentUser = nil
        profile = nil
        isAuthenticated = false
        
        do {
            try keychain.delete(accessTokenKey)
            try keychain.delete(refreshTokenKey)
            try keychain.delete(expiresAtKey)
        } catch {
            // Log erro mas continua com logout - tokens foram limpos em memória
            print("⚠️ Falha ao deletar tokens do Keychain durante logout: \(error)")
        }
        
        AppLockService.shared.resetForLogout()
    }
}
