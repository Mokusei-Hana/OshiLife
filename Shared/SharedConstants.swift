import Foundation

enum SharedConstants {
    static var appGroupIdentifier: String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String,
              !value.isEmpty,
              !value.contains("$(") else {
            return "group.com.example.OshiLife"
        }
        return value
    }

    static var importScheme: String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "ImportURLScheme") as? String,
              !value.isEmpty,
              !value.contains("$(") else {
            return "oshilife"
        }
        return value
    }
    static let pendingDirectory = "Incoming"
    static let imagesDirectory = "Images"
    static let databaseName = "OshiLife"
}

enum SharedContainerError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        String(localized: "error.shared_container")
    }
}

extension FileManager {
    func oshiLifeSharedContainerURL() throws -> URL {
        guard let url = containerURL(
            forSecurityApplicationGroupIdentifier: SharedConstants.appGroupIdentifier
        ) else {
            throw SharedContainerError.unavailable
        }
        return url
    }
}
