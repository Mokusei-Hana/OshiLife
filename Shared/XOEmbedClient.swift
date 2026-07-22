import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(UIKit)
import UIKit
#endif

struct XOEmbedResponse: Decodable, Sendable {
    let url: URL
    let authorName: String
    let authorURL: URL?
    let html: String

    enum CodingKeys: String, CodingKey {
        case url
        case authorName = "author_name"
        case authorURL = "author_url"
        case html
    }
}

struct XOEmbedMetadata: Sendable {
    let canonicalURL: URL
    let authorName: String
    let postText: String?
}

enum XOEmbedError: LocalizedError {
    case invalidURL
    case invalidResponse
    case responseTooLarge
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: String(localized: "error.invalid_x_url")
        case .invalidResponse: String(localized: "error.oembed_response")
        case .responseTooLarge: String(localized: "error.oembed_too_large")
        case .httpStatus(let status): String(localized: "error.oembed_http \(status)")
        }
    }
}

struct XOEmbedClient: Sendable {
    static let maximumResponseBytes = 512 * 1_024
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

    func fetch(postURL: URL) async throws -> XOEmbedMetadata {
        guard let normalized = XURLValidator.normalizedPostURL(from: postURL),
              var components = URLComponents(string: "https://publish.x.com/oembed") else {
            throw XOEmbedError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "url", value: normalized.absoluteString)]
        guard let endpoint = components.url else { throw XOEmbedError.invalidURL }

        let (data, response) = try await session.data(from: endpoint)
        guard let response = response as? HTTPURLResponse else { throw XOEmbedError.invalidResponse }
        guard (200..<300).contains(response.statusCode) else { throw XOEmbedError.httpStatus(response.statusCode) }
        guard data.count <= Self.maximumResponseBytes else { throw XOEmbedError.responseTooLarge }

        let decoded = try JSONDecoder().decode(XOEmbedResponse.self, from: data)
        return XOEmbedMetadata(
            canonicalURL: XURLValidator.normalizedPostURL(from: decoded.url) ?? normalized,
            authorName: decoded.authorName,
            postText: Self.postText(from: decoded.html)
        )
    }

    static func postText(from html: String) -> String? {
        guard let expression = try? NSRegularExpression(
            pattern: #"<p(?:\s[^>]*)?>(.*?)</p>"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ), let match = expression.firstMatch(
            in: html,
            range: NSRange(html.startIndex..., in: html)
        ), let range = Range(match.range(at: 1), in: html) else {
            return nil
        }
        let fragment = String(html[range])

        #if canImport(UIKit)
        guard let data = fragment.data(using: .utf8),
              let attributed = try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil
              ) else { return nil }
        let text = attributed.string.trimmingCharacters(in: .whitespacesAndNewlines)
        #else
        let text = fragment
            .replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        #endif
        return text.isEmpty ? nil : text
    }
}
