import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfileResponseDto?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await SessionStore.shared.loadProfile()
            profile = SessionStore.shared.profile
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func update(name: String, email: String? = nil) async -> Bool {
        do {
            try await SessionStore.shared.updateProfile(name: name, email: email)
            profile = SessionStore.shared.profile
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
