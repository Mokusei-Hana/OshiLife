import Foundation
import XCTest
@testable import OshiLife

final class EventCountdownFormatterTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    func testMinutesOnly() {
        XCTAssertEqual(
            EventCountdownFormatter.shortText(until: now.addingTimeInterval(45 * 60), now: now),
            "45m"
        )
    }

    func testHoursAndMinutes() {
        XCTAssertEqual(
            EventCountdownFormatter.shortText(until: now.addingTimeInterval(3 * 3_600 + 12 * 60), now: now),
            "3h 12m"
        )
    }

    func testDaysAndHours() {
        XCTAssertEqual(
            EventCountdownFormatter.shortText(until: now.addingTimeInterval(2 * 86_400 + 5 * 3_600 + 59 * 60), now: now),
            "2d 5h"
        )
    }

    func testPastDatesClampToZeroMinutes() {
        XCTAssertEqual(
            EventCountdownFormatter.shortText(until: now.addingTimeInterval(-3_600), now: now),
            "0m"
        )
    }
}
