import Foundation

extension Error {
    var userMessage: String? {
        if let apiError = self as? APIError {
            switch apiError {
            case .requestCancelled:
                return nil
            default:
                return apiError.errorDescription
            }
        }
        return localizedDescription
    }
}
