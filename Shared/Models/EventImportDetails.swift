import Foundation

struct EventImportDetails: Codable, Hashable, Sendable {
    var title: String?
    var date: Date?
    /// Last day of a multi-day event, when the announcement covers a range.
    var endDate: Date?
    var venue: String?
    var openTime: Date?
    var startTime: Date?
    var performers: [String]
    var ticketOptions: [TicketOption]
    var ticketInformation: String?
    /// Cover image candidate discovered on the event page (e.g. og:image).
    var imageURL: URL?
    var linkedURL: URL
    /// Shortened URLs (e.g. t.co) from the post that redirected to
    /// `linkedURL`. Kept so Notes cleanup can drop them once their
    /// destination is stored in a structured field.
    var shortenedLinkURLs: [URL]
    /// Individual days for a multi-day event (e.g. DAY1/DAY2/DAY3).
    /// Empty for single-day events. When non-empty the editor shows a day
    /// selector so the user can choose which day they are attending.
    var scheduleOptions: [EventScheduleOption]

    private enum CodingKeys: String, CodingKey {
        case title
        case date
        case endDate
        case venue
        case openTime
        case startTime
        case performers
        case ticketOptions
        case ticketInformation
        case imageURL
        case linkedURL
        case shortenedLinkURLs
        case scheduleOptions
    }

    init(
        title: String? = nil,
        date: Date? = nil,
        endDate: Date? = nil,
        venue: String? = nil,
        openTime: Date? = nil,
        startTime: Date? = nil,
        performers: [String] = [],
        ticketOptions: [TicketOption] = [],
        ticketInformation: String? = nil,
        imageURL: URL? = nil,
        linkedURL: URL,
        shortenedLinkURLs: [URL] = [],
        scheduleOptions: [EventScheduleOption] = []
    ) {
        self.title = title
        self.date = date
        self.endDate = endDate
        self.venue = venue
        self.openTime = openTime
        self.startTime = startTime
        self.performers = performers
        self.ticketOptions = ticketOptions
        self.ticketInformation = ticketInformation
        self.imageURL = imageURL
        self.linkedURL = linkedURL
        self.shortenedLinkURLs = shortenedLinkURLs
        self.scheduleOptions = scheduleOptions
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        date = try container.decodeIfPresent(Date.self, forKey: .date)
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        venue = try container.decodeIfPresent(String.self, forKey: .venue)
        openTime = try container.decodeIfPresent(Date.self, forKey: .openTime)
        startTime = try container.decodeIfPresent(Date.self, forKey: .startTime)
        performers = try container.decodeIfPresent([String].self, forKey: .performers) ?? []
        ticketOptions = try container.decodeIfPresent([TicketOption].self, forKey: .ticketOptions) ?? []
        ticketInformation = try container.decodeIfPresent(String.self, forKey: .ticketInformation)
        imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
        linkedURL = try container.decode(URL.self, forKey: .linkedURL)
        shortenedLinkURLs = try container.decodeIfPresent([URL].self, forKey: .shortenedLinkURLs) ?? []
        scheduleOptions = try container.decodeIfPresent([EventScheduleOption].self, forKey: .scheduleOptions) ?? []
    }

    /// Fills fields this source could not recognize with values from another
    /// source, so partially parsed imports can be combined without ever
    /// discarding successfully parsed information.
    func fillingMissingFields(from other: EventImportDetails) -> EventImportDetails {
        var merged = self
        merged.title = title ?? other.title
        merged.date = date ?? other.date
        // An end date is only adopted together with the start date it
        // belongs to; another source must not attach its end date to this
        // source's day (e.g. an X post reshaping a multi-day website range).
        merged.endDate = endDate ?? (date == nil ? other.endDate : nil)
        merged.venue = venue ?? other.venue
        merged.openTime = openTime ?? other.openTime
        merged.startTime = startTime ?? other.startTime
        if merged.performers.isEmpty { merged.performers = other.performers }
        if merged.ticketOptions.isEmpty { merged.ticketOptions = other.ticketOptions }
        merged.ticketInformation = ticketInformation ?? other.ticketInformation
        merged.imageURL = imageURL ?? other.imageURL
        if merged.shortenedLinkURLs.isEmpty { merged.shortenedLinkURLs = other.shortenedLinkURLs }
        if merged.scheduleOptions.isEmpty { merged.scheduleOptions = other.scheduleOptions }
        return merged
    }
}
