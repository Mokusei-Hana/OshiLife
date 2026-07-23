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
    var hasOpenTime: Bool
    var openTime: Date
    var hasStartTime: Bool
    var startTime: Date
    var performersText: String
    var ticketOptions: [TicketOption]
    var selectedTicketID: UUID?
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
        let importedDetails = pendingImport?.eventDetails
        artistName = event?.artistName
            ?? (importedDetails?.performers.isEmpty == false ? importedDetails?.performers.joined(separator: " / ") : nil)
            ?? pendingImport?.authorName
            ?? ""
        title = event?.title ?? importedDetails?.title ?? ""
        eventDate = event?.eventDate ?? importedDetails?.date
        hasOpenTime = event?.openTime != nil || importedDetails?.openTime != nil
        openTime = event?.openTime ?? importedDetails?.openTime ?? .now
        hasStartTime = event?.startTime != nil || importedDetails?.startTime != nil
        startTime = event?.startTime ?? importedDetails?.startTime ?? .now
        performersText = event?.performers.joined(separator: " / ")
            ?? importedDetails?.performers.joined(separator: " / ")
            ?? ""
        ticketOptions = event?.ticketOptions ?? importedDetails?.ticketOptions ?? []
        selectedTicketID = event?.selectedTicketID
        venue = event?.venue ?? importedDetails?.venue ?? ""
        address = event?.address ?? ""
        latitude = event?.latitude
        longitude = event?.longitude
        ticketURLString = event?.ticketURLString ?? importedDetails?.linkedURL.absoluteString ?? ""
        sourceURLString = event?.sourceURLString ?? pendingImport?.sourceURL.absoluteString ?? ""
        notes = event?.notes ?? Self.importNotes(from: pendingImport)
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
            let draft = try await XImportDraftBuilder().makeDraft(from: pendingImport.sourceURL)
            if artistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if draft.eventDetails?.performers.isEmpty == false {
                    artistName = draft.eventDetails?.performers.joined(separator: " / ") ?? ""
                } else {
                    artistName = draft.authorName ?? ""
                }
            }
            if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { title = draft.eventDetails?.title ?? "" }
            if eventDate == nil { eventDate = draft.eventDetails?.date }
            if venue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { venue = draft.eventDetails?.venue ?? "" }
            if !hasOpenTime, let importedOpen = draft.eventDetails?.openTime {
                openTime = importedOpen
                hasOpenTime = true
            }
            if !hasStartTime, let importedStart = draft.eventDetails?.startTime {
                startTime = importedStart
                hasStartTime = true
            }
            if ticketURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ticketURLString = draft.eventDetails?.linkedURL.absoluteString ?? ""
            }
            if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                notes = Self.importNotes(from: draft)
            }
            if ticketOptions.isEmpty {
                ticketOptions = draft.eventDetails?.ticketOptions ?? []
            }
            if performersText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                performersText = draft.eventDetails?.performers.joined(separator: " / ") ?? ""
            }
            sourceURLString = draft.sourceURL.absoluteString
            importWarning = draft.warning
        } catch {
            importWarning = String(localized: "share.metadata_warning \(error.localizedDescription)")
        }
    }

    private static func importNotes(from pending: PendingShareImport?) -> String {
        guard let pending else { return "" }
        var sections = [pending.postText].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if let openTime = pending.eventDetails?.openTime {
            sections.append("OPEN \(openTime.formatted(date: .omitted, time: .shortened))")
        }
        if let ticketInformation = pending.eventDetails?.ticketInformation,
           !ticketInformation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sections.append(ticketInformation)
        }
        return sections.joined(separator: "\n\n")
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
            event.openTime = hasOpenTime ? openTime : nil
            event.startTime = hasStartTime ? startTime : nil
            event.performers = performersText
                .split(whereSeparator: { $0 == "/" || $0 == "／" || $0 == "、" || $0 == "," })
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            event.venue = venue.trimmingCharacters(in: .whitespacesAndNewlines)
            event.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
            event.latitude = latitude
            event.longitude = longitude
            event.ticketURLString = ticketURLString.trimmingCharacters(in: .whitespacesAndNewlines)
            event.sourceURLString = sourceURLString.trimmingCharacters(in: .whitespacesAndNewlines)
            event.ticketOptions = ticketOptions
            event.selectedTicketID = selectedTicketID
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
