import Foundation
import XCTest
@testable import OshiLife

@MainActor
final class MapServiceTests: XCTestCase {
    func testGoogleMapsURLUsesStoredCoordinates() throws {
        let url = try MapService.googleMapsURL(latitude: 35.693317, longitude: 139.749885)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let queryItems = try XCTUnwrap(components.queryItems)

        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "www.google.com")
        XCTAssertEqual(components.path, "/maps/search/")
        XCTAssertEqual(queryItems.first(where: { $0.name == "api" })?.value, "1")
        XCTAssertEqual(
            queryItems.first(where: { $0.name == "query" })?.value,
            "35.693317,139.749885"
        )
    }

    func testCoordinateValidationRejectsMissingAndOutOfRangeValues() {
        XCTAssertFalse(MapService.hasValidCoordinates(latitude: nil, longitude: 139))
        XCTAssertFalse(MapService.hasValidCoordinates(latitude: 91, longitude: 139))
        XCTAssertFalse(MapService.hasValidCoordinates(latitude: 35, longitude: -181))
        XCTAssertTrue(MapService.hasValidCoordinates(latitude: 35, longitude: 139))

        XCTAssertThrowsError(try MapService.googleMapsURL(latitude: nil, longitude: 139)) { error in
            XCTAssertEqual(error as? MapServiceError, .missingCoordinates)
        }
    }
}
