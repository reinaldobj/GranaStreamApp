import Foundation

struct AuthenticatedUserDto: Codable {
    let id: String
    let name: String?
    let email: String?
}

struct LoginRequestDto: Codable {
    let email: String
    let password: String
}

struct LoginResponseDto: Codable {
    let accessToken: String?
    let refreshToken: String?
    let expiresIn: Int
    let user: AuthenticatedUserDto
}

struct SignupRequestDto: Codable {
    let name: String
    let email: String
    let password: String
}

struct SignupResponseDto: Codable {
    let id: String
    let name: String?
    let email: String?
}

struct RefreshTokenRequestDto: Codable {
    let refreshToken: String
}

struct LogoutRequestDto: Codable {
    let refreshToken: String
}

struct ChangePasswordRequestDto: Codable {
    let currentPassword: String
    let newPassword: String
}
