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
        [HeroinesEventPageParser(), TicketDiveEventPageParser(), GenericEventPageParser()]
    }

    private let session: URLSession
    private let parsers: [any EventPageParsing]
    private let shortLinkResolver: any ShortLinkResolving

    init(
        session: URLSession? = nil,
        parsers: [any EventPageParsing] = EventLinkImporter.defaultParsers,
        shortLinkResolver: any ShortLinkResolving = ShortLinkResolver()
    ) {
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
        self.shortLinkResolver = shortLinkResolver
    }

    func importDetails(from urls: [URL]) async throws -> EventImportDetails? {
        let links = Self.uniqueWebURLs(urls)
        guard !links.isEmpty else { return nil }

        // Short links must be expanded before classification: a t.co link
        // gives no hint which parser its destination needs.
        let resolution = await resolvingShortLinks(in: links)
        guard let first = resolution.links.first else { return nil }

        if let supported = matchedURL(in: resolution.links) {
            var details = try await fetchAndParse(supported)
            details.shortenedLinkURLs = resolution.shortLinks(for: details.linkedURL)
            return details
        }
        var details = EventImportDetails(linkedURL: first)
        details.shortenedLinkURLs = resolution.shortLinks(for: first)
        return details
    }

    private struct ShortLinkResolution {
        var links: [URL]
        /// Original shortened URLs keyed by the destination they resolved to.
        var origins: [String: [URL]]

        func shortLinks(for url: URL) -> [URL] { origins[url.absoluteString] ?? [] }
    }

    /// Replaces every shortened link with its resolved destination, keeping
    /// order, dropping duplicates between original and resolved URLs, and
    /// discarding destinations that are not importable event links (such as
    /// a t.co link that redirects back to an X post or attached media).
    private func resolvingShortLinks(in links: [URL]) async -> ShortLinkResolution {
        var resolved: [URL] = []
        var origins: [String: [URL]] = [:]
        var seen = Set<String>()
        for link in links {
            var destination = link
            if ShortLinkResolver.isShortLink(link) {
                destination = await shortLinkResolver.resolve(link)
                if destination != link {
                    guard Self.isImportableWebURL(destination) else { continue }
                    origins[destination.absoluteString, default: []].append(link)
                }
            }
            if seen.insert(destination.absoluteString).inserted {
                resolved.append(destination)
            }
        }
        return ShortLinkResolution(links: resolved, origins: origins)
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

    static func urls(in text: String) -> [URL] {
        #if canImport(Darwin)
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }
        return detector.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap { $0.url }
        #else
        // NSDataDetector is unavailable in swift-corelibs-foundation; a
        // regex approximation keeps Linux-based test runs working. The app
        // itself always uses the NSDataDetector path above.
        guard let expression = try? NSRegularExpression(
            pattern: #"(?:https?://|www\.|pic\.(?:twitter|x)\.com/|t\.co/)[^\s<>"']+"#,
            options: [.caseInsensitive]
        ) else { return [] }
        let trailingPunctuation = CharacterSet(charactersIn: ",.!?;:、。)]}")
        return expression.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            var value = String(text[range]).trimmingCharacters(in: trailingPunctuation)
            if !value.lowercased().hasPrefix("http") { value = "http://" + value }
            return URL(string: value)
        }
        #endif
    }

    /// Hosts that never lead to an importable event page: X posts have their
    /// own import path, and `pic.twitter.com` links are media attachment
    /// placeholders, not event or ticket links.
    private static let excludedHosts: Set<String> = [
        "x.com", "www.x.com", "twitter.com", "www.twitter.com", "mobile.twitter.com",
        "pic.twitter.com", "pic.x.com"
    ]

    private static func isImportableWebURL(_ url: URL) -> Bool {
        guard ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return false }
        return !excludedHosts.contains(url.host?.lowercased() ?? "")
    }

    private static func uniqueWebURLs(_ urls: [URL]) -> [URL] {
        var seen = Set<String>()
        return urls.filter {
            isImportableWebURL($0) && seen.insert($0.absoluteString).inserted
        }
    }
}
