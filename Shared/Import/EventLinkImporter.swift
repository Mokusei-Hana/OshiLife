import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

protocol EventLinkImporting: Sendable {
    func importDetails(from urls: [URL]) async throws -> EventImportDetails?
}

struct EventLinkImporter: EventLinkImporting, Sendable {
    static let maximumResponseBytes = 2 * 1_024 * 1_024

    /// Site-specific parsers first, then the generic fallback pipeline for
    /// unsupported websites. Add new site parsers before the generic one.
    static var defaultParsers: [any EventPageParsing] {
        [HeroinesEventPageParser(), GenericEventPageParser()]
    }

    private let session: URLSession
    private let parsers: [any EventPageParsing]

    init(session: URLSession? = nil, parsers: [any EventPageParsing] = EventLinkImporter.defaultParsers) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = 12
            configuration.timeoutIntervalForResource = 15
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
            self.session = URLSession(configuration: configuration)
        }
        self.parsers = parsers
    }

    func importDetails(from urls: [URL]) async throws -> EventImportDetails? {
        let links = Self.uniqueWebURLs(urls)
        guard let first = links.first else { return nil }

        if let supported = matchedURL(in: links) {
            return try await fetchAndParse(supported)
        }
        if first.host?.lowercased() == "t.co" {
            return try await resolveShortLink(first)
        }
        return EventImportDetails(linkedURL: first)
    }

    /// Picks the link handled by the highest-priority parser, so a link with
    /// a site-specific parser wins over one that only the generic parser
    /// understands.
    private func matchedURL(in links: [URL]) -> URL? {
        for parser in parsers {
            if let url = links.first(where: parser.supports) { return url }
        }
        return nil
    }

    private func fetchAndParse(_ supported: URL) async throws -> EventImportDetails {
        do {
            var request = URLRequest(url: supported)
            request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
            let (data, response) = try await session.data(for: request)
            guard let response = response as? HTTPURLResponse,
                  (200..<300).contains(response.statusCode),
                  data.count <= Self.maximumResponseBytes,
                  let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .japaneseEUC) else {
                return EventImportDetails(linkedURL: supported)
            }
            return parse(html: html, sourceURL: supported)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            return EventImportDetails(linkedURL: supported)
        }
    }

    /// Tries every parser that supports the URL in priority order, so a
    /// site-specific parser that recognizes nothing on a page still falls
    /// through to the generic pipeline, and finally to a plain link.
    private func parse(html: String, sourceURL: URL) -> EventImportDetails {
        for parser in parsers where parser.supports(sourceURL) {
            if let details = parser.parse(html: html, sourceURL: sourceURL) {
                return details
            }
        }
        return EventImportDetails(linkedURL: sourceURL)
    }

    private func resolveShortLink(_ shortURL: URL) async throws -> EventImportDetails {
        do {
            let (data, response) = try await session.data(from: shortURL)
            guard let resolvedURL = response.url else { return EventImportDetails(linkedURL: shortURL) }
            guard data.count <= Self.maximumResponseBytes,
                  parsers.contains(where: { $0.supports(resolvedURL) }),
                  let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .japaneseEUC) else {
                return EventImportDetails(linkedURL: resolvedURL)
            }
            return parse(html: html, sourceURL: resolvedURL)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            return EventImportDetails(linkedURL: shortURL)
        }
    }

    static func urls(in text: String) -> [URL] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }
        return detector.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap(\.url)
    }

    private static func uniqueWebURLs(_ urls: [URL]) -> [URL] {
        var seen = Set<String>()
        return urls.filter {
            guard ["http", "https"].contains($0.scheme?.lowercased() ?? ""),
                  !["x.com", "www.x.com", "twitter.com", "www.twitter.com"].contains($0.host?.lowercased() ?? "") else {
                return false
            }
            return seen.insert($0.absoluteString).inserted
        }
    }
}
