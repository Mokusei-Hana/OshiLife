import Foundation
import XCTest
@testable import OshiLife

@MainActor
final class LiveEditorViewModelTests: XCTestCase {
    func testRequiresArtistTitleAndDate() throws {
        let store = LiveStore(container: try ModelContainerFactory.makeInMemory())
        let viewModel = LiveEditorViewModel(store: store)
        XCTAssertFalse(viewModel.canSave)
        XCTAssertEqual(viewModel.validationMessages.count, 3)

        viewModel.artistName = "推し"
        viewModel.title = "ワンマンライブ"
        viewModel.eventDate = .now
        XCTAssertTrue(viewModel.canSave)
    }

    func testImportMapsAuthorTextAndURLWithoutInferringEventFields() throws {
        let store = LiveStore(container: try ModelContainerFactory.makeInMemory())
        let sourceURL = try XCTUnwrap(URL(string: "https://x.com/oshi/status/42"))
        let pending = PendingShareImport(sourceURL: sourceURL, authorName: "推し", postText: "ライブ告知")
        let viewModel = LiveEditorViewModel(store: store, pendingImport: pending)

        XCTAssertEqual(viewModel.artistName, "推し")
        XCTAssertEqual(viewModel.notes, "ライブ告知")
        XCTAssertEqual(viewModel.sourceURLString, sourceURL.absoluteString)
        XCTAssertTrue(viewModel.title.isEmpty)
        XCTAssertNil(viewModel.eventDate)
    }
}
