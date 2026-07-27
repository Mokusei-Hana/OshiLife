import Foundation
import XCTest
@testable import OshiLife

final class JapaneseEventTextParserTests: XCTestCase {
    private var tokyoCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }

    private func components(_ date: Date?) throws -> DateComponents {
        tokyoCalendar.dateComponents([.year, .month, .day, .hour, .minute], from: try XCTUnwrap(date))
    }

    func testParsesFullAnnouncementWithMultiDayRange() throws {
        let parsed = JapaneseEventTextParser.parse("""
        『IDOL SUMMER JUNGLE 2026』
        日程：2026年8月7日(金)-9日(日)
        会場：お台場R地区
        開場 / 開演：09:00 / 10:00
        料金：VIPチケット ¥28,000 / 一般 ¥5,000- / 女性 ¥4,000-
        ※通し券なし / 各税込 / 1D代別途
        """)

        XCTAssertEqual(parsed.title, "IDOL SUMMER JUNGLE 2026")
        let start = try components(parsed.date)
        XCTAssertEqual([start.year, start.month, start.day], [2026, 8, 7])
        let end = try components(parsed.endDate)
        XCTAssertEqual([end.year, end.month, end.day], [2026, 8, 9])
        XCTAssertEqual(parsed.venue, "お台場R地区")
        XCTAssertEqual(try components(parsed.openTime).hour, 9)
        XCTAssertEqual(try components(parsed.startTime).hour, 10)
        XCTAssertEqual(parsed.ticketOptions.map(\.name), ["VIPチケット", "一般", "女性"])
        XCTAssertEqual(parsed.ticketOptions.map(\.price), [28000, 5000, 4000])
        XCTAssertTrue(try XCTUnwrap(parsed.ticketInformation).contains("※通し券なし"))
    }

    func testParsesDateTimeLineWithOpenStart() throws {
        let parsed = JapaneseEventTextParser.parse("日時：2026年8月7日(金) OPEN 18:00 START 19:00")

        let day = try components(parsed.date)
        XCTAssertEqual([day.year, day.month, day.day], [2026, 8, 7])
        XCTAssertNil(parsed.endDate)
        let open = try components(parsed.openTime)
        XCTAssertEqual([open.day, open.hour, open.minute], [7, 18, 0])
        let start = try components(parsed.startTime)
        XCTAssertEqual([start.day, start.hour, start.minute], [7, 19, 0])
    }

    func testParsesFullWidthCharactersAndSeparators() throws {
        let parsed = JapaneseEventTextParser.parse("""
        日時：２０２６年８月７日（金）
        ＯＰＥＮ　１８：００／ＳＴＡＲＴ　１９：００
        会場：ＫＴ　Ｚｅｐｐ　Ｙｏｋｏｈａｍａ
        """)

        let day = try components(parsed.date)
        XCTAssertEqual([day.year, day.month, day.day], [2026, 8, 7])
        XCTAssertEqual(try components(parsed.openTime).hour, 18)
        XCTAssertEqual(try components(parsed.startTime).hour, 19)
        XCTAssertEqual(parsed.venue, "KT Zepp Yokohama")
    }

    func testParsesKaijoKaienTimesWithoutDate() throws {
        let parsed = JapaneseEventTextParser.parse("開場 13:00 / 開演 14:00")

        XCTAssertNil(parsed.date)
        XCTAssertEqual(try components(parsed.openTime).hour, 13)
        XCTAssertEqual(try components(parsed.startTime).hour, 14)
        XCTAssertTrue(parsed.hasEventSignals)
    }

    func testParsesSlashDateRangeAndLateNightTimes() throws {
        let parsed = JapaneseEventTextParser.parse("""
        2026/8/7(金)〜8/9(日)
        OPEN 24:30 / START 25:00
        """)

        let start = try components(parsed.date)
        XCTAssertEqual([start.month, start.day], [8, 7])
        let end = try components(parsed.endDate)
        XCTAssertEqual([end.month, end.day], [8, 9])
        // 24:30 / 25:00 roll over to the following day.
        let open = try components(parsed.openTime)
        XCTAssertEqual([open.day, open.hour, open.minute], [8, 0, 30])
        let startTime = try components(parsed.startTime)
        XCTAssertEqual([startTime.day, startTime.hour, startTime.minute], [8, 1, 0])
    }

    func testPrefersLabeledDateOverIncidentalDate() throws {
        let parsed = JapaneseEventTextParser.parse("""
        2026年7月29日(水) 発表
        日程：2026年8月7日(金)
        """)

        let day = try components(parsed.date)
        XCTAssertEqual([day.month, day.day], [8, 7])
    }

    func testParsesVenueFromAtMarkerButIgnoresHandles() throws {
        let venue = JapaneseEventTextParser.parse("""
        2026年7月29日(水)
        @ KT Zepp Yokohama
        """)
        XCTAssertEqual(venue.venue, "KT Zepp Yokohama")

        let handle = JapaneseEventTextParser.parse("""
        @oshi_official
        2026年7月29日(水)
        """)
        XCTAssertNil(handle.venue)
        XCTAssertNil(handle.title)
    }

    func testParsesPerformersWithMixedSeparators() {
        let parsed = JapaneseEventTextParser.parse("出演：iLiFE! / のんふぃく！ / TENRIN")
        XCTAssertEqual(parsed.performers, ["iLiFE!", "のんふぃく!", "TENRIN"])

        let multiline = JapaneseEventTextParser.parse("""
        出演：
        chuLa・TENRIN
        iLiFE!
        会場：Zepp Nagoya
        """)
        XCTAssertEqual(multiline.performers, ["chuLa", "TENRIN", "iLiFE!"])
        XCTAssertEqual(multiline.venue, "Zepp Nagoya")
    }

    func testParsesStandaloneTicketLinesWithoutTicketKeyword() {
        let parsed = JapaneseEventTextParser.parse("""
        Sチケット ¥9,000
        前方 ¥5,000
        一般 ¥2,000
        女性 ¥1,000
        学生 ¥500
        当日 ¥3,000
        """)

        XCTAssertEqual(parsed.ticketOptions.map(\.name), ["Sチケット", "前方", "一般", "女性", "学生", "当日"])
        XCTAssertEqual(parsed.ticketOptions.map(\.price), [9000, 5000, 2000, 1000, 500, 3000])
    }

    func testParsesYenSuffixPricesOnOneLine() {
        let parsed = JapaneseEventTextParser.parse("前売 3,000円 / 当日 3,500円")

        XCTAssertEqual(parsed.ticketOptions.map(\.name), ["前売", "当日"])
        XCTAssertEqual(parsed.ticketOptions.map(\.price), [3000, 3500])
    }

    func testPartialAnnouncementKeepsRecognizedFields() throws {
        let parsed = JapaneseEventTextParser.parse("2026年7月29日(水)")

        let day = try components(parsed.date)
        XCTAssertEqual([day.year, day.month, day.day], [2026, 7, 29])
        XCTAssertNil(parsed.venue)
        XCTAssertNil(parsed.openTime)
        XCTAssertTrue(parsed.performers.isEmpty)
        XCTAssertTrue(parsed.ticketOptions.isEmpty)
        XCTAssertTrue(parsed.hasEventSignals)
    }

    func testMalformedTicketLineDoesNotDiscardOtherFields() throws {
        let parsed = JapaneseEventTextParser.parse("""
        日程：2026年8月7日(金)
        料金：未定
        """)

        XCTAssertNotNil(parsed.date)
        XCTAssertTrue(parsed.ticketOptions.isEmpty)
        XCTAssertTrue(parsed.hasEventSignals)
    }

    func testUsesPlainFirstLineAsTitleFallback() {
        let parsed = JapaneseEventTextParser.parse("""
        超すごいライブ2026
        2026年9月1日(火)
        会場：Zepp Nagoya
        """)

        XCTAssertEqual(parsed.title, "超すごいライブ2026")
    }

    func testTextWithoutEventInformationHasNoSignals() throws {
        let parsed = JapaneseEventTextParser.parse("今日はいい天気ですね。散歩に行きます。")

        XCTAssertFalse(parsed.hasEventSignals)
        XCTAssertNil(parsed.details(linkedURL: try XCTUnwrap(URL(string: "https://x.com/oshi/status/1"))))
    }

    func testDetailsCarryAllRecognizedFields() throws {
        let linkedURL = try XCTUnwrap(URL(string: "https://example.com/event"))
        let parsed = JapaneseEventTextParser.parse("""
        『夏の単独公演』
        日程：2026年8月7日(金)-9日(日)
        会場：Zepp Shinjuku
        OPEN 17:00 / START 18:00
        出演：推しグループ
        一般 ¥5,000
        """)

        let details = try XCTUnwrap(parsed.details(linkedURL: linkedURL))
        XCTAssertEqual(details.title, "夏の単独公演")
        XCTAssertNotNil(details.date)
        XCTAssertNotNil(details.endDate)
        XCTAssertEqual(details.venue, "Zepp Shinjuku")
        XCTAssertNotNil(details.openTime)
        XCTAssertNotNil(details.startTime)
        XCTAssertEqual(details.performers, ["推しグループ"])
        XCTAssertEqual(details.ticketOptions.map(\.price), [5000])
        XCTAssertEqual(details.linkedURL, linkedURL)
    }
}
