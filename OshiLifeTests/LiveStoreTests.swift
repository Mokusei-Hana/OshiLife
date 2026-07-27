import Foundation
import XCTest
@testable import OshiLife

@MainActor
final class LiveStoreTests: XCTestCase {
    func testCRUDAndUpcomingThenHistoryOrdering() throws {
        let container = try ModelContainerFactory.makeInMemory()
        let store = LiveStore(container: container)
        let calendar = Calendar(identifier: .gregorian)
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let past = LiveEvent(artistName: "A", title: "Past", eventDate: now.addingTimeInterval(-86_400))
        let later = LiveEvent(artistName: "A", title: "Later", eventDate: now.addingTimeInterval(172_800))
        let sooner = LiveEvent(artistName: "A", title: "Sooner", eventDate: now.addingTimeInterval(86_400))

        try store.insert(past)
        try store.insert(later)
        try store.insert(sooner)

        XCTAssertEqual(try store.fetchAll(now: now, calendar: calendar).map(\.title), ["Sooner", "Later", "Past"])
        XCTAssertEqual(try store.event(id: later.id)?.title, "Later")

        try store.delete(later)
        XCTAssertNil(try store.event(id: later.id))
    }

    func testHTTPURLValidation() {
        XCTAssertNotNil(LiveEvent.validHTTPURL("https://example.com/ticket"))
        XCTAssertNotNil(LiveEvent.validHTTPURL(" http://example.com "))
        XCTAssertNil(LiveEvent.validHTTPURL("javascript:alert(1)"))
        XCTAssertNil(LiveEvent.validHTTPURL("not a url"))
    }

    func testPersistsVenueCoordinates() throws {
        let container = try ModelContainerFactory.makeInMemory()
        let store = LiveStore(container: container)
        let event = LiveEvent(
            artistName: "A",
            title: "Coordinate",
            eventDate: .now,
            venue: "Venue",
            address: "Address",
            latitude: 35.0,
            longitude: 139.0
        )

        try store.insert(event)
        let fetched = try XCTUnwrap(store.event(id: event.id))

        XCTAssertEqual(fetched.latitude, 35.0)
        XCTAssertEqual(fetched.longitude, 139.0)
    }
}
