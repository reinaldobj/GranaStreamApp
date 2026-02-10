import Foundation

extension Error {
    var isCancellation: Bool {
        if self is CancellationError {
            return true
        }

        if let apiError = self as? APIError {
            if case .requestCancelled = apiError {
                return true
            }
        }

        if let urlError = self as? URLError, urlError.code == .cancelled {
            return true
        }

        return false
    }

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
