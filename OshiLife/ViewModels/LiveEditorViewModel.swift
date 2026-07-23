import Foundation
import Observation

@MainActor
@Observable
final class LiveEditorViewModel {
    private let store: LiveStore
    private let existingEvent: LiveEvent?

    let pendingImport: PendingShareImport?
    var artistName: String
    var title: String
    var eventDate: Date?
    var hasStartTime: Bool
    var startTime: Date
    var venue: String
    var address: String
    var latitude: Double?
    var longitude: Double?
    var ticketURLString: String
    var sourceURLString: String
    var notes: String
    var status: LiveStatus
    var coverImageData: Data?
    var removesExistingCover = false
    var errorMessage: String?
    var importWarning: String?
    var isRetryingMetadata = false
    var isSaving = false

    init(
        store: LiveStore,
        event: LiveEvent? = nil,
        pendingImport: PendingShareImport? = nil,
        pendingImageData: Data? = nil
    ) {
        self.store = store
        existingEvent = event
        self.pendingImport = pendingImport
        artistName = event?.artistName ?? pendingImport?.authorName ?? ""
        title = event?.title ?? ""
        eventDate = event?.eventDate
        hasStartTime = event?.startTime != nil
        startTime = event?.startTime ?? .now
        venue = event?.venue ?? ""
        address = event?.address ?? ""
        latitude = event?.latitude
        longitude = event?.longitude
        ticketURLString = event?.ticketURLString ?? ""
        sourceURLString = event?.sourceURLString ?? pendingImport?.sourceURL.absoluteString ?? ""
        notes = event?.notes ?? pendingImport?.postText ?? ""
        status = event?.status ?? .planned
        coverImageData = pendingImageData
        importWarning = pendingImport?.warning
    }

    var isEditing: Bool { existingEvent != nil }
    var existingCoverPath: String? { existingEvent?.coverImagePath }
    var validationMessages: [String] {
        var messages: [String] = []
        if artistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append(String(localized: "validation.artist_required"))
        }
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append(String(localized: "validation.title_required"))
        }
        if eventDate == nil {
            messages.append(String(localized: "validation.date_required"))
        }
        if !ticketURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           LiveEvent.validHTTPURL(ticketURLString) == nil {
            messages.append(String(localized: "validation.ticket_url"))
        }
        if !sourceURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           LiveEvent.validHTTPURL(sourceURLString) == nil {
            messages.append(String(localized: "validation.source_url"))
        }
        return messages
    }

    var canSave: Bool { validationMessages.isEmpty && !isSaving }

    func selectVenue(_ selection: VenueSelection) {
        venue = selection.name
        address = selection.address
        latitude = selection.latitude
        longitude = selection.longitude
    }

    func clearVenue() {
        venue = ""
        address = ""
        latitude = nil
        longitude = nil
    }

    func retryImportMetadata() async {
        guard let pendingImport else { return }
        isRetryingMetadata = true
        defer { isRetryingMetadata = false }
        do {
            let metadata = try await XOEmbedClient().fetch(postURL: pendingImport.sourceURL)
            if artistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                artistName = metadata.authorName
            }
            if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                notes = metadata.postText ?? ""
            }
            sourceURLString = metadata.canonicalURL.absoluteString
            importWarning = nil
        } catch {
            importWarning = String(localized: "share.metadata_warning \(error.localizedDescription)")
        }
    }

    @discardableResult
    func save(imageStore: ImageStore) -> LiveEvent? {
        guard canSave, let eventDate else { return nil }
        isSaving = true
        defer { isSaving = false }

        let oldImagePath = existingEvent?.coverImagePath
        var newImagePath: String?
        do {
            if let coverImageData {
                newImagePath = try imageStore.saveJPEG(data: coverImageData)
            }

            let event = existingEvent ?? LiveEvent(
                artistName: artistName.trimmingCharacters(in: .whitespacesAndNewlines),
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                eventDate: eventDate
            )
            event.artistName = artistName.trimmingCharacters(in: .whitespacesAndNewlines)
            event.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            event.eventDate = eventDate
            event.startTime = hasStartTime ? startTime : nil
            event.venue = venue.trimmingCharacters(in: .whitespacesAndNewlines)
            event.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
            event.latitude = latitude
            event.longitude = longitude
            event.ticketURLString = ticketURLString.trimmingCharacters(in: .whitespacesAndNewlines)
            event.sourceURLString = sourceURLString.trimmingCharacters(in: .whitespacesAndNewlines)
            event.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            event.status = status
            event.updatedAt = .now
            if let newImagePath {
                event.coverImagePath = newImagePath
            } else if removesExistingCover {
                event.coverImagePath = nil
            }

            if existingEvent == nil { try store.insert(event) } else { try store.save() }

            if oldImagePath != event.coverImagePath {
                try? imageStore.remove(relativePath: oldImagePath)
            }
            errorMessage = nil
            return event
        } catch {
            store.rollback()
            try? imageStore.remove(relativePath: newImagePath)
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
