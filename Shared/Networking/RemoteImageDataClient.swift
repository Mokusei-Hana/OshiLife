import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

protocol RemoteImageDataFetching: Sendable {
    func fetchImage(from url: URL) async throws -> Data
}

struct RemoteImageDataClient: RemoteImageDataFetching, Sendable {
    static let maximumImageBytes = 25 * 1_024 * 1_024

    private let session: URLSession

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = 12
            configuration.timeoutIntervalForResource = 15
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
            self.session = URLSession(configuration: configuration)
        }
    }

    func fetchImage(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let response = response as? HTTPURLResponse else {
            throw FXTwitterError.invalidResponse
        }
        guard (200..<300).contains(response.statusCode) else {
            throw FXTwitterError.httpStatus(response.statusCode)
        }
        guard !data.isEmpty, data.count <= Self.maximumImageBytes else {
            throw FXTwitterError.responseTooLarge
        }
        return data
    }
}
