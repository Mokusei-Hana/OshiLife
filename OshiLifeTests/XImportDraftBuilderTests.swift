import Foundation
import XCTest
@testable import OshiLife

final class XImportDraftBuilderTests: XCTestCase {
    private struct StubClient: XOEmbedFetching {
        var metadata: XOEmbedMetadata?

        func fetch(postURL: URL) async throws -> XOEmbedMetadata {
            guard let metadata else { throw URLError(.notConnectedToInternet) }
            return metadata
        }
    }

    private struct StubEventLinkImporter: EventLinkImporting {
        var details: EventImportDetails?

        func importDetails(from urls: [URL]) async throws -> EventImportDetails? {
            details
        }
    }

    private struct StubFXTwitterClient: FXTwitterFetching {
        var imageURLs: [URL] = []

        func fetch(postURL: URL) async throws -> FXTwitterMetadata {
            FXTwitterMetadata(canonicalURL: postURL, imageURLs: imageURLs)
        }
    }

    private struct StubImageDownloader: RemoteImageDataFetching {
        var dataByURL: [URL: Data] = [:]
        var failingURLs: Set<URL> = []

        func fetchImage(from url: URL) async throws -> Data {
            if failingURLs.contains(url) {
                throw URLError(.cannotLoadFromNetwork)
            }
            guard let data = dataByURL[url] else {
                throw URLError(.fileDoesNotExist)
            }
            return data
        }
    }

    private func builder(
        client: any XOEmbedFetching,
        eventLinkImporter: any EventLinkImporting = StubEventLinkImporter(details: nil),
        imageURLs: [URL] = [],
        imageData: [URL: Data] = [:],
        failingImageURLs: Set<URL> = []
    ) -> XImportDraftBuilder {
        XImportDraftBuilder(
            client: client,
            eventLinkImporter: eventLinkImporter,
            fxTwitterClient: StubFXTwitterClient(imageURLs: imageURLs),
            imageDownloader: StubImageDownloader(dataByURL: imageData, failingURLs: failingImageURLs)
        )
    }

    func testBuildsDraftFromOEmbedMetadata() async throws {
        let canonicalURL = try XCTUnwrap(URL(string: "https://x.com/oshi/status/42"))
        let metadata = XOEmbedMetadata(
            canonicalURL: canonicalURL,
            authorName: "推し",
            postText: "ライブ情報"
        )

        let draft = try await builder(client: StubClient(metadata: metadata))
            .makeDraft(from: try XCTUnwrap(URL(string: "https://twitter.com/oshi/status/42?s=20")))

        XCTAssertEqual(draft.sourceURL, canonicalURL)
        XCTAssertEqual(draft.authorName, "推し")
        XCTAssertEqual(draft.postText, "ライブ情報")
        XCTAssertNil(draft.warning)
    }

    func testAddsParsedEventDetailsToEditableDraft() async throws {
        let canonicalURL = try XCTUnwrap(URL(string: "https://x.com/oshi/status/42"))
        let eventURL = try XCTUnwrap(URL(string: "https://heroines.jp/news/event"))
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let metadata = XOEmbedMetadata(
            canonicalURL: canonicalURL,
            authorName: "推し",
            postText: "ライブ情報",
            linkedURLs: [eventURL]
        )
        let details = EventImportDetails(
            title: "HEROINES FES",
            date: date,
            venue: "Spotify O-EAST",
            performers: ["iLiFE!", "のんふぃく！"],
            linkedURL: eventURL
        )

        let draft = try await builder(
            client: StubClient(metadata: metadata),
            eventLinkImporter: StubEventLinkImporter(details: details)
        ).makeDraft(from: canonicalURL)

        XCTAssertEqual(draft.eventDetails, details)
        XCTAssertEqual(draft.postText, "ライブ情報")
    }

    func testBuildsEditableDraftWhenMetadataFetchFails() async throws {
        let draft = try await builder(client: StubClient(metadata: nil))
            .makeDraft(from: try XCTUnwrap(URL(string: "https://x.com/oshi/status/42")))

        XCTAssertEqual(draft.sourceURL.absoluteString, "https://x.com/oshi/status/42")
        XCTAssertNotNil(draft.warning)
    }

    func testRejectsInvalidURLBeforeFetching() async throws {
        do {
            _ = try await builder(client: StubClient(metadata: nil))
                .makeDraft(from: XCTUnwrap(URL(string: "https://example.com/oshi/status/42")))
            XCTFail("Expected invalid URL error")
        } catch let error as XOEmbedError {
            guard case .invalidURL = error else { return XCTFail("Unexpected error: \(error)") }
        }
    }

    func testDownloadsFirstAvailableTweetImage() async throws {
        let first = try XCTUnwrap(URL(string: "https://pbs.twimg.com/media/first.jpg"))
        let second = try XCTUnwrap(URL(string: "https://pbs.twimg.com/media/second.jpg"))
        let metadata = XOEmbedMetadata(
            canonicalURL: try XCTUnwrap(URL(string: "https://x.com/oshi/status/42")),
            authorName: "推し",
            postText: "ライブ情報"
        )

        let draft = try await builder(
            client: StubClient(metadata: metadata),
            imageURLs: [first, second],
            imageData: [second: Data([0xFF, 0xD8, 0xFF])],
            failingImageURLs: [first]
        ).makeDraft(from: metadata.canonicalURL)

        XCTAssertEqual(draft.imageData, Data([0xFF, 0xD8, 0xFF]))
    }

    func testImportWithoutTweetImagesKeepsCurrentBehavior() async throws {
        let metadata = XOEmbedMetadata(
            canonicalURL: try XCTUnwrap(URL(string: "https://x.com/oshi/status/42")),
            authorName: "推し",
            postText: "ライブ情報"
        )

        let draft = try await builder(client: StubClient(metadata: metadata))
            .makeDraft(from: metadata.canonicalURL)

        XCTAssertNil(draft.imageData)
        XCTAssertNil(draft.warning)
    }
}
