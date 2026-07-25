import UIKit
import XCTest
@testable import OshiLife

final class ThemeSystemTests: XCTestCase {
    func testCustomColorEncodingRoundTrip() throws {
        let color = AccentColorValue(red: 0.12, green: 0.34, blue: 0.56, alpha: 0.78)

        let data = try JSONEncoder().encode(color)
        let decoded = try JSONDecoder().decode(AccentColorValue.self, from: data)

        XCTAssertEqual(decoded, color)
    }

    func testOshiColorEncodingRoundTrip() throws {
        let data = try JSONEncoder().encode(OshiColor.aqua)
        let decoded = try JSONDecoder().decode(OshiColor.self, from: data)

        XCTAssertEqual(decoded, .aqua)
    }

    func testWhiteUsesReadableFallbackInLightMode() {
        let primary = AccentColorValue(
            color: OshiColor.white.primaryColor(for: .light)
        )

        XCTAssertNotEqual(primary, AccentColorValue(red: 1, green: 1, blue: 1))
    }
}
