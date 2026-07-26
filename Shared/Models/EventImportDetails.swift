import Foundation

struct EventImportDetails: Codable, Hashable, Sendable {
    var title: String?
    var date: Date?
    var venue: String?
    var openTime: Date?
    var startTime: Date?
    var performers: [String]
    var ticketOptions: [TicketOption]
    var ticketInformation: String?
    var linkedURL: URL

    private enum CodingKeys: String, CodingKey {
        case title
        case date
        case venue
        case openTime
        case startTime
        case performers
        case ticketOptions
        case ticketInformation
        case linkedURL
    }

    init(
        title: String? = nil,
        date: Date? = nil,
        venue: String? = nil,
        openTime: Date? = nil,
        startTime: Date? = nil,
        performers: [String] = [],
        ticketOptions: [TicketOption] = [],
        ticketInformation: String? = nil,
        linkedURL: URL
    ) {
        self.title = title
        self.date = date
        self.venue = venue
        self.openTime = openTime
        self.startTime = startTime
        self.performers = performers
        self.ticketOptions = ticketOptions
        self.ticketInformation = ticketInformation
        self.linkedURL = linkedURL
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        date = try container.decodeIfPresent(Date.self, forKey: .date)
        venue = try container.decodeIfPresent(String.self, forKey: .venue)
        openTime = try container.decodeIfPresent(Date.self, forKey: .openTime)
        startTime = try container.decodeIfPresent(Date.self, forKey: .startTime)
        performers = try container.decodeIfPresent([String].self, forKey: .performers) ?? []
        ticketOptions = try container.decodeIfPresent([TicketOption].self, forKey: .ticketOptions) ?? []
        ticketInformation = try container.decodeIfPresent(String.self, forKey: .ticketInformation)
        linkedURL = try container.decode(URL.self, forKey: .linkedURL)
    }
}
