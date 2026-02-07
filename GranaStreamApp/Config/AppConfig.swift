import Foundation

enum AppEnvironment: String {
    case dev
    case hml
    case prod

    static var current: AppEnvironment {
        if let rawValue = Bundle.main.object(forInfoDictionaryKey: "APP_ENV") as? String,
           let environment = AppEnvironment(rawValue: rawValue.lowercased()) {
            return environment
        }

        #if DEBUG
        return .dev
        #else
        return .prod
        #endif
    }
}

enum AppConfig {
    static var baseURL: URL {
        if let value = baseURLString(for: AppEnvironment.current), let url = URL(string: value) {
            return url
        }
        return fallbackBaseURL
    }

    static let keychainService = "GranaStreamApp"

    private static let fallbackBaseURL = URL(
        string: "https://granastreamappcontainer.purplehill-6384ee00.brazilsouth.azurecontainerapps.io"
    )!

    private static func baseURLString(for environment: AppEnvironment) -> String? {
        let key: String
        switch environment {
        case .dev:
            key = "BASE_URL_DEV"
        case .hml:
            key = "BASE_URL_HML"
        case .prod:
            key = "BASE_URL_PROD"
        }

        return Bundle.main.object(forInfoDictionaryKey: key) as? String
    }
}
