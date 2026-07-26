import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

protocol EventLinkImporting: Sendable {
    func importDetails(from urls: [URL]) async throws -> EventImportDetails?
}

struct EventLinkImporter: EventLinkImporting, Sendable {
    static let maximumResponseBytes = 2 * 1_024 * 1_024

    private let session: URLSession
    private let parsers: [any EventPageParsing]

    init(session: URLSession? = nil, parsers: [any EventPageParsing] = [HeroinesEventPageParser()]) {
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

        if let supported = links.first(where: { url in parsers.contains { $0.supports(url) } }),
           let parser = parsers.first(where: { $0.supports(supported) }) {
            return try await fetchAndParse(supported, with: parser)
        }

        if first.host?.lowercased() == "t.co" {
            return try await resolveShortLink(first)
        }
        return EventImportDetails(linkedURL: first)
    }

    private func fetchAndParse(
        _ supported: URL,
        with parser: any EventPageParsing
    ) async throws -> EventImportDetails {
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
            return parser.parse(html: html, sourceURL: supported)
                ?? EventImportDetails(linkedURL: supported)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            return EventImportDetails(linkedURL: supported)
        }
    }

    private func resolveShortLink(_ shortURL: URL) async throws -> EventImportDetails {
        do {
            let (data, response) = try await session.data(from: shortURL)
            guard let resolvedURL = response.url else { return EventImportDetails(linkedURL: shortURL) }
            guard data.count <= Self.maximumResponseBytes,
                  let parser = parsers.first(where: { $0.supports(resolvedURL) }),
                  let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .japaneseEUC) else {
                return EventImportDetails(linkedURL: resolvedURL)
            }
            return parser.parse(html: html, sourceURL: resolvedURL)
                ?? EventImportDetails(linkedURL: resolvedURL)
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
