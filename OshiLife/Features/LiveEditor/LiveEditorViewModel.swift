import Foundation
import Observation

private struct EditableSchedule {
    var date: Date
    var openTime: Date?
    var startTime: Date?
    var performers: [String]
}

@MainActor
@Observable
final class LiveEditorViewModel {
    private let store: LiveStore
    private let existingEvent: LiveEvent?

    let pendingImport: PendingShareImport?
    var scheduleOptions: [EventScheduleOption]
    var selectedScheduleOptionIDs: Set<UUID>
    var activeScheduleOptionID: UUID?
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
    private var scheduleDrafts: [UUID: EditableSchedule]
    private var scheduleEvents: [UUID: LiveEvent]
    private var scheduleGroupID: UUID?
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
        let persistedScheduleOptions = event?.scheduleOptions ?? []
        let importedScheduleOptions = importedDetails?.scheduleOptions ?? []
        let resolvedScheduleOptions = persistedScheduleOptions.isEmpty
            ? importedScheduleOptions
            : persistedScheduleOptions
        scheduleOptions = resolvedScheduleOptions
        scheduleGroupID = event?.scheduleGroupID
            ?? (resolvedScheduleOptions.count > 1 ? UUID() : nil)

        let groupedEvents: [LiveEvent]
        if let groupID = event?.scheduleGroupID {
            groupedEvents = (try? store.events(scheduleGroupID: groupID)) ?? [event].compactMap { $0 }
        } else {
            groupedEvents = [event].compactMap { $0 }
        }
        scheduleEvents = groupedEvents.reduce(into: [:]) { result, groupedEvent in
            guard let optionID = groupedEvent.scheduleOptionID else { return }
            result[optionID] = groupedEvent
        }
        selectedScheduleOptionIDs = Set(scheduleEvents.keys)
        if event == nil, let firstScheduleID = resolvedScheduleOptions.first?.id {
            selectedScheduleOptionIDs.insert(firstScheduleID)
        }
        activeScheduleOptionID = event?.scheduleOptionID
            ?? selectedScheduleOptionIDs.first
            ?? resolvedScheduleOptions.first?.id

        var resolvedDrafts = Dictionary(
            uniqueKeysWithValues: resolvedScheduleOptions.map { option in
                (
                    option.id,
                    EditableSchedule(
                        date: option.date,
                        openTime: option.openTime,
                        startTime: option.startTime,
                        performers: []
                    )
                )
            }
        )
        for groupedEvent in groupedEvents {
            guard let optionID = groupedEvent.scheduleOptionID else { continue }
            resolvedDrafts[optionID] = EditableSchedule(
                date: groupedEvent.eventDate,
                openTime: groupedEvent.openTime,
                startTime: groupedEvent.startTime,
                performers: groupedEvent.performers
            )
        }
        scheduleDrafts = resolvedDrafts

