import Foundation
import SwiftData

typealias LiveEvent = OshiLifeSchemaV4.LiveEvent

extension OshiLifeSchemaV2 {
    @Model
    final class LiveEvent {
        @Attribute(.unique) var id: UUID
        var artistName: String
        var title: String
        var eventDate: Date
        var startTime: Date?
        var venue: String
        var address: String
        var latitude: Double?
        var longitude: Double?
        var coverImagePath: String?
        var ticketURLString: String
        var sourceURLString: String
        var notes: String
        var statusRawValue: String
        var createdAt: Date
        var updatedAt: Date

        init(
            id: UUID = UUID(),
            artistName: String,
            title: String,
            eventDate: Date,
            startTime: Date? = nil,
            venue: String = "",
            address: String = "",
            latitude: Double? = nil,
            longitude: Double? = nil,
            coverImagePath: String? = nil,
            ticketURLString: String = "",
            sourceURLString: String = "",
            notes: String = "",
            status: LiveStatus = .planned,
            createdAt: Date = .now,
            updatedAt: Date = .now
        ) {
            self.id = id
            self.artistName = artistName
            self.title = title
            self.eventDate = eventDate
            self.startTime = startTime
            self.venue = venue
            self.address = address
            self.latitude = latitude
            self.longitude = longitude
            self.coverImagePath = coverImagePath
            self.ticketURLString = ticketURLString
            self.sourceURLString = sourceURLString
            self.notes = notes
            self.statusRawValue = status.rawValue
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }

        var status: LiveStatus {
            get { LiveStatus(rawValue: statusRawValue) ?? .planned }
            set { statusRawValue = newValue.rawValue }
        }

        var ticketURL: URL? { Self.validHTTPURL(ticketURLString) }
        var sourceURL: URL? { Self.validHTTPURL(sourceURLString) }

        static func validHTTPURL(_ rawValue: String) -> URL? {
            let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let url = URL(string: trimmed),
                  let scheme = url.scheme?.lowercased(),
                  ["http", "https"].contains(scheme),
                  url.host != nil else { return nil }
            return url
        }
    }
}

extension OshiLifeSchemaV3 {
    @Model
    final class LiveEvent {
        @Attribute(.unique) var id: UUID
        var artistName: String
        var title: String
        var eventDate: Date
        var openTime: Date?
        var startTime: Date?
        var venue: String
        var address: String
        var latitude: Double?
        var longitude: Double?
        var coverImagePath: String?
        var ticketURLString: String
        var sourceURLString: String
        var performersJSON: String = "[]"
        var ticketOptionsJSON: String = "[]"
        var selectedTicketID: UUID?
        var notes: String
        var statusRawValue: String
        var createdAt: Date
        var updatedAt: Date

        init(
            id: UUID = UUID(),
            artistName: String,
            title: String,
            eventDate: Date,
            openTime: Date? = nil,
            startTime: Date? = nil,
            venue: String = "",
            address: String = "",
            latitude: Double? = nil,
            longitude: Double? = nil,
            coverImagePath: String? = nil,
            ticketURLString: String = "",
            sourceURLString: String = "",
            performers: [String] = [],
            ticketOptions: [TicketOption] = [],
            selectedTicketID: UUID? = nil,
            notes: String = "",
            status: LiveStatus = .planned,
            createdAt: Date = .now,
            updatedAt: Date = .now
        ) {
            self.id = id
            self.artistName = artistName
            self.title = title
            self.eventDate = eventDate
            self.openTime = openTime
            self.startTime = startTime
            self.venue = venue
            self.address = address
            self.latitude = latitude
            self.longitude = longitude
            self.coverImagePath = coverImagePath
            self.ticketURLString = ticketURLString
            self.sourceURLString = sourceURLString
            self.notes = notes
            self.statusRawValue = status.rawValue
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.performers = performers
            self.ticketOptions = ticketOptions
            self.selectedTicketID = selectedTicketID
        }

        var status: LiveStatus {
            get { LiveStatus(rawValue: statusRawValue) ?? .planned }
            set { statusRawValue = newValue.rawValue }
        }

        var performers: [String] {
            get { Self.decode([String].self, from: performersJSON) ?? [] }
            set { performersJSON = Self.encode(newValue) }
        }

        var ticketOptions: [TicketOption] {
            get { Self.decode([TicketOption].self, from: ticketOptionsJSON) ?? [] }
            set {
                ticketOptionsJSON = Self.encode(newValue)
                if let selectedTicketID, !newValue.contains(where: { $0.id == selectedTicketID }) {
                    self.selectedTicketID = nil
                }
            }
        }

        var selectedTicket: TicketOption? {
            guard let selectedTicketID else { return nil }
            return ticketOptions.first { $0.id == selectedTicketID }
        }

        var selectedTicketName: String? {
            get { selectedTicket?.name }
            set { selectedTicketID = ticketOptions.first { $0.name == newValue }?.id }
        }

        var ticketURL: URL? { Self.validHTTPURL(ticketURLString) }
        var sourceURL: URL? { Self.validHTTPURL(sourceURLString) }

        var ticketActionURL: URL? {
            guard let ticketURL else { return nil }
            guard selectedTicketID != nil else { return ticketURL }
            return TicketPlatform.detect(from: ticketURL)?.ticketAccessURL ?? ticketURL
        }

        static func validHTTPURL(_ rawValue: String) -> URL? {
            let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let url = URL(string: trimmed),
                  let scheme = url.scheme?.lowercased(),
                  ["http", "https"].contains(scheme),
                  url.host != nil else { return nil }
            return url
        }

