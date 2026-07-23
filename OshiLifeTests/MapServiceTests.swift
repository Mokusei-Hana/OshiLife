import Foundation
import XCTest
@testable import OshiLife

@MainActor
final class MapServiceTests: XCTestCase {
    func testAppleMapsURLUsesPercentEncodedVenueName() throws {
        let url = try MapService.appleMapsURL(venue: "KT Zepp 横浜")
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let queryItems = try XCTUnwrap(components.queryItems)

        XCTAssertEqual(components.scheme, "http")
        XCTAssertEqual(components.host, "maps.apple.com")
        XCTAssertEqual(components.path, "/")
        XCTAssertEqual(queryItems.first(where: { $0.name == "q" })?.value, "KT Zepp 横浜")
        XCTAssertFalse(try XCTUnwrap(components.percentEncodedQuery).contains("横浜"))
    }

    func testGoogleMapsURLUsesPercentEncodedVenueName() throws {
        let url = try MapService.googleMapsURL(venue: "KT Zepp 横浜")
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let queryItems = try XCTUnwrap(components.queryItems)

        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "www.google.com")
        XCTAssertEqual(components.path, "/maps/search/")
        XCTAssertEqual(queryItems.first(where: { $0.name == "api" })?.value, "1")
        XCTAssertEqual(queryItems.first(where: { $0.name == "query" })?.value, "KT Zepp 横浜")
        XCTAssertFalse(try XCTUnwrap(components.percentEncodedQuery).contains("横浜"))
    }

    func testMapURLsRejectEmptyVenueName() {
        XCTAssertThrowsError(try MapService.appleMapsURL(venue: "  \n")) { error in
            XCTAssertEqual(error as? MapServiceError, .emptyVenue)
        }
        XCTAssertThrowsError(try MapService.googleMapsURL(venue: "")) { error in
            XCTAssertEqual(error as? MapServiceError, .emptyVenue)
        }
    }

    func testCoordinateURLCompatibility() throws {
        let url = try MapService.googleMapsURL(latitude: 35.693317, longitude: 139.749885)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let queryItems = try XCTUnwrap(components.queryItems)

        XCTAssertEqual(
            queryItems.first(where: { $0.name == "query" })?.value,
            "35.693317,139.749885"
        )
        XCTAssertTrue(MapService.hasValidCoordinates(latitude: 35, longitude: 139))
        XCTAssertFalse(MapService.hasValidCoordinates(latitude: 91, longitude: 139))
    }
}
