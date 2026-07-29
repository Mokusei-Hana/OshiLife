import Foundation
import Observation

@MainActor
@Observable
final class LiveEditorViewModel {
    private let store: LiveStore
    private let existingEvent: LiveEvent?

    let pendingImport: PendingShareImport?
    /// Selectable days when the imported event lists multiple schedules.
    /// Empty for single-day events; the UI only shows the picker when > 1.
    let scheduleOptions: [EventScheduleOption]
    var artistName: String
    var title: String
    var eventDate: Date?
    var hasOpenTime: Bool
    var openTime: Date
    var hasStartTime: Bool
    var startTime: Date
    var performers: [String]
    private var importedPerformerSuggestions: [String]
    private let savedPerformerSuggestions: [String]
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
        let importedPerformers = Self.normalizedPerformers(
            (importedDetails?.performers ?? [])
                + (importedDetails?.scheduleOptions.flatMap(\.performers) ?? [])
        )
        scheduleOptions = importedDetails?.scheduleOptions ?? []
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
        performers = Self.normalizedPerformers(event?.performers ?? [])
        importedPerformerSuggestions = event == nil ? importedPerformers : []
        savedPerformerSuggestions = PerformerCatalog.namesByUsage(in: (try? store.fetchAll()) ?? [])
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
    var performerSuggestions: [String] {
        Self.normalizedPerformers(
            performers + importedPerformerSuggestions + savedPerformerSuggestions
        )
    }
    var performersText: String {
        get { performers.joined(separator: " / ") }
        set {
            performers = Self.normalizedPerformers(
                newValue.split(whereSeparator: { $0 == "/" || $0 == "／" }).map(String.init)
            )
        }
    }
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

    @discardableResult
    func addPerformer(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !performers.contains(where: { $0.localizedCaseInsensitiveCompare(trimmed) == .orderedSame })
        else { return false }
        performers.append(trimmed)
        return true
    }

    func removePerformer(_ performer: String) {
        performers.removeAll { $0 == performer }
    }

    /// Applies the chosen schedule option to the editor fields.
    ///
    /// Existing manual edits to fields not covered by a day option are left
    /// untouched. Call this whenever the user picks a different day.
    func selectScheduleDay(_ option: EventScheduleOption) {
        eventDate = option.date
        if let open = option.openTime {
            openTime = open
            hasOpenTime = true
        }
        if let start = option.startTime {
            startTime = start
            hasStartTime = true
        }
        if !option.performers.isEmpty {
            artistName = Self.normalizedPerformers(option.performers).joined(separator: " / ")
        }
    }

    @discardableResult
    func addTicketOption(name: String, price: Int?, description: String?) -> TicketOption? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }
        let trimmedDescription = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        let option = TicketOption(
            name: trimmedName,
            price: price,
            description: trimmedDescription?.isEmpty == false ? trimmedDescription : nil
        )
        ticketOptions.append(option)
        return option
    }

    func removeTicketOptions(at offsets: IndexSet) {
        let removedIDs = Set(offsets.compactMap { ticketOptions.indices.contains($0) ? ticketOptions[$0].id : nil })
        ticketOptions.remove(atOffsets: offsets)
        if let selectedTicketID, removedIDs.contains(selectedTicketID) {
            self.selectedTicketID = nil
        }
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
            if let imported = draft.eventDetails {
                importedPerformerSuggestions = Self.normalizedPerformers(
                    importedPerformerSuggestions
                        + imported.performers
                        + imported.scheduleOptions.flatMap(\.performers)
                )
            }
            if coverImageData == nil {
                coverImageData = draft.imageData
            }
            sourceURLString = draft.sourceURL.absoluteString
            importWarning = draft.warning
        } catch {
            importWarning = String(localized: "share.metadata_warning \(error.localizedDescription)")
        }
    }

    private static func importNotes(from pending: PendingShareImport?) -> String {
        guard let pending else { return "" }
        // Media placeholders and URLs already stored in structured fields are
        // noise in Notes; the announcement text itself is kept.
        var storedURLs = [pending.sourceURL]
        if let details = pending.eventDetails {
            storedURLs.append(details.linkedURL)
            storedURLs.append(contentsOf: details.shortenedLinkURLs)
        }
        var sections = [pending.postText.map { XPostNotesCleaner.cleanedNotes($0, removing: storedURLs) }]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        // The event model stores a single day, so a multi-day range is kept
        // in the notes instead of being dropped.
        if let start = pending.eventDetails?.date, let end = pending.eventDetails?.endDate {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
            formatter.dateFormat = "yyyy/M/d"
            sections.append("日程: \(formatter.string(from: start)) 〜 \(formatter.string(from: end))")
        }
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
            event.performers = performers
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

    private static func normalizedPerformers(_ performers: [String]) -> [String] {
        performers.reduce(into: []) { result, performer in
            let trimmed = performer.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty,
                  !result.contains(where: { $0.localizedCaseInsensitiveCompare(trimmed) == .orderedSame })
            else { return }
            result.append(trimmed)
        }
    }

}
