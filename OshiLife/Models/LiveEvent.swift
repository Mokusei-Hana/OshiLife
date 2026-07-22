import Foundation
import SwiftData

@Model
final class LiveEvent {
    @Attribute(.unique) var id: UUID
    var artistName: String
    var title: String
    var eventDate: Date
    var startTime: Date?
    var venue: String
    var address: String
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
