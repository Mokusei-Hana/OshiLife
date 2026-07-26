import Foundation

/// Fallback parser for event pages without a site-specific parser: ticket
/// shops, organizer sites, and other unsupported websites.
///
/// It combines three sources in priority order — structured JSON-LD Event
/// data, Japanese announcement text heuristics, and Open Graph metadata —
/// and returns whatever subset of fields could be recognized. It returns nil
/// only when the page contains no event signal at all, so the import falls
/// back to a plain link instead of guessed fields.
struct GenericEventPageParser: EventPageParsing, Sendable {
    /// Hosts that must not be parsed as generic event pages: X posts have a
    /// dedicated import path and t.co links need resolving first.
    private static let excludedHosts: Set<String> = [
        "t.co", "x.com", "www.x.com", "twitter.com", "www.twitter.com", "mobile.twitter.com"
    ]

    func supports(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme),
              let host = url.host?.lowercased() else { return false }
        return !Self.excludedHosts.contains(host)
    }

    func parse(html: String, sourceURL: URL) -> EventImportDetails? {
        let structured = JSONLDEventExtractor.firstEvent(in: html)
        let openGraph = OpenGraphMetadata(html: html)
        let text = JapaneseEventTextParser.parse(HTMLTextExtractor.plainText(from: html))

        guard structured != nil || text.hasEventSignals else { return nil }

        let date = structured?.startDate ?? text.date
        let startTime = (structured?.startDateIncludesTime == true ? structured?.startDate : nil)
            ?? text.startTime
        var endDate = structured?.endDate ?? text.endDate
        if let start = date, let end = endDate, Self.tokyoCalendar.isDate(start, inSameDayAs: end) {
            endDate = nil
        }

        let performers = structured?.performers.isEmpty == false ? structured!.performers : text.performers
        let ticketOptions = structured?.ticketOptions.isEmpty == false ? structured!.ticketOptions : text.ticketOptions
        let imageURLString = structured?.imageURLString ?? openGraph.imageURLString

        return EventImportDetails(
            title: structured?.name ?? text.title ?? openGraph.cleanedTitle,
            date: date,
            endDate: endDate,
            venue: structured?.venueName ?? text.venue,
            openTime: structured?.doorTime ?? text.openTime,
            startTime: startTime,
            performers: performers,
            ticketOptions: ticketOptions,
            ticketInformation: text.ticketInformation,
            imageURL: imageURLString.flatMap { URL(string: $0, relativeTo: sourceURL)?.absoluteURL },
            linkedURL: sourceURL
        )
    }

    private static var tokyoCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }
}
