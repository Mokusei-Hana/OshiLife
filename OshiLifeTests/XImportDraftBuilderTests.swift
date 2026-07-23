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

    func testBuildsDraftFromOEmbedMetadata() async throws {
        let canonicalURL = try XCTUnwrap(URL(string: "https://x.com/oshi/status/42"))
        let metadata = XOEmbedMetadata(
            canonicalURL: canonicalURL,
            authorName: "推し",
            postText: "ライブ情報"
        )

        let draft = try await XImportDraftBuilder(client: StubClient(metadata: metadata))
            .makeDraft(from: try XCTUnwrap(URL(string: "https://twitter.com/oshi/status/42?s=20")))

        XCTAssertEqual(draft.sourceURL, canonicalURL)
        XCTAssertEqual(draft.authorName, "推し")
        XCTAssertEqual(draft.postText, "ライブ情報")
        XCTAssertNil(draft.warning)
    }

    func testBuildsEditableDraftWhenMetadataFetchFails() async throws {
        let draft = try await XImportDraftBuilder(client: StubClient(metadata: nil))
            .makeDraft(from: try XCTUnwrap(URL(string: "https://x.com/oshi/status/42")))

        XCTAssertEqual(draft.sourceURL.absoluteString, "https://x.com/oshi/status/42")
        XCTAssertNotNil(draft.warning)
    }

    func testRejectsInvalidURLBeforeFetching() async throws {
        do {
            _ = try await XImportDraftBuilder(client: StubClient(metadata: nil))
                .makeDraft(from: XCTUnwrap(URL(string: "https://example.com/oshi/status/42")))
            XCTFail("Expected invalid URL error")
        } catch let error as XOEmbedError {
            guard case .invalidURL = error else { return XCTFail("Unexpected error: \(error)") }
        }
    }
}
