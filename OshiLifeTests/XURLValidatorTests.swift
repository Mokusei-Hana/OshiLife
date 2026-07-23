import Foundation
import XCTest
@testable import OshiLife

final class XURLValidatorTests: XCTestCase {
    func testNormalizesXAndLegacyTwitterURLs() throws {
        let xURL = try XCTUnwrap(URL(string: "https://x.com/example/status/123456?ref_src=test#fragment"))
        XCTAssertEqual(
            XURLValidator.normalizedPostURL(from: xURL)?.absoluteString,
            "https://x.com/example/status/123456"
        )

        let twitterURL = try XCTUnwrap(URL(string: "https://mobile.twitter.com/example/status/987"))
        XCTAssertEqual(
            XURLValidator.normalizedPostURL(from: twitterURL)?.absoluteString,
            "https://x.com/example/status/987"
        )
    }

    func testRejectsUnsupportedOrNonStatusURLs() throws {
        XCTAssertNil(XURLValidator.normalizedPostURL(from: try XCTUnwrap(URL(string: "http://x.com/a/status/1"))))
        XCTAssertNil(XURLValidator.normalizedPostURL(from: try XCTUnwrap(URL(string: "https://example.com/a/status/1"))))
        XCTAssertNil(XURLValidator.normalizedPostURL(from: try XCTUnwrap(URL(string: "https://x.com/a/photo/1"))))
        XCTAssertNil(XURLValidator.normalizedPostURL(from: try XCTUnwrap(URL(string: "https://x.com/a/status/not-a-number"))))
        XCTAssertNil(XURLValidator.normalizedPostURL(from: try XCTUnwrap(URL(string: "https://x.com/a/status/１２３"))))
    }

    func testExtractsFirstValidURLFromText() {
        let text = "こちら https://example.com/nope と https://twitter.com/oshi/status/42?s=20"
        XCTAssertEqual(XURLValidator.firstPostURL(in: text)?.absoluteString, "https://x.com/oshi/status/42")
    }

    func testNormalizesPastedURLTextAndRejectsInvalidText() {
        XCTAssertEqual(
            XURLValidator.normalizedPostURL(from: "  https://www.twitter.com/oshi/status/42?s=20\n")?.absoluteString,
            "https://x.com/oshi/status/42"
        )
        XCTAssertNil(XURLValidator.normalizedPostURL(from: "not a URL"))
        XCTAssertNil(XURLValidator.normalizedPostURL(from: "https://x.com/oshi"))
    }
}
