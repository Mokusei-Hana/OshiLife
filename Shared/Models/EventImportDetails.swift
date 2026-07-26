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
        linkedURL: URL
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
    }

    /// Fills fields this source could not recognize with values from another
    /// source, so partially parsed imports can be combined without ever
    /// discarding successfully parsed information.
    func fillingMissingFields(from other: EventImportDetails) -> EventImportDetails {
        var merged = self
        merged.title = title ?? other.title
        merged.date = date ?? other.date
        merged.endDate = endDate ?? other.endDate
        merged.venue = venue ?? other.venue
        merged.openTime = openTime ?? other.openTime
        merged.startTime = startTime ?? other.startTime
        if merged.performers.isEmpty { merged.performers = other.performers }
        if merged.ticketOptions.isEmpty { merged.ticketOptions = other.ticketOptions }
        merged.ticketInformation = ticketInformation ?? other.ticketInformation
        merged.imageURL = imageURL ?? other.imageURL
        return merged
    }
}
