import Foundation

/// A selectable day in a multi-day event (e.g. DAY1, DAY2, DAY3).
///
/// When imported event data describes several schedules, the user can pick
/// which day they plan to attend. Selecting a day updates the event date,
/// open/start times, and performers in the editor.
struct EventScheduleOption: Codable, Hashable, Sendable, Identifiable {
    /// Stable identity for use as `ForEach` / `Picker` tag.
    var id: UUID
    /// Human-readable label shown in the selector, e.g. "DAY1".
    var dayLabel: String
    /// The calendar date for this day.
    var date: Date
    /// Doors-open time for this day, if available.
    var openTime: Date?
    /// Show-start time for this day, if available.
    var startTime: Date?
    /// Performers appearing on this day, if the page listed a lineup.
    var performers: [String]

    init(
        id: UUID = UUID(),
        dayLabel: String,
        date: Date,
        openTime: Date? = nil,
        startTime: Date? = nil,
        performers: [String] = []
    ) {
        self.id = id
        self.dayLabel = dayLabel
        self.date = date
        self.openTime = openTime
        self.startTime = startTime
        self.performers = performers
    }
}
