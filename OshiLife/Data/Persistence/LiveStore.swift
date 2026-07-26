import Foundation
import SwiftData

@MainActor
final class LiveStore {
    private let context: ModelContext

    init(container: ModelContainer) {
        context = container.mainContext
        context.autosaveEnabled = false
    }

    func fetchAll(now: Date = .now, calendar: Calendar = .current) throws -> [LiveEvent] {
        let descriptor = FetchDescriptor<LiveEvent>()
        let events = try context.fetch(descriptor)
        let today = calendar.startOfDay(for: now)
        return events.sorted { lhs, rhs in
            let lhsUpcoming = lhs.eventDate >= today
            let rhsUpcoming = rhs.eventDate >= today
            if lhsUpcoming != rhsUpcoming { return lhsUpcoming }
            if lhsUpcoming { return lhs.eventDate < rhs.eventDate }
            return lhs.eventDate > rhs.eventDate
        }
    }

    func event(id: UUID) throws -> LiveEvent? {
        let descriptor = FetchDescriptor<LiveEvent>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }

    func event(sourceURLString: String) throws -> LiveEvent? {
        guard !sourceURLString.isEmpty else { return nil }
        let descriptor = FetchDescriptor<LiveEvent>(predicate: #Predicate { $0.sourceURLString == sourceURLString })
        return try context.fetch(descriptor).first
    }

    func insert(_ event: LiveEvent) throws {
        context.insert(event)
        try context.save()
    }

    func save() throws {
        try context.save()
    }

    func delete(_ event: LiveEvent) throws {
        context.delete(event)
        try context.save()
    }

    func rollback() {
        context.rollback()
    }
}