        private static func encode<T: Encodable>(_ value: T) -> String {
            guard let data = try? JSONEncoder().encode(value),
                  let string = String(data: data, encoding: .utf8) else {
                return "[]"
            }
            return string
        }

        private static func decode<T: Decodable>(_ type: T.Type, from string: String) -> T? {
            guard let data = string.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode(type, from: data)
        }
    }
}

extension OshiLifeSchemaV4 {
    @Model
    final class LiveEvent {
        @Attribute(.unique) var id: UUID
        var artistName: String
        var title: String
        var eventDate: Date
        var openTime: Date?
        var startTime: Date?
        var venue: String
        var address: String
        var latitude: Double?
        var longitude: Double?
        var coverImagePath: String?
        var ticketURLString: String
        var sourceURLString: String
        var performersJSON: String = "[]"
        var performerCandidatesJSON: String = "[]"
        var ticketOptionsJSON: String = "[]"
        var selectedTicketID: UUID?
        var scheduleGroupID: UUID?
        var scheduleOptionID: UUID?
        var scheduleLabel: String = ""
        var scheduleOptionsJSON: String = "[]"
        var notes: String
        var statusRawValue: String
        var createdAt: Date
        var updatedAt: Date

        init(
            id: UUID = UUID(),
            artistName: String,
            title: String,
            eventDate: Date,
            openTime: Date? = nil,
            startTime: Date? = nil,
            venue: String = "",
            address: String = "",
            latitude: Double? = nil,
            longitude: Double? = nil,
            coverImagePath: String? = nil,
            ticketURLString: String = "",
            sourceURLString: String = "",
            performers: [String] = [],
            performerCandidates: [String] = [],
            ticketOptions: [TicketOption] = [],
            selectedTicketID: UUID? = nil,
            scheduleGroupID: UUID? = nil,
            scheduleOptionID: UUID? = nil,
            scheduleLabel: String = "",
            scheduleOptions: [EventScheduleOption] = [],
            notes: String = "",
            status: LiveStatus = .planned,
            createdAt: Date = .now,
            updatedAt: Date = .now
        ) {
            self.id = id
            self.artistName = artistName
            self.title = title
            self.eventDate = eventDate
            self.openTime = openTime
            self.startTime = startTime
            self.venue = venue
            self.address = address
            self.latitude = latitude
            self.longitude = longitude
            self.coverImagePath = coverImagePath
            self.ticketURLString = ticketURLString
            self.sourceURLString = sourceURLString
            self.notes = notes
            self.statusRawValue = status.rawValue
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.scheduleGroupID = scheduleGroupID
            self.scheduleOptionID = scheduleOptionID
            self.scheduleLabel = scheduleLabel
            self.performers = performers
            self.performerCandidates = performerCandidates
            self.ticketOptions = ticketOptions
            self.selectedTicketID = selectedTicketID
            self.scheduleOptions = scheduleOptions
        }

        var status: LiveStatus {
            get { LiveStatus(rawValue: statusRawValue) ?? .planned }
            set { statusRawValue = newValue.rawValue }
        }

        var performers: [String] {
            get { Self.decode([String].self, from: performersJSON) ?? [] }
            set { performersJSON = Self.encode(newValue) }
        }

        var performerCandidates: [String] {
            get { Self.decode([String].self, from: performerCandidatesJSON) ?? [] }
            set { performerCandidatesJSON = Self.encode(newValue) }
        }

        var ticketOptions: [TicketOption] {
            get { Self.decode([TicketOption].self, from: ticketOptionsJSON) ?? [] }
            set {
                ticketOptionsJSON = Self.encode(newValue)
                if let selectedTicketID, !newValue.contains(where: { $0.id == selectedTicketID }) {
                    self.selectedTicketID = nil
                }
            }
        }

        var scheduleOptions: [EventScheduleOption] {
            get { Self.decode([EventScheduleOption].self, from: scheduleOptionsJSON) ?? [] }
            set { scheduleOptionsJSON = Self.encode(newValue) }
        }

        var selectedTicket: TicketOption? {
            guard let selectedTicketID else { return nil }
            return ticketOptions.first { $0.id == selectedTicketID }
        }

        var selectedTicketName: String? {
            get { selectedTicket?.name }
            set { selectedTicketID = ticketOptions.first { $0.name == newValue }?.id }
        }

        var ticketURL: URL? { Self.validHTTPURL(ticketURLString) }
        var sourceURL: URL? { Self.validHTTPURL(sourceURLString) }

        var ticketActionURL: URL? {
            guard let ticketURL else { return nil }
            guard selectedTicketID != nil else { return ticketURL }
            return TicketPlatform.detect(from: ticketURL)?.ticketAccessURL ?? ticketURL
        }

        static func validHTTPURL(_ rawValue: String) -> URL? {
            let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let url = URL(string: trimmed),
                  let scheme = url.scheme?.lowercased(),
                  ["http", "https"].contains(scheme),
                  url.host != nil else { return nil }
            return url
        }

        private static func encode<T: Encodable>(_ value: T) -> String {
            guard let data = try? JSONEncoder().encode(value),
                  let string = String(data: data, encoding: .utf8) else {
                return "[]"
            }
            return string
        }

        private static func decode<T: Decodable>(_ type: T.Type, from string: String) -> T? {
            guard let data = string.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode(type, from: data)
        }
    }
}
