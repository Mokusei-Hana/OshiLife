import Foundation

protocol XOEmbedFetching: Sendable {
    func fetch(postURL: URL) async throws -> XOEmbedMetadata
}

extension XOEmbedClient: XOEmbedFetching {}

struct XImportDraftBuilder: Sendable {
    private let client: any XOEmbedFetching
    private let eventLinkImporter: any EventLinkImporting

    init(
        client: any XOEmbedFetching = XOEmbedClient(),
        eventLinkImporter: any EventLinkImporting = EventLinkImporter()
    ) {
        self.client = client
        self.eventLinkImporter = eventLinkImporter
    }

    func makeDraft(from candidate: URL) async throws -> PendingShareImport {
        guard let normalized = XURLValidator.normalizedPostURL(from: candidate) else {
            throw XOEmbedError.invalidURL
        }

        var draft = PendingShareImport(sourceURL: normalized)
        do {
            let metadata = try await client.fetch(postURL: normalized)
            draft.sourceURL = metadata.canonicalURL
            draft.authorName = metadata.authorName
            draft.postText = metadata.postText
            let contentURLs = metadata.linkedURLs + EventLinkImporter.urls(in: metadata.postText ?? "")
            if let details = try await eventLinkImporter.importDetails(from: contentURLs) {
                draft.eventDetails = details
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            draft.warning = String(localized: "share.metadata_warning \(error.localizedDescription)")
        }
        return draft
    }
}
