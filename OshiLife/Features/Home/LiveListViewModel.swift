import Foundation
import Observation

@MainActor
@Observable
final class LiveListViewModel {
    enum StatusFilter: String, CaseIterable, Identifiable {
        case all
        case planned
        case attended
        case cancelled

        var id: String { rawValue }

        var title: LocalizedStringResource {
            switch self {
            case .all: "filter.all"
            case .planned: "status.planned"
            case .attended: "status.attended"
            case .cancelled: "status.cancelled"
            }
        }

        var status: LiveStatus? { self == .all ? nil : LiveStatus(rawValue: rawValue) }
    }

    private let store: LiveStore
    private let settings: AppSettings
    var events: [LiveEvent] = []
    var filter: StatusFilter = .all
    var errorMessage: String?
    var isLoading = false

    init(store: LiveStore, settings: AppSettings) {
        self.store = store
        self.settings = settings
    }

    var filteredEvents: [LiveEvent] {
        let statusFiltered = filter.status.map { status in
            events.filter { $0.status == status }
        } ?? events
        guard !settings.selectedPerformerFilters.isEmpty else {
            return statusFiltered
        }
        return statusFiltered.filter {
            !Set($0.performers).isDisjoint(with: settings.selectedPerformerFilters)
        }
    }

    var availablePerformers: [String] {
        PerformerCatalog.namesByUsage(in: events)
    }

    var selectedPerformers: Set<String> {
        settings.selectedPerformerFilters
    }

    func togglePerformer(_ performer: String) {
        if settings.selectedPerformerFilters.contains(performer) {
            settings.selectedPerformerFilters.remove(performer)
        } else {
            settings.selectedPerformerFilters.insert(performer)
        }
    }

    func clearPerformerFilter() {
        settings.selectedPerformerFilters.removeAll()
    }

    func reloadAfterCreatingEvent() {
        clearPerformerFilter()
        load()
    }

    static func upcomingEvents(
        in events: [LiveEvent],
        now: Date,
        calendar: Calendar = .current
    ) -> [LiveEvent] {
        let today = calendar.startOfDay(for: now)
        return events
            .filter { $0.status == .planned && $0.eventDate >= today }
            .sorted { $0.eventDate < $1.eventDate }
    }

    static func historicalEvents(in events: [LiveEvent]) -> [LiveEvent] {
        events
            .filter { $0.status == .attended }
            .sorted { $0.eventDate > $1.eventDate }
    }

    func load() {
        isLoading = true
        defer { isLoading = false }
        do {
            events = try store.fetchAll()
            let available = Set(availablePerformers)
            settings.selectedPerformerFilters.formIntersection(available)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ event: LiveEvent, imageStore: ImageStore) {
        let imagePath = event.coverImagePath
        do {
            try store.delete(event)
            load()
            do {
                try imageStore.remove(relativePath: imagePath)
            } catch {
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
