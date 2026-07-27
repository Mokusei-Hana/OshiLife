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
    var events: [LiveEvent] = []
    var filter: StatusFilter = .all
    var errorMessage: String?
    var isLoading = false

    init(store: LiveStore) {
        self.store = store
    }

    var filteredEvents: [LiveEvent] {
        guard let status = filter.status else { return events }
        return events.filter { $0.status == status }
    }

    static func upcomingEvents(in events: [LiveEvent], now: Date) -> [LiveEvent] {
        events
            .filter { $0.status == .planned && $0.eventDate > now }
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
