import Foundation
import XCTest
@testable import OshiLife

@MainActor
final class LiveListViewModelTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    func testUpcomingEventsKeepsFuturePlannedSortedAscending() {
        let later = LiveEvent(artistName: "A", title: "Later", eventDate: now.addingTimeInterval(172_800))
        let sooner = LiveEvent(artistName: "A", title: "Sooner", eventDate: now.addingTimeInterval(86_400))
        let past = LiveEvent(artistName: "A", title: "Past", eventDate: now.addingTimeInterval(-86_400))
        let attended = LiveEvent(
            artistName: "A",
            title: "Attended",
            eventDate: now.addingTimeInterval(86_400),
            status: .attended
        )
        let cancelled = LiveEvent(
            artistName: "A",
            title: "Cancelled",
            eventDate: now.addingTimeInterval(86_400),
            status: .cancelled
        )

        let upcoming = LiveListViewModel.upcomingEvents(
            in: [later, sooner, past, attended, cancelled],
            now: now
        )

        XCTAssertEqual(upcoming.map(\.title), ["Sooner", "Later"])
    }

    func testHistoricalEventsKeepsAttendedSortedDescending() {
        let older = LiveEvent(
            artistName: "A",
            title: "Older",
            eventDate: now.addingTimeInterval(-172_800),
            status: .attended
        )
        let newer = LiveEvent(
            artistName: "A",
            title: "Newer",
            eventDate: now.addingTimeInterval(-86_400),
            status: .attended
        )
        let planned = LiveEvent(artistName: "A", title: "Planned", eventDate: now.addingTimeInterval(86_400))

        let history = LiveListViewModel.historicalEvents(in: [older, planned, newer])

        XCTAssertEqual(history.map(\.title), ["Newer", "Older"])
    }
}
