import Foundation
import XCTest
@testable import OshiLife

final class FXTwitterClientTests: XCTestCase {
    func testExtractsOnlyUniquePhotoMediaInOrder() throws {
        let first = try XCTUnwrap(URL(string: "https://pbs.twimg.com/media/first.jpg"))
        let second = try XCTUnwrap(URL(string: "https://pbs.twimg.com/media/second.jpg"))
        let response = FXTwitterResponse(
            code: 200,
            tweet: FXTwitterTweet(
                url: URL(string: "https://x.com/oshi/status/42"),
                media: FXTwitterMedia(all: [
                    FXTwitterMediaItem(type: "photo", url: first),
                    FXTwitterMediaItem(type: "video", url: second),
                    FXTwitterMediaItem(type: "photo", url: first),
                    FXTwitterMediaItem(type: "photo", url: second)
                ])
            )
        )

        XCTAssertEqual(FXTwitterClient.imageURLs(in: response), [first, second])
    }

    func testMissingMediaProducesNoImageURLs() throws {
        let response = FXTwitterResponse(
            code: 200,
            tweet: FXTwitterTweet(url: nil, media: nil)
        )

        XCTAssertTrue(FXTwitterClient.imageURLs(in: response).isEmpty)
    }
}
