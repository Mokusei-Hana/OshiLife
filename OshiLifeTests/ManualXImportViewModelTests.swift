import Foundation
import XCTest
@testable import OshiLife

@MainActor
final class ManualXImportViewModelTests: XCTestCase {
    private struct StubClient: XOEmbedFetching {
        func fetch(postURL: URL) async throws -> XOEmbedMetadata {
            XOEmbedMetadata(canonicalURL: postURL, authorName: "推し", postText: "ライブ情報")
        }
    }

    func testClipboardIsCheckedOnlyOnceAndSuggestionCanBeUsed() throws {
        let viewModel = ManualXImportViewModel()
        viewModel.checkClipboard(text: "https://twitter.com/first/status/1?s=20")
        viewModel.checkClipboard(text: "https://x.com/second/status/2")

        XCTAssertEqual(viewModel.clipboardSuggestion?.absoluteString, "https://x.com/first/status/1")

        viewModel.useClipboardSuggestion()
        XCTAssertEqual(viewModel.urlString, "https://x.com/first/status/1")
        XCTAssertNil(viewModel.clipboardSuggestion)
    }

    func testImportsNormalizedURLIntoDraft() async throws {
        let builder = XImportDraftBuilder(client: StubClient())
        let viewModel = ManualXImportViewModel(draftBuilder: builder)
        viewModel.urlString = " https://mobile.twitter.com/oshi/status/42?s=20 "

        let importedDraft = await viewModel.importDraft()
        let draft = try XCTUnwrap(importedDraft)

        XCTAssertEqual(draft.sourceURL.absoluteString, "https://x.com/oshi/status/42")
        XCTAssertEqual(draft.authorName, "推し")
        XCTAssertNil(viewModel.errorMessage)
    }

    func testInvalidURLShowsErrorAndDoesNotImport() async {
        let viewModel = ManualXImportViewModel()
        viewModel.urlString = "https://example.com/not-x"

        let draft = await viewModel.importDraft()
        XCTAssertNil(draft)
        XCTAssertNotNil(viewModel.errorMessage)
    }
}
