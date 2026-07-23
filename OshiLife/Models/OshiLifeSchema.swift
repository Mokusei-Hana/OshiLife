import Foundation
import SwiftData

enum OshiLifeSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [LiveEvent.self] }

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
            statusRawValue: String = LiveStatus.planned.rawValue,
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
            self.statusRawValue = statusRawValue
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }
}

enum OshiLifeSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] { [LiveEvent.self] }
}

enum OshiLifeMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [OshiLifeSchemaV1.self, OshiLifeSchemaV2.self] }
    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: OshiLifeSchemaV1.self, toVersion: OshiLifeSchemaV2.self)]
    }
}
