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

    func testArtworkExtractionUsesFallbackWithoutImage() {
        let fallback = AccentColorValue(red: 0.2, green: 0.4, blue: 0.6)

        let extracted = ArtworkAccentColorExtractor.extract(from: nil, fallback: fallback)

        XCTAssertEqual(extracted, fallback)
    }
}
