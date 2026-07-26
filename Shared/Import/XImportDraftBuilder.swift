import Foundation

struct XImportDraftBuilder: Sendable {
    private let client: any XOEmbedFetching
    private let eventLinkImporter: any EventLinkImporting
    private let fxTwitterClient: any FXTwitterFetching
    private let imageDownloader: any RemoteImageDataFetching

    init(
        client: any XOEmbedFetching = XOEmbedClient(),
        eventLinkImporter: any EventLinkImporting = EventLinkImporter(),
        fxTwitterClient: any FXTwitterFetching = FXTwitterClient(),
        imageDownloader: any RemoteImageDataFetching = RemoteImageDataClient()
    ) {
        self.client = client
        self.eventLinkImporter = eventLinkImporter
        self.fxTwitterClient = fxTwitterClient
        self.imageDownloader = imageDownloader
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
            var details = try await eventLinkImporter.importDetails(from: contentURLs)
            // Announcements often live in the post itself. Text-parsed values
            // only fill fields the linked page could not provide.
            if let postText = metadata.postText,
               let textDetails = JapaneseEventTextParser.parse(postText)
                .details(linkedURL: details?.linkedURL ?? metadata.canonicalURL) {
                details = details.map { $0.fillingMissingFields(from: textDetails) } ?? textDetails
            }
            if let details {
                draft.eventDetails = details
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            draft.warning = String(localized: "share.metadata_warning \(error.localizedDescription)")
        }

        // FxTwitter is only an optional media source. Metadata or image failures
        // must leave the editable oEmbed draft usable.
        do {
            let media = try await fxTwitterClient.fetch(postURL: normalized)
            for imageURL in media.imageURLs {
                do {
                    let data = try await imageDownloader.fetchImage(from: imageURL)
                    if !data.isEmpty {
                        draft.imageData = data
                        break
                    }
                } catch is CancellationError {
                    throw CancellationError()
                } catch {
                    continue
                }
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            // The current import behavior does not depend on media availability.
        }

        // Posts without media can still get a cover from the event page.
        if draft.imageData == nil, let imageURL = draft.eventDetails?.imageURL {
            do {
                let data = try await imageDownloader.fetchImage(from: imageURL)
                if !data.isEmpty {
                    draft.imageData = data
                }
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                // A missing cover image never blocks the import.
            }
        }
        return draft
    }
}
