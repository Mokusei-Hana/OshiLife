import Foundation
import XCTest
@testable import OshiLife

// MARK: - Multi-day event selection tests

@MainActor
final class MultiDayEventSelectionTests: XCTestCase {

    // MARK: - Helpers

    private func tokyoCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }

    private func date(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) throws -> Date {
        let cal = tokyoCalendar()
        return try XCTUnwrap(
            cal.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))
        )
    }

    private func assertHour(_ date: Date?, _ expected: Int, file: StaticString = #filePath, line: UInt = #line) throws {
        let d = try XCTUnwrap(date, file: file, line: line)
        let h = tokyoCalendar().component(.hour, from: d)
        XCTAssertEqual(h, expected, file: file, line: line)
    }

    private func assertMinute(_ date: Date?, _ expected: Int, file: StaticString = #filePath, line: UInt = #line) throws {
        let d = try XCTUnwrap(date, file: file, line: line)
        let m = tokyoCalendar().component(.minute, from: d)
        XCTAssertEqual(m, expected, file: file, line: line)
    }

    private func makeStore() throws -> LiveStore {
        LiveStore(container: try ModelContainerFactory.makeInMemory())
    }

    // MARK: - 1. Single-day event does not show day selector

    func testSingleDayEventHasNoScheduleOptions() throws {
        let store = try makeStore()
        let sourceURL = try XCTUnwrap(URL(string: "https://ticketdive.com/event/oneman"))
        let eventDate = try date(year: 2026, month: 9, day: 12)
        let details = EventImportDetails(
            title: "ワンマンライブ",
            date: eventDate,
            venue: "Zepp Haneda",
            linkedURL: sourceURL
        )
        let pending = PendingShareImport(sourceURL: sourceURL, authorName: "推し", eventDetails: details)
        let viewModel = LiveEditorViewModel(store: store, pendingImport: pending)

        XCTAssertTrue(viewModel.scheduleOptions.isEmpty, "Single-day event must not expose schedule options")
    }

    // MARK: - 2. Multi-day event shows day selector (via parser)

    func testMultiDayImportParsesScheduleOptions() throws {
        let sourceURL = try XCTUnwrap(URL(string: "https://ticketdive.com/event/festival"))
        let html = """
        <html><head>
        <meta property="og:title" content="IDOL SUMMER JUNGLE 2026"/>
        </head><body>
        <div>公演日時2026/8/7(金)〜8/9(日)</div>
        <div>会場お台場R地区</div>
        <div>DAY1日時2026/8/7(金)</div>
        <div>開場時刻 9:00 / 開演時刻 10:00</div>
        <div>出演アキシブproject/</div>
        <div>chuLa</div>
        <div>選択する</div>
        <div>DAY2日時2026/8/8(土)</div>
        <div>開場時刻 9:00 / 開演時刻 10:00</div>
        <div>出演iON!</div>
        <div>選択する</div>
        <div>DAY3日時2026/8/9(日)</div>
        <div>開場時刻 9:00 / 開演時刻 10:00</div>
        <div>出演Mirror,Mirror</div>
        <div>選択する</div>
        </body></html>
        """
        let details = try XCTUnwrap(TicketDiveEventPageParser().parse(html: html, sourceURL: sourceURL))

        XCTAssertEqual(details.scheduleOptions.count, 3, "3 DAY blocks should produce 3 schedule options")
        XCTAssertEqual(details.scheduleOptions[0].dayLabel, "DAY1")
        XCTAssertEqual(details.scheduleOptions[1].dayLabel, "DAY2")
        XCTAssertEqual(details.scheduleOptions[2].dayLabel, "DAY3")
    }

    // MARK: - 3. Selecting DAY1 updates event date/time

    func testSelectDAY1UpdatesFields() throws {
        let store = try makeStore()
        let sourceURL = try XCTUnwrap(URL(string: "https://ticketdive.com/event/festival"))
        let day1 = try date(year: 2026, month: 8, day: 7)
        let day2 = try date(year: 2026, month: 8, day: 8)
        let open1 = try date(year: 2026, month: 8, day: 7, hour: 9, minute: 0)
        let start1 = try date(year: 2026, month: 8, day: 7, hour: 10, minute: 0)

        let options = [
            EventScheduleOption(dayLabel: "DAY1", date: day1, openTime: open1, startTime: start1,
                                performers: ["アキシブproject"]),
            EventScheduleOption(dayLabel: "DAY2", date: day2, openTime: nil, startTime: nil, performers: [])
        ]
        let details = EventImportDetails(
            title: "フェス",
            date: day1,
            endDate: day2,
            linkedURL: sourceURL,
            scheduleOptions: options
        )
        let pending = PendingShareImport(sourceURL: sourceURL, authorName: "公式", eventDetails: details)
        let viewModel = LiveEditorViewModel(store: store, pendingImport: pending)

        XCTAssertEqual(viewModel.scheduleOptions.count, 2, "2 options should be available for the picker")

        viewModel.selectScheduleDay(options[0])

        XCTAssertEqual(viewModel.eventDate, day1)
        XCTAssertTrue(viewModel.hasOpenTime)
        try assertHour(viewModel.openTime, 9)
        try assertMinute(viewModel.openTime, 0)
        XCTAssertTrue(viewModel.hasStartTime)
        try assertHour(viewModel.startTime, 10)
        try assertMinute(viewModel.startTime, 0)
        XCTAssertTrue(viewModel.performers.isEmpty)
        XCTAssertTrue(viewModel.performerSuggestions.contains("アキシブproject"))
    }

    // MARK: - 4. Selecting DAY2 updates event date/time

    func testSelectDAY2UpdatesFields() throws {
        let store = try makeStore()
        let sourceURL = try XCTUnwrap(URL(string: "https://ticketdive.com/event/festival"))
        let day1 = try date(year: 2026, month: 8, day: 7)
        let day2 = try date(year: 2026, month: 8, day: 8)
        let open2 = try date(year: 2026, month: 8, day: 8, hour: 10, minute: 0)
        let start2 = try date(year: 2026, month: 8, day: 8, hour: 11, minute: 0)

        let options = [
            EventScheduleOption(dayLabel: "DAY1", date: day1),
            EventScheduleOption(dayLabel: "DAY2", date: day2, openTime: open2, startTime: start2,
                                performers: ["iON!", "TENRIN"])
        ]
        let details = EventImportDetails(
            title: "フェス",
            date: day1,
            endDate: day2,
            linkedURL: sourceURL,
            scheduleOptions: options
        )
        let pending = PendingShareImport(sourceURL: sourceURL, authorName: "公式", eventDetails: details)
        let viewModel = LiveEditorViewModel(store: store, pendingImport: pending)

        viewModel.selectScheduleDay(options[1])

        XCTAssertEqual(viewModel.eventDate, day2)
        XCTAssertTrue(viewModel.hasOpenTime)
        try assertHour(viewModel.openTime, 10)
        try assertMinute(viewModel.openTime, 0)
        XCTAssertTrue(viewModel.hasStartTime)
        try assertHour(viewModel.startTime, 11)
        try assertMinute(viewModel.startTime, 0)
        XCTAssertTrue(viewModel.performers.isEmpty)
        XCTAssertTrue(Set(["iON!", "TENRIN"]).isSubset(of: Set(viewModel.performerSuggestions)))
    }

    // MARK: - 5. Selecting DAY3 updates event date/time

    func testSelectDAY3UpdatesFields() throws {
        let store = try makeStore()
        let sourceURL = try XCTUnwrap(URL(string: "https://ticketdive.com/event/festival"))
        let day1 = try date(year: 2026, month: 8, day: 7)
        let day3 = try date(year: 2026, month: 8, day: 9)
        let open3 = try date(year: 2026, month: 8, day: 9, hour: 9, minute: 30)
        let start3 = try date(year: 2026, month: 8, day: 9, hour: 10, minute: 30)

        let options = [
            EventScheduleOption(dayLabel: "DAY1", date: day1),
            EventScheduleOption(dayLabel: "DAY2", date: try date(year: 2026, month: 8, day: 8)),
            EventScheduleOption(dayLabel: "DAY3", date: day3, openTime: open3, startTime: start3,
                                performers: ["Mirror,Mirror"])
        ]
        let details = EventImportDetails(
            title: "3DAYS Festival",
            date: day1,
            endDate: day3,
            linkedURL: sourceURL,
            scheduleOptions: options
        )
        let pending = PendingShareImport(sourceURL: sourceURL, authorName: "公式", eventDetails: details)
        let viewModel = LiveEditorViewModel(store: store, pendingImport: pending)

        viewModel.selectScheduleDay(options[2])

        XCTAssertEqual(viewModel.eventDate, day3)
        XCTAssertTrue(viewModel.hasOpenTime)
        try assertHour(viewModel.openTime, 9)
        try assertMinute(viewModel.openTime, 30)
        XCTAssertTrue(viewModel.hasStartTime)
        try assertHour(viewModel.startTime, 10)
        try assertMinute(viewModel.startTime, 30)
        XCTAssertTrue(viewModel.performers.isEmpty)
        XCTAssertTrue(viewModel.performerSuggestions.contains("Mirror,Mirror"))
    }

    func testChangingScheduleUpdatesPerformerCandidatesAndPreservesSelections() throws {
        let store = try makeStore()
        let sourceURL = try XCTUnwrap(URL(string: "https://ticketdive.com/event/festival"))
        let options = [
            EventScheduleOption(
                dayLabel: "DAY1",
                date: try date(year: 2026, month: 8, day: 7),
                performers: ["chuLa"]
            ),
            EventScheduleOption(
                dayLabel: "DAY2",
                date: try date(year: 2026, month: 8, day: 8),
                performers: ["TENRIN"]
            )
        ]
        let details = EventImportDetails(
            title: "フェス",
            date: options[0].date,
            linkedURL: sourceURL,
            scheduleOptions: options
        )
        let pending = PendingShareImport(sourceURL: sourceURL, authorName: "公式", eventDetails: details)
        let viewModel = LiveEditorViewModel(store: store, pendingImport: pending)

        XCTAssertTrue(viewModel.performerSuggestions.contains("chuLa"))
        XCTAssertFalse(viewModel.performerSuggestions.contains("TENRIN"))
        viewModel.addPerformer("chuLa")

        viewModel.selectScheduleDay(options[1])

        XCTAssertTrue(viewModel.performerSuggestions.contains("TENRIN"))
        XCTAssertFalse(viewModel.performerSuggestions.contains("chuLa"))
        XCTAssertTrue(viewModel.performers.isEmpty)
        viewModel.addPerformer("TENRIN")

        viewModel.selectScheduleDay(options[0])

        XCTAssertEqual(viewModel.performers, ["chuLa"])
    }

    func testSavingMultipleSchedulesCreatesIndependentEventsWithSharedSource() throws {
        let store = try makeStore()
        let sourceURL = try XCTUnwrap(URL(string: "https://x.com/official/status/42"))
        let eventURL = try XCTUnwrap(URL(string: "https://ticketdive.com/event/festival"))
        let options = [
            EventScheduleOption(
                dayLabel: "DAY1",
                date: try date(year: 2026, month: 8, day: 7),
                performers: ["chuLa"]
            ),
            EventScheduleOption(
                dayLabel: "Special Stage",
                date: try date(year: 2026, month: 8, day: 8),
                performers: ["TENRIN"]
            )
        ]
        let details = EventImportDetails(
            title: "フェス",
            date: options[0].date,
            linkedURL: eventURL,
            scheduleOptions: options
        )
        let pending = PendingShareImport(sourceURL: sourceURL, authorName: "公式", eventDetails: details)
        let viewModel = LiveEditorViewModel(store: store, pendingImport: pending)
        viewModel.selectScheduleDay(options[0])
        viewModel.addPerformer("chuLa")
        viewModel.selectScheduleDay(options[1])
        viewModel.addPerformer("TENRIN")

        let saved = viewModel.save(
            imageStore: ImageStore(rootURL: FileManager.default.temporaryDirectory)
        )
        let events = try store.fetchAll()

        XCTAssertNotNil(saved)
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(Set(events.map(\.scheduleLabel)), ["DAY1", "Special Stage"])
        XCTAssertEqual(Set(events.map(\.sourceURLString)), [sourceURL.absoluteString])
        XCTAssertEqual(Set(events.compactMap(\.scheduleGroupID)).count, 1)
        XCTAssertEqual(
            Dictionary(uniqueKeysWithValues: events.map { ($0.scheduleLabel, $0.performers) }),
            ["DAY1": ["chuLa"], "Special Stage": ["TENRIN"]]
        )
    }

    func testEditingScheduleGroupCanRemoveParticipationAfterImport() throws {
        let store = try makeStore()
        let sourceURL = try XCTUnwrap(URL(string: "https://x.com/official/status/42"))
        let options = [
            EventScheduleOption(dayLabel: "DAY1", date: try date(year: 2026, month: 8, day: 7)),
            EventScheduleOption(dayLabel: "DAY2", date: try date(year: 2026, month: 8, day: 8))
        ]
        let details = EventImportDetails(
            title: "フェス",
            date: options[0].date,
            linkedURL: sourceURL,
            scheduleOptions: options
        )
        let pending = PendingShareImport(sourceURL: sourceURL, authorName: "公式", eventDetails: details)
        let importingViewModel = LiveEditorViewModel(store: store, pendingImport: pending)
        importingViewModel.selectScheduleDay(options[1])
        XCTAssertNotNil(importingViewModel.save(
            imageStore: ImageStore(rootURL: FileManager.default.temporaryDirectory)
        ))
        let importedEvents = try store.fetchAll()
        XCTAssertEqual(importedEvents.count, 2)

        let editingViewModel = LiveEditorViewModel(store: store, event: importedEvents[0])
        editingViewModel.setScheduleParticipation(options[1], isSelected: false)
        XCTAssertNotNil(editingViewModel.save(
            imageStore: ImageStore(rootURL: FileManager.default.temporaryDirectory)
        ))

        let remainingEvents = try store.fetchAll()
        XCTAssertEqual(remainingEvents.count, 1)
        XCTAssertEqual(remainingEvents[0].scheduleLabel, "DAY1")
    }

    // MARK: - Existing imported events remain compatible

    func testExistingImportedEventsWithoutScheduleOptionsAreCompatible() throws {
        let store = try makeStore()
        let sourceURL = try XCTUnwrap(URL(string: "https://x.com/oshi/status/42"))
        let eventDate = try date(year: 2026, month: 9, day: 12)
        // Simulate a previously stored import that was encoded before scheduleOptions existed.
        // The decoder falls back to an empty array for the missing key.
        let details = EventImportDetails(
            title: "ワンマンライブ",
            date: eventDate,
            venue: "Zepp Haneda",
            linkedURL: sourceURL
            // scheduleOptions intentionally omitted — default is []
        )
        let pending = PendingShareImport(sourceURL: sourceURL, authorName: "推し", eventDetails: details)
        let viewModel = LiveEditorViewModel(store: store, pendingImport: pending)

        // No schedule options → selector is hidden (count <= 1)
        XCTAssertTrue(viewModel.scheduleOptions.isEmpty)
        // All original fields still work
        XCTAssertEqual(viewModel.eventDate, eventDate)
        XCTAssertEqual(viewModel.venue, "Zepp Haneda")
        XCTAssertEqual(viewModel.title, "ワンマンライブ")

        // Can still save without selecting a day
        viewModel.artistName = "推し"
        let saved = viewModel.save(imageStore: ImageStore(rootURL: FileManager.default.temporaryDirectory))
        XCTAssertNotNil(saved)
        XCTAssertEqual(saved?.eventDate, eventDate)
    }

    // MARK: - Parser: single-day event produces no schedule options

    func testParserProducesNoScheduleOptionsForSingleDayEvent() throws {
        let sourceURL = try XCTUnwrap(URL(string: "https://ticketdive.com/event/oneman"))
        let html = """
        <html><body>
        <div>公演日時2026/9/12(土)</div>
        <div>会場Zepp Haneda</div>
        <div>開場時刻 17:00 / 開演時刻 18:00</div>
        </body></html>
        """
        let details = try XCTUnwrap(TicketDiveEventPageParser().parse(html: html, sourceURL: sourceURL))

        XCTAssertTrue(details.scheduleOptions.isEmpty,
                      "A single-day event must not produce schedule options")
    }

    // MARK: - Parser: multi-day event produces schedule options with per-day times

    func testParserPopulatesPerDayTimesInScheduleOptions() throws {
        let sourceURL = try XCTUnwrap(URL(string: "https://ticketdive.com/event/daybyday"))
        let html = """
        <html><head>
        <meta property="og:title" content="JUNGLE 3DAYS"/>
        </head><body>
        <div>会場お台場R地区</div>
        <div>TICKET INFO</div>
        <div>DAY1</div>
        <div>日時</div><div>2026/8/7(金)</div>
        <div>開場時刻 9:00 / 開演時刻 10:00</div>
        <div>DAY2</div>
        <div>日時</div><div>2026/8/8(土)</div>
        <div>開場時刻 10:00 / 開演時刻 11:00</div>
        <div>DAY3</div>
        <div>日時</div><div>2026/8/9(日)</div>
        <div>開場時刻 11:00 / 開演時刻 12:00</div>
        </body></html>
        """
        let details = try XCTUnwrap(TicketDiveEventPageParser().parse(html: html, sourceURL: sourceURL))

        XCTAssertEqual(details.scheduleOptions.count, 3)

        let cal = tokyoCalendar()

        // DAY1
        let opt1 = details.scheduleOptions[0]
        XCTAssertEqual(opt1.dayLabel, "DAY1")
        XCTAssertEqual(cal.component(.day, from: opt1.date), 7)
        let open1 = try XCTUnwrap(opt1.openTime)
        XCTAssertEqual(cal.component(.hour, from: open1), 9)
        let start1 = try XCTUnwrap(opt1.startTime)
        XCTAssertEqual(cal.component(.hour, from: start1), 10)

        // DAY2
        let opt2 = details.scheduleOptions[1]
        XCTAssertEqual(opt2.dayLabel, "DAY2")
        XCTAssertEqual(cal.component(.day, from: opt2.date), 8)
        let open2 = try XCTUnwrap(opt2.openTime)
        XCTAssertEqual(cal.component(.hour, from: open2), 10)
        let start2 = try XCTUnwrap(opt2.startTime)
        XCTAssertEqual(cal.component(.hour, from: start2), 11)

        // DAY3
        let opt3 = details.scheduleOptions[2]
        XCTAssertEqual(opt3.dayLabel, "DAY3")
        XCTAssertEqual(cal.component(.day, from: opt3.date), 9)
        let open3 = try XCTUnwrap(opt3.openTime)
        XCTAssertEqual(cal.component(.hour, from: open3), 11)
        let start3 = try XCTUnwrap(opt3.startTime)
        XCTAssertEqual(cal.component(.hour, from: start3), 12)
    }
}
