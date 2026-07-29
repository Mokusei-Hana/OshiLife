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

    func testImportMapsParsedEventFieldsIntoEditableEditor() throws {
        let store = LiveStore(container: try ModelContainerFactory.makeInMemory())
        let sourceURL = try XCTUnwrap(URL(string: "https://x.com/oshi/status/42"))
        let eventURL = try XCTUnwrap(URL(string: "https://heroines.jp/news/event"))
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let details = EventImportDetails(
            title: "HEROINES FES",
            date: date,
            venue: "Spotify O-EAST",
            openTime: date.addingTimeInterval(17 * 60 * 60),
            startTime: date.addingTimeInterval(18 * 60 * 60),
            performers: ["iLiFE!", "のんふぃく！"],
            ticketOptions: [
                TicketOption(name: "Sチケット", price: 9000),
                TicketOption(name: "Aチケット", price: 3500)
            ],
            ticketInformation: "一般チケット ¥3,500",
            linkedURL: eventURL
        )
        let pending = PendingShareImport(
            sourceURL: sourceURL,
            authorName: "公式",
            postText: "ライブ告知",
            eventDetails: details
        )

        let viewModel = LiveEditorViewModel(store: store, pendingImport: pending)

        XCTAssertEqual(viewModel.artistName, "iLiFE! / のんふぃく！")
        XCTAssertEqual(viewModel.title, "HEROINES FES")
        XCTAssertEqual(viewModel.eventDate, date)
        XCTAssertEqual(viewModel.venue, "Spotify O-EAST")
        XCTAssertTrue(viewModel.hasOpenTime)
        XCTAssertTrue(viewModel.hasStartTime)
        XCTAssertTrue(viewModel.performers.isEmpty)
        XCTAssertEqual(viewModel.performerSuggestions, ["iLiFE!", "のんふぃく！"])
        XCTAssertEqual(viewModel.ticketOptions.count, 2)
        XCTAssertEqual(viewModel.ticketURLString, eventURL.absoluteString)
        XCTAssertEqual(viewModel.sourceURLString, sourceURL.absoluteString)
        XCTAssertTrue(viewModel.notes.contains("一般チケット ¥3,500"))

        viewModel.title = "編集したタイトル"
        viewModel.addPerformer("iLiFE!")
        viewModel.selectedTicketID = viewModel.ticketOptions[0].id
        let saved = viewModel.save(imageStore: ImageStore(rootURL: FileManager.default.temporaryDirectory))
        XCTAssertEqual(saved?.selectedTicketID, viewModel.ticketOptions[0].id)
        XCTAssertEqual(saved?.selectedTicketName, "Sチケット")
        XCTAssertEqual(saved?.ticketOptions.count, 2)
        XCTAssertEqual(saved?.performers, ["iLiFE!"])
        XCTAssertEqual(saved?.performerCandidates, ["iLiFE!", "のんふぃく！"])
        XCTAssertEqual(viewModel.title, "編集したタイトル")
    }

    func testPerformerTagsCanBeAddedRemovedAndDeduplicated() throws {
        let store = LiveStore(container: try ModelContainerFactory.makeInMemory())
        let viewModel = LiveEditorViewModel(store: store)

        XCTAssertTrue(viewModel.addPerformer(" iLiFE! "))
        XCTAssertTrue(viewModel.addPerformer("Mirror,Mirror"))
        XCTAssertFalse(viewModel.addPerformer("ILIFE!"))
        viewModel.removePerformer("iLiFE!")

        XCTAssertEqual(viewModel.performers, ["Mirror,Mirror"])
    }

    func testPerformerSuggestionsAreSortedByUsageFrequency() throws {
        let store = LiveStore(container: try ModelContainerFactory.makeInMemory())
        try store.insert(LiveEvent(
            artistName: "A",
            title: "One",
            eventDate: .now,
            performers: ["TENRIN", "iLiFE!"]
        ))
        try store.insert(LiveEvent(
            artistName: "B",
            title: "Two",
            eventDate: .now,
            performers: ["TENRIN"]
        ))

        let viewModel = LiveEditorViewModel(store: store)

        XCTAssertEqual(viewModel.performerSuggestions, ["TENRIN", "iLiFE!"])
    }

    func testCollapsedPerformerSuggestionsAlwaysIncludeSelections() {
        let names = (1...12).map { "Performer \($0)" }
        let selected = Set(["Performer 10", "Performer 12"])

        let collapsed = PerformerCatalog.collapsedNames(
            from: names,
            selected: selected,
            limit: 8
        )

        XCTAssertEqual(collapsed.count, 8)
        XCTAssertTrue(selected.isSubset(of: Set(collapsed)))
    }

    func testCollapsedPerformerSuggestionsDoNotHideSelectionsBeyondLimit() {
        let names = (1...12).map { "Performer \($0)" }
        let selected = Set(names.suffix(10))

        let collapsed = PerformerCatalog.collapsedNames(
            from: names,
            selected: selected,
            limit: 8
        )

        XCTAssertEqual(Set(collapsed), selected)
    }

    func testPerformerCandidateSearchMergesSelectedNamesWithoutDuplicates() {
        let names = PerformerCatalog.uniqueNames([
            "TENRIN",
            "iLiFE!",
            "tenrin",
            "のんふぃく！"
        ])

        XCTAssertEqual(names, ["TENRIN", "iLiFE!", "のんふぃく！"])
    }

    func testExistingEventKeepsPreviouslySavedPerformerSelections() throws {
        let store = LiveStore(container: try ModelContainerFactory.makeInMemory())
        let event = LiveEvent(
            artistName: "推し",
            title: "ライブ",
            eventDate: .now,
            performers: ["TENRIN", "iLiFE!"]
        )

        let viewModel = LiveEditorViewModel(store: store, event: event)

        XCTAssertEqual(viewModel.performers, ["TENRIN", "iLiFE!"])
        XCTAssertEqual(
            Array(viewModel.performerSuggestions.prefix(2)),
            ["TENRIN", "iLiFE!"]
        )
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

    func testImportWithoutParsedTicketsStartsEmptyAndAllowsManualEntry() throws {
        let store = LiveStore(container: try ModelContainerFactory.makeInMemory())
        let sourceURL = try XCTUnwrap(URL(string: "https://x.com/oshi/status/42"))
        let pending = PendingShareImport(sourceURL: sourceURL, authorName: "推し", postText: "ライブ告知")
        let viewModel = LiveEditorViewModel(store: store, pendingImport: pending)
        viewModel.title = "ワンマンライブ"
        viewModel.eventDate = .now

        XCTAssertTrue(viewModel.ticketOptions.isEmpty)

        let added = try XCTUnwrap(viewModel.addTicketOption(name: " 一般チケット ", price: 3500, description: " ドリンク代別 "))
        XCTAssertEqual(added.name, "一般チケット")
        XCTAssertEqual(added.price, 3500)
        XCTAssertEqual(added.description, "ドリンク代別")
        viewModel.selectedTicketID = added.id

        let saved = try XCTUnwrap(viewModel.save(imageStore: ImageStore(rootURL: FileManager.default.temporaryDirectory)))
        XCTAssertEqual(saved.ticketOptions.count, 1)
        XCTAssertEqual(saved.selectedTicketID, added.id)
    }

    func testMultiDayImportKeepsFirstDayAndRecordsRangeInNotes() throws {
        let store = LiveStore(container: try ModelContainerFactory.makeInMemory())
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 7)))
        let end = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 9)))
        let sourceURL = try XCTUnwrap(URL(string: "https://x.com/oshi/status/42"))
        let details = EventImportDetails(
            title: "IDOL SUMMER JUNGLE 2026",
            date: start,
            endDate: end,
            venue: "お台場R地区",
            linkedURL: sourceURL
        )
        let pending = PendingShareImport(sourceURL: sourceURL, authorName: "公式", eventDetails: details)

        let viewModel = LiveEditorViewModel(store: store, pendingImport: pending)

        XCTAssertEqual(viewModel.eventDate, start)
        XCTAssertTrue(viewModel.notes.contains("2026/8/7"))
        XCTAssertTrue(viewModel.notes.contains("2026/8/9"))

        viewModel.artistName = "推し"
        let saved = try XCTUnwrap(viewModel.save(imageStore: ImageStore(rootURL: FileManager.default.temporaryDirectory)))
        XCTAssertEqual(saved.eventDate, start)
        XCTAssertTrue(saved.notes.contains("2026/8/9"))
    }

    func testImportNotesDropURLNoiseButKeepAnnouncementText() throws {
        let store = LiveStore(container: try ModelContainerFactory.makeInMemory())
        let sourceURL = try XCTUnwrap(URL(string: "https://x.com/iLiFE_official/status/42"))
        let shortURL = try XCTUnwrap(URL(string: "https://t.co/SPT3fbKaK6"))
        let eventURL = try XCTUnwrap(URL(string: "https://ticketdive.com/event/idolsummerjungle2026"))
        let details = EventImportDetails(
            title: "IDOL SUMMER JUNGLE 2026",
            date: Date(timeIntervalSince1970: 1_800_000_000),
            venue: "お台場R地区",
            linkedURL: eventURL,
            shortenedLinkURLs: [shortURL]
        )
        let pending = PendingShareImport(
            sourceURL: sourceURL,
            authorName: "iLiFE!",
            postText: """
            8月9日は！「IDOL SUMMER JUNGLE 2026」に出演いたします❤︎

            🎫チケット販売中！
            https://t.co/SPT3fbKaK6

            ※後日お知らせ予定。#iLiFE pic.twitter.com/T86Fe2z2Nb
            """,
            eventDetails: details
        )

        let viewModel = LiveEditorViewModel(store: store, pendingImport: pending)

        // Media placeholders and the stored short link are noise in Notes.
        XCTAssertFalse(viewModel.notes.contains("pic.twitter.com"))
        XCTAssertFalse(viewModel.notes.contains("t.co/SPT3fbKaK6"))
        XCTAssertTrue(viewModel.notes.contains("「IDOL SUMMER JUNGLE 2026」に出演いたします❤︎"))
        XCTAssertTrue(viewModel.notes.contains("#iLiFE"))
        XCTAssertTrue(viewModel.notes.contains("※後日お知らせ予定。"))
        // The resolved TicketDive URL lives in the structured link field.
        XCTAssertEqual(viewModel.ticketURLString, eventURL.absoluteString)
    }

    func testTicketsRemainEditableWhenDetectionFoundNone() throws {
        let store = LiveStore(container: try ModelContainerFactory.makeInMemory())
        let sourceURL = try XCTUnwrap(URL(string: "https://x.com/oshi/status/42"))
        // A partial import: fields were recognized but no ticket type was.
        let details = EventImportDetails(
            title: "ワンマンライブ",
            date: Date(timeIntervalSince1970: 1_800_000_000),
            venue: "Zepp Haneda",
            linkedURL: sourceURL
        )
        let pending = PendingShareImport(sourceURL: sourceURL, authorName: "推し", eventDetails: details)

        let viewModel = LiveEditorViewModel(store: store, pendingImport: pending)

        XCTAssertTrue(viewModel.ticketOptions.isEmpty)
        let added = try XCTUnwrap(viewModel.addTicketOption(name: "VIPチケット", price: 10000, description: "特典付き"))
        viewModel.selectedTicketID = added.id
        viewModel.artistName = "推し"

        let saved = try XCTUnwrap(viewModel.save(imageStore: ImageStore(rootURL: FileManager.default.temporaryDirectory)))
        XCTAssertEqual(saved.ticketOptions.map(\.name), ["VIPチケット"])
        XCTAssertEqual(saved.selectedTicketID, added.id)
    }

    func testAddTicketOptionRejectsBlankNameAndDropsEmptyDescription() throws {
        let store = LiveStore(container: try ModelContainerFactory.makeInMemory())
        let viewModel = LiveEditorViewModel(store: store)

        XCTAssertNil(viewModel.addTicketOption(name: "   ", price: 1000, description: nil))
        XCTAssertTrue(viewModel.ticketOptions.isEmpty)

        let added = try XCTUnwrap(viewModel.addTicketOption(name: "VIP", price: nil, description: "  "))
        XCTAssertNil(added.price)
        XCTAssertNil(added.description)
    }

    func testRemovingSelectedTicketClearsSelection() throws {
        let store = LiveStore(container: try ModelContainerFactory.makeInMemory())
        let viewModel = LiveEditorViewModel(store: store)
        let first = try XCTUnwrap(viewModel.addTicketOption(name: "Sチケット", price: 9000, description: nil))
        let second = try XCTUnwrap(viewModel.addTicketOption(name: "Aチケット", price: 3500, description: nil))

        viewModel.selectedTicketID = first.id
        viewModel.removeTicketOptions(at: IndexSet(integer: 0))
        XCTAssertNil(viewModel.selectedTicketID)
        XCTAssertEqual(viewModel.ticketOptions, [second])

        viewModel.selectedTicketID = second.id
        viewModel.removeTicketOptions(at: IndexSet(integer: 1))
        XCTAssertEqual(viewModel.selectedTicketID, second.id)
        XCTAssertEqual(viewModel.ticketOptions, [second])
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
