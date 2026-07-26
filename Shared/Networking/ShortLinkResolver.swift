import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Executes a single HTTP request without following redirects, so a resolver
/// can walk redirect chains explicitly and bound them. Injectable so tests
/// never depend on live network access.
protocol RedirectHTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> HTTPURLResponse
}

/// URLSession-backed transport whose delegate refuses every redirect, which
/// keeps each 3xx response visible to the caller instead of being followed
/// automatically.
struct URLSessionRedirectTransport: RedirectHTTPTransport {
    private final class NoRedirectDelegate: NSObject, URLSessionTaskDelegate {
        func urlSession(
            _ session: URLSession,
            task: URLSessionTask,
            willPerformHTTPRedirection response: HTTPURLResponse,
            newRequest request: URLRequest,
            completionHandler: @escaping (URLRequest?) -> Void
        ) {
            completionHandler(nil)
        }
    }

    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 8
        configuration.timeoutIntervalForResource = 10
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        session = URLSession(configuration: configuration, delegate: NoRedirectDelegate(), delegateQueue: nil)
    }

    func send(_ request: URLRequest) async throws -> HTTPURLResponse {
        let (_, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return response
    }
}

protocol ShortLinkResolving: Sendable {
    /// Follows redirects to the final destination of a shortened URL.
    /// Returns the original URL whenever resolution fails, so an import can
    /// always continue with the link it started from.
    func resolve(_ url: URL) async -> URL
}

/// Resolves shortened URLs such as `https://t.co/…` by following HTTP
/// redirects. Each hop is tried with `HEAD` first and retried with `GET`
/// when `HEAD` is unsupported or fails. Redirect chains are bounded and
/// loop-protected, and any failure falls back to the original URL.
struct ShortLinkResolver: ShortLinkResolving {
    static let maximumRedirects = 5

    private static let shortLinkHosts: Set<String> = ["t.co", "www.t.co"]

    static func isShortLink(_ url: URL) -> Bool {
        shortLinkHosts.contains(url.host?.lowercased() ?? "")
    }

    private let transport: any RedirectHTTPTransport

    init(transport: any RedirectHTTPTransport = URLSessionRedirectTransport()) {
        self.transport = transport
    }

    func resolve(_ url: URL) async -> URL {
        var current = url
        var visited: Set<String> = [current.absoluteString]
        for _ in 0..<Self.maximumRedirects {
            guard let response = await send(current) else { return url }
            guard (300..<400).contains(response.statusCode) else {
                return response.url ?? current
            }
            guard let next = Self.redirectTarget(of: response, relativeTo: current) else {
                // A redirect status without a usable target cannot settle.
                return url
            }
            guard visited.insert(next.absoluteString).inserted else {
                // Revisiting a URL means the chain loops and never settles.
                return url
            }
            current = next
        }
        return url
    }

    private func send(_ url: URL) async -> HTTPURLResponse? {
        if let head = try? await transport.send(request(for: url, method: "HEAD")),
           head.statusCode < 400 {
            return head
        }
        return try? await transport.send(request(for: url, method: "GET"))
    }

    private func request(for url: URL, method: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        return request
    }

    private static func redirectTarget(of response: HTTPURLResponse, relativeTo current: URL) -> URL? {
        let location = response.allHeaderFields.first {
            ($0.key as? String)?.lowercased() == "location"
        }?.value as? String
        guard let location,
              let next = URL(string: location, relativeTo: current)?.absoluteURL,
              ["http", "https"].contains(next.scheme?.lowercased() ?? "") else {
            return nil
        }
        return next
    }
}
