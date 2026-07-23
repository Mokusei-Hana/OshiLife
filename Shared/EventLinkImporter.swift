import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

protocol EventLinkImporting: Sendable {
    func importDetails(from urls: [URL]) async throws -> EventImportDetails?
}

protocol EventPageParsing: Sendable {
    func supports(_ url: URL) -> Bool
    func parse(html: String, sourceURL: URL) -> EventImportDetails?
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

struct HeroinesEventPageParser: EventPageParsing, Sendable {
    func supports(_ url: URL) -> Bool {
        let host = url.host?.lowercased()
        return host == "heroines.jp" || host == "www.heroines.jp"
    }

    func parse(html: String, sourceURL: URL) -> EventImportDetails? {
        let text = Self.plainText(from: html)
        let eventText = Self.eventSection(in: text)
        guard let date = Self.eventDate(in: eventText) else { return nil }

        let title = Self.eventTitle(in: eventText, html: html)
        let venue = Self.firstCapture(#"(?:^|\n)\s*[@＠]\s*([^\n]+)"#, in: eventText)
            ?? Self.firstCapture(#"(?:会場|VENUE)\s*[：:]\s*([^\n]+)"#, in: eventText, caseInsensitive: true)
        let times = Self.times(in: eventText, eventDate: date)
        let performers = Self.performers(in: eventText)
        let ticketInformation = Self.ticketInformation(in: eventText)

        guard title != nil || venue != nil || times.open != nil || times.start != nil else { return nil }
        return EventImportDetails(
            title: title,
            date: date,
            venue: venue,
            openTime: times.open,
            startTime: times.start,
            performers: performers,
            ticketInformation: ticketInformation,
            linkedURL: sourceURL
        )
    }

    private static func eventSection(in text: String) -> String {
        guard let range = text.range(of: #"公演概要|イベント概要"#, options: .regularExpression) else {
            return text
        }
        return String(text[range.upperBound...])
    }

    private static func plainText(from html: String) -> String {
        html
            .replacingOccurrences(of: #"(?is)<(script|style)\b[^>]*>.*?</\1>"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"(?i)<br\s*/?>"#, with: "\n", options: .regularExpression)
            .replacingOccurrences(of: #"(?i)</(?:p|div|h[1-6]|li|section|article)>"#, with: "\n", options: .regularExpression)
            .replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    private static func eventDate(in text: String) -> Date? {
        let patterns = [
            #"(?<!\d)(20\d{2})[年./-]\s*(\d{1,2})[月./-]\s*(\d{1,2})日?"#,
            #"(?<!\d)(20\d{2})\s*年\s*(\d{1,2})\s*月\s*(\d{1,2})\s*日"#
        ]
        for pattern in patterns {
            guard let values = captures(pattern, in: text, count: 3),
                  let year = Int(values[0]), let month = Int(values[1]), let day = Int(values[2]) else { continue }
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
            if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                return date
            }
        }
        return nil
    }

    private static func eventTitle(in text: String, html: String) -> String? {
        let lines = text.components(separatedBy: .newlines)
        if let dateIndex = lines.firstIndex(where: { eventDate(in: $0) != nil }) {
            let preceding = lines[..<dateIndex].reversed().prefix(2).first(where: isLikelyTitle)
            if let preceding, preceding.range(of: #"公演概要|イベント概要"#, options: .regularExpression) == nil {
                return preceding
            }
            if let following = lines.dropFirst(dateIndex + 1).prefix(4).first(where: isLikelyTitle) {
                return following
            }
        }
        if let heading = firstCapture(#"(?is)<h1\b[^>]*>(.*?)</h1>"#, in: html) {
            let clean = plainText(from: heading)
            if !clean.isEmpty, clean != "NEWS" { return clean }
        }
        return nil
    }

    private static func isLikelyTitle(_ line: String) -> Bool {
        !line.hasPrefix("@") &&
        !line.hasPrefix("＠") &&
        line.range(
            of: #"^(?:OPEN|START|開場|開演|出演|会場|チケット|前方|一般|注意|※|▼|【|〖)"#,
            options: [.regularExpression, .caseInsensitive]
        ) == nil
    }

    private static func times(in text: String, eventDate: Date) -> (open: Date?, start: Date?) {
        if let combined = captures(
            #"(?:OPEN|開場)\s*/\s*(?:START|開演)\s*[：:]?\s*(\d{1,2}:\d{2})\s*/\s*(\d{1,2}:\d{2})"#,
            in: text,
            count: 2,
            caseInsensitive: true
        ) {
            return (time(combined[0], on: eventDate), time(combined[1], on: eventDate))
        }
        let open = firstCapture(#"(?:OPEN|開場)\s*(?:/|・)?\s*[：:]?\s*(\d{1,2}:\d{2})"#, in: text, caseInsensitive: true)
        let start = firstCapture(#"(?:START|開演)\s*(?:/|・)?\s*[：:]?\s*(\d{1,2}:\d{2})"#, in: text, caseInsensitive: true)
        return (time(open, on: eventDate), time(start, on: eventDate))
    }

    private static func time(_ value: String?, on date: Date) -> Date? {
        guard let value else { return nil }
        let parts = value.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: date)
    }

    private static func performers(in text: String) -> [String] {
        guard let raw = firstCapture(#"(?:出演|出演者|ACT)\s*[：:]\s*([^\n]+)"#, in: text, caseInsensitive: true) else {
            return []
        }
        return raw.components(separatedBy: CharacterSet(charactersIn: "/／、,"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func ticketInformation(in text: String) -> String? {
        let lines = text.components(separatedBy: .newlines)
        guard let index = lines.firstIndex(where: {
            $0.range(of: #"チケット|TICKET"#, options: [.regularExpression, .caseInsensitive]) != nil
        }) else { return nil }
        let result = lines[index...].prefix(8).joined(separator: "\n")
        return result.isEmpty ? nil : result
    }

    private static func captures(
        _ pattern: String,
        in text: String,
        count: Int,
        caseInsensitive: Bool = false
    ) -> [String]? {
        let options: NSRegularExpression.Options = caseInsensitive ? [.caseInsensitive] : []
        guard let expression = try? NSRegularExpression(pattern: pattern, options: options),
              let match = expression.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > count else { return nil }
        return (1...count).compactMap {
            guard let range = Range(match.range(at: $0), in: text) else { return nil }
            return String(text[range])
        }
    }

    private static func firstCapture(
        _ pattern: String,
        in text: String,
        caseInsensitive: Bool = false
    ) -> String? {
        let options: NSRegularExpression.Options = caseInsensitive ? [.caseInsensitive] : []
        guard let expression = try? NSRegularExpression(pattern: pattern, options: options),
              let match = expression.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else { return nil }
        let value = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
