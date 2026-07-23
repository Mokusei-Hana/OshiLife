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

    func testVenueSelectionSavesResolvedLocation() throws {
        let store = LiveStore(container: try ModelContainerFactory.makeInMemory())
        let viewModel = LiveEditorViewModel(store: store)
        viewModel.artistName = "推し"
        viewModel.title = "ワンマンライブ"
        viewModel.eventDate = .now

        viewModel.selectVenue(VenueSelection(
            name: "日本武道館",
            address: "東京都千代田区北の丸公園2-3",
            latitude: 35.693317,
            longitude: 139.749885
        ))

        let event = try XCTUnwrap(viewModel.save(imageStore: ImageStore(rootURL: FileManager.default.temporaryDirectory)))
        XCTAssertEqual(event.venue, "日本武道館")
        XCTAssertEqual(event.address, "東京都千代田区北の丸公園2-3")
        XCTAssertEqual(event.latitude, 35.693317)
        XCTAssertEqual(event.longitude, 139.749885)
    }

    func testClearingVenueAlsoClearsCoordinates() throws {
        let store = LiveStore(container: try ModelContainerFactory.makeInMemory())
        let event = LiveEvent(
            artistName: "推し",
            title: "ライブ",
            eventDate: .now,
            venue: "日本武道館",
            address: "東京都千代田区",
            latitude: 35.693317,
            longitude: 139.749885
        )
        let viewModel = LiveEditorViewModel(store: store, event: event)

        viewModel.clearVenue()

        XCTAssertTrue(viewModel.venue.isEmpty)
        XCTAssertTrue(viewModel.address.isEmpty)
        XCTAssertNil(viewModel.latitude)
        XCTAssertNil(viewModel.longitude)
    }
}