        let activeDraft = activeScheduleOptionID.flatMap { resolvedDrafts[$0] }
        artistName = event?.artistName
            ?? (importedDetails?.performers.isEmpty == false ? importedDetails?.performers.joined(separator: " / ") : nil)
            ?? pendingImport?.authorName
            ?? ""
        title = event?.title ?? importedDetails?.title ?? ""
        eventDate = activeDraft?.date ?? event?.eventDate ?? importedDetails?.date
        hasOpenTime = activeDraft?.openTime != nil || event?.openTime != nil || importedDetails?.openTime != nil
        openTime = activeDraft?.openTime ?? event?.openTime ?? importedDetails?.openTime ?? .now
        hasStartTime = activeDraft?.startTime != nil || event?.startTime != nil || importedDetails?.startTime != nil
        startTime = activeDraft?.startTime ?? event?.startTime ?? importedDetails?.startTime ?? .now
        performers = Self.normalizedPerformers(activeDraft?.performers ?? event?.performers ?? [])
        importedPerformerSuggestions = Self.normalizedPerformers(
            event?.performerCandidates ?? importedDetails?.performers ?? []
        )
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
        let activeScheduleCandidates = activeScheduleOptionID
            .flatMap { activeID in scheduleOptions.first { $0.id == activeID } }
            .map(\.performers)
            ?? []
        let scheduleCandidates = activeScheduleCandidates.isEmpty
            ? importedPerformerSuggestions
            : activeScheduleCandidates
        return Self.normalizedPerformers(
            performers + scheduleCandidates + savedPerformerSuggestions
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
        if scheduleOptions.count > 1, selectedScheduleOptionIDs.isEmpty {
            messages.append(String(localized: "validation.schedule_required"))
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

    func selectScheduleDay(_ option: EventScheduleOption) {
        storeActiveScheduleDraft()
        selectedScheduleOptionIDs.insert(option.id)
        activeScheduleOptionID = option.id
        applyScheduleDraft(optionID: option.id)
    }

    func setScheduleParticipation(_ option: EventScheduleOption, isSelected: Bool) {
        storeActiveScheduleDraft()
        if isSelected {
            selectedScheduleOptionIDs.insert(option.id)
            activeScheduleOptionID = option.id
            applyScheduleDraft(optionID: option.id)
            return
        }

        selectedScheduleOptionIDs.remove(option.id)
        guard activeScheduleOptionID == option.id else { return }
        activeScheduleOptionID = scheduleOptions.first {
            selectedScheduleOptionIDs.contains($0.id)
        }?.id
        if let activeScheduleOptionID {
            applyScheduleDraft(optionID: activeScheduleOptionID)
        } else {
            performers = []
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
                if scheduleOptions.isEmpty, !imported.scheduleOptions.isEmpty {
                    scheduleOptions = imported.scheduleOptions
                    scheduleGroupID = imported.scheduleOptions.count > 1 ? UUID() : nil
                    for option in imported.scheduleOptions {
                        scheduleDrafts[option.id] = EditableSchedule(
                            date: option.date,
                            openTime: option.openTime,
                            startTime: option.startTime,
                            performers: []
                        )
                    }
                    if let first = imported.scheduleOptions.first {
                        selectedScheduleOptionIDs = [first.id]
                        activeScheduleOptionID = first.id
                        applyScheduleDraft(optionID: first.id)
                    }
                }
                importedPerformerSuggestions = Self.normalizedPerformers(
                    importedPerformerSuggestions + imported.performers
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

        storeActiveScheduleDraft()
        let oldImagePath = existingEvent?.coverImagePath
        var newImagePath: String?
        do {
            if let coverImageData {
                newImagePath = try imageStore.saveJPEG(data: coverImageData)
            }

            let event: LiveEvent
            if scheduleOptions.count > 1 {
                event = try saveScheduleGroup(newImagePath: newImagePath)
            } else {
                event = existingEvent ?? LiveEvent(
                    artistName: artistName.trimmingCharacters(in: .whitespacesAndNewlines),
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    eventDate: eventDate
                )
                applyCommonFields(to: event)
                event.eventDate = eventDate
                event.openTime = hasOpenTime ? openTime : nil
                event.startTime = hasStartTime ? startTime : nil
                event.performers = performers
                event.performerCandidates = importedPerformerSuggestions
                event.scheduleGroupID = nil
                event.scheduleOptionID = nil
                event.scheduleLabel = ""
                event.scheduleOptions = []
                applyCoverChange(to: event, newImagePath: newImagePath)

                if existingEvent == nil {
                    try store.insert(event)
                } else {
                    try store.save()
                }
            }

            if oldImagePath != event.coverImagePath,
               try !store.isCoverImageReferenced(oldImagePath) {
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

    private func saveScheduleGroup(newImagePath: String?) throws -> LiveEvent {
        let groupID = scheduleGroupID ?? UUID()
        scheduleGroupID = groupID
        let activeID = activeScheduleOptionID
            ?? scheduleOptions.first { selectedScheduleOptionIDs.contains($0.id) }?.id
        var insertedEvents: [LiveEvent] = []
        var savedEvents: [UUID: LiveEvent] = [:]

        for option in scheduleOptions where selectedScheduleOptionIDs.contains(option.id) {
            let draft = scheduleDrafts[option.id] ?? EditableSchedule(
                date: option.date,
                openTime: option.openTime,
                startTime: option.startTime,
                performers: []
            )
            let isNewEvent = scheduleEvents[option.id] == nil
            let event = scheduleEvents[option.id] ?? LiveEvent(
                artistName: artistName.trimmingCharacters(in: .whitespacesAndNewlines),
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                eventDate: draft.date
            )

            if isNewEvent || option.id == activeID {
                applyCommonFields(to: event)
            }
            event.eventDate = draft.date
            event.openTime = draft.openTime
            event.startTime = draft.startTime
            event.performers = draft.performers
            event.performerCandidates = option.performers
            event.scheduleGroupID = groupID
            event.scheduleOptionID = option.id
            event.scheduleLabel = option.dayLabel
            event.scheduleOptions = scheduleOptions

            if isNewEvent {
                event.coverImagePath = newImagePath ?? existingEvent?.coverImagePath
                insertedEvents.append(event)
            } else if option.id == activeID {
                applyCoverChange(to: event, newImagePath: newImagePath)
            }
            savedEvents[option.id] = event
        }

        let removedEvents = scheduleEvents.compactMap { optionID, event in
            selectedScheduleOptionIDs.contains(optionID) ? nil : event
        }
        try store.save(inserting: insertedEvents, deleting: removedEvents)
        scheduleEvents = savedEvents

        guard let result = activeID.flatMap({ savedEvents[$0] }) ?? savedEvents.values.first else {
            throw LiveEditorSaveError.missingSelectedSchedule
        }
        return result
    }

    private func applyCommonFields(to event: LiveEvent) {
        event.artistName = artistName.trimmingCharacters(in: .whitespacesAndNewlines)
        event.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
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
    }

    private func applyCoverChange(to event: LiveEvent, newImagePath: String?) {
        if let newImagePath {
            event.coverImagePath = newImagePath
        } else if removesExistingCover {
            event.coverImagePath = nil
        }
    }

    private func storeActiveScheduleDraft() {
        guard let activeScheduleOptionID, let eventDate else { return }
        scheduleDrafts[activeScheduleOptionID] = EditableSchedule(
            date: eventDate,
            openTime: hasOpenTime ? openTime : nil,
            startTime: hasStartTime ? startTime : nil,
            performers: performers
        )
    }

    private func applyScheduleDraft(optionID: UUID) {
        guard let draft = scheduleDrafts[optionID] else { return }
        eventDate = draft.date
        hasOpenTime = draft.openTime != nil
        openTime = draft.openTime ?? .now
        hasStartTime = draft.startTime != nil
        startTime = draft.startTime ?? .now
        performers = draft.performers
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

private enum LiveEditorSaveError: LocalizedError {
    case missingSelectedSchedule

    var errorDescription: String? {
        String(localized: "validation.schedule_required")
    }
}
