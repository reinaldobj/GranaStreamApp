import Foundation

struct UserProfileResponseDto: Codable {
    let id: String
    let name: String?
    let email: String?
    let status: UserStatus
}

struct UpdateUserRequestDto: Codable {
    let name: String?
    let email: String?
}
