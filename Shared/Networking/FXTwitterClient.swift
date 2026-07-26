import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct FXTwitterMediaItem: Decodable, Sendable {
    let type: String?
    let url: URL?

    init(type: String?, url: URL?) {
        self.type = type
        self.url = url
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        let value = try container.decodeIfPresent(String.self, forKey: .url)
        url = value.flatMap(URL.init(string:))
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case url
    }
}

struct FXTwitterMedia: Decodable, Sendable {
    let all: [FXTwitterMediaItem]

    init(all: [FXTwitterMediaItem]) {
        self.all = all
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        all = try container.decodeIfPresent([FXTwitterMediaItem].self, forKey: .all) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case all
    }
}

struct FXTwitterTweet: Decodable, Sendable {
    let url: URL?
    let media: FXTwitterMedia?
}

struct FXTwitterResponse: Decodable, Sendable {
    let code: Int?
    let tweet: FXTwitterTweet
}

struct FXTwitterMetadata: Sendable {
    let canonicalURL: URL
    let imageURLs: [URL]
}

protocol FXTwitterFetching: Sendable {
    func fetch(postURL: URL) async throws -> FXTwitterMetadata
}

enum FXTwitterError: LocalizedError {
    case invalidURL
    case invalidResponse
    case responseTooLarge
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid X URL"
        case .invalidResponse: "Invalid FxTwitter response"
        case .responseTooLarge: "FxTwitter response is too large"
        case .httpStatus(let status): "FxTwitter returned HTTP \(status)"
        }
    }
}

struct FXTwitterClient: FXTwitterFetching, Sendable {
    static let maximumResponseBytes = 1 * 1_024 * 1_024

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

    func fetch(postURL: URL) async throws -> FXTwitterMetadata {
        guard let normalized = XURLValidator.normalizedPostURL(from: postURL),
              let statusID = normalized.path.split(separator: "/").last,
              let endpoint = URL(string: "https://api.fxtwitter.com/status/\(statusID)") else {
            throw FXTwitterError.invalidURL
        }

        let (data, response) = try await session.data(from: endpoint)
        guard let response = response as? HTTPURLResponse else {
            throw FXTwitterError.invalidResponse
        }
        guard (200..<300).contains(response.statusCode) else {
            throw FXTwitterError.httpStatus(response.statusCode)
        }
        guard data.count <= Self.maximumResponseBytes else {
            throw FXTwitterError.responseTooLarge
        }

        let decoded = try JSONDecoder().decode(FXTwitterResponse.self, from: data)
        let canonicalURL = XURLValidator.normalizedPostURL(from: decoded.tweet.url ?? normalized) ?? normalized
        return FXTwitterMetadata(canonicalURL: canonicalURL, imageURLs: Self.imageURLs(in: decoded))
    }

    static func imageURLs(in response: FXTwitterResponse) -> [URL] {
        var seen = Set<URL>()
        return (response.tweet.media?.all ?? []).compactMap { item in
            guard item.type?.lowercased() == "photo",
                  let url = item.url,
                  ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
                  seen.insert(url).inserted else {
                return nil
            }
            return url
        }
    }
}
