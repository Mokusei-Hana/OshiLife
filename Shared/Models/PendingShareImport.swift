import Foundation

struct PendingShareImport: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var sourceURL: URL
    var authorName: String?
    var postText: String?
    var imageRelativePath: String?
    // Downloaded media is kept only while the draft is in memory. Staged imports
    // store the bytes in the pending directory instead.
    var imageData: Data?
    var createdAt: Date
    var warning: String?
    var eventDetails: EventImportDetails?

    private enum CodingKeys: String, CodingKey {
        case id
        case sourceURL
        case authorName
        case postText
        case imageRelativePath
        case createdAt
        case warning
        case eventDetails
    }

    init(
        id: UUID = UUID(),
        sourceURL: URL,
        authorName: String? = nil,
        postText: String? = nil,
        imageRelativePath: String? = nil,
        imageData: Data? = nil,
        createdAt: Date = .now,
        warning: String? = nil,
        eventDetails: EventImportDetails? = nil
    ) {
        self.id = id
        self.sourceURL = sourceURL
        self.authorName = authorName
        self.postText = postText
        self.imageRelativePath = imageRelativePath
        self.imageData = imageData
        self.createdAt = createdAt
        self.warning = warning
        self.eventDetails = eventDetails
    }
}
