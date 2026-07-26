import Foundation
import XCTest
@testable import OshiLife

final class GenericEventPageParserTests: XCTestCase {
    private let parser = GenericEventPageParser()

    private var tokyoCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }

    private func components(_ date: Date?) throws -> DateComponents {
        tokyoCalendar.dateComponents([.year, .month, .day, .hour, .minute], from: try XCTUnwrap(date))
    }

    func testSupportsGenericWebsitesButNotXOrShortLinks() throws {
        XCTAssertTrue(parser.supports(try XCTUnwrap(URL(string: "https://example.com/event/1"))))
        XCTAssertTrue(parser.supports(try XCTUnwrap(URL(string: "http://tickets.example.jp/live"))))
        XCTAssertFalse(parser.supports(try XCTUnwrap(URL(string: "https://x.com/oshi/status/42"))))
        XCTAssertFalse(parser.supports(try XCTUnwrap(URL(string: "https://twitter.com/oshi/status/42"))))
        XCTAssertFalse(parser.supports(try XCTUnwrap(URL(string: "https://t.co/abc"))))
        XCTAssertFalse(parser.supports(try XCTUnwrap(URL(string: "ftp://example.com/event"))))
    }

    func testParsesJSONLDEventPage() throws {
        let html = """
        <html><head>
        <script type="application/ld+json">
        {"@context":"https://schema.org","@type":"MusicEvent","name":"SUMMER SONIC 2026",
         "startDate":"2026-08-15T11:00:00+09:00","endDate":"2026-08-16T21:00:00+09:00",
         "doorTime":"2026-08-15T09:00:00+09:00",
         "location":{"@type":"Place","name":"ZOZOマリンスタジアム"},
         "image":"https://cdn.example.com/cover.jpg",
         "performer":[{"@type":"MusicGroup","name":"iLiFE!"},{"@type":"MusicGroup","name":"TENRIN"}],
         "offers":[{"@type":"Offer","name":"1DAY TICKET","price":"16500","description":"税込"},
                   {"@type":"Offer","name":"PLATINUM TICKET","price":33000}]}
        </script></head><body><p>本文</p></body></html>
        """
        let sourceURL = try XCTUnwrap(URL(string: "https://festival.example.com/2026"))

        let details = try XCTUnwrap(parser.parse(html: html, sourceURL: sourceURL))

        XCTAssertEqual(details.title, "SUMMER SONIC 2026")
        let day = try components(details.date)
        XCTAssertEqual([day.year, day.month, day.day], [2026, 8, 15])
        let end = try components(details.endDate)
        XCTAssertEqual([end.month, end.day], [8, 16])
        XCTAssertEqual(details.venue, "ZOZOマリンスタジアム")
        XCTAssertEqual(try components(details.openTime).hour, 9)
        XCTAssertEqual(try components(details.startTime).hour, 11)
        XCTAssertEqual(details.performers, ["iLiFE!", "TENRIN"])
        XCTAssertEqual(details.ticketOptions.map(\.name), ["1DAY TICKET", "PLATINUM TICKET"])
        XCTAssertEqual(details.ticketOptions.map(\.price), [16500, 33000])
        XCTAssertEqual(details.ticketOptions.first?.description, "税込")
        XCTAssertEqual(details.imageURL?.absoluteString, "https://cdn.example.com/cover.jpg")
        XCTAssertEqual(details.linkedURL, sourceURL)
    }

    func testSingleDayJSONLDEventDropsMatchingEndDate() throws {
        let html = """
        <script type="application/ld+json">
        {"@type":"Event","name":"ワンマン","startDate":"2026-09-23T18:00:00+09:00",
         "endDate":"2026-09-23T21:00:00+09:00","location":"Zepp Haneda"}
        </script>
        """
        let details = try XCTUnwrap(parser.parse(
            html: html,
            sourceURL: try XCTUnwrap(URL(string: "https://example.com/oneman"))
        ))

        XCTAssertNil(details.endDate)
        XCTAssertEqual(details.venue, "Zepp Haneda")
    }

    func testParsesAnnouncementTextAndOpenGraphMetadata() throws {
        let html = """
        <html><head>
        <meta property="og:title" content="ワンマンライブ2026特設サイト | チケットぴあ" />
        <meta property="og:site_name" content="チケットぴあ" />
        <meta property="og:image" content="/images/cover.jpg" />
        </head><body>
        <div>2026年9月23日(水)<br>
        会場：Zepp Haneda<br>
        OPEN 17:00 / START 18:00<br>
        料金：一般 ¥5,000 / 学生 ¥3,000</div>
        </body></html>
        """
        let sourceURL = try XCTUnwrap(URL(string: "https://ticket.example.jp/event/123"))

        let details = try XCTUnwrap(parser.parse(html: html, sourceURL: sourceURL))

        // No JSON-LD or quoted title, so the cleaned og:title is used.
        XCTAssertEqual(details.title, "ワンマンライブ2026特設サイト")
        let day = try components(details.date)
        XCTAssertEqual([day.year, day.month, day.day], [2026, 9, 23])
        XCTAssertEqual(details.venue, "Zepp Haneda")
        XCTAssertEqual(try components(details.openTime).hour, 17)
        XCTAssertEqual(try components(details.startTime).hour, 18)
        XCTAssertEqual(details.ticketOptions.map(\.name), ["一般", "学生"])
        XCTAssertEqual(details.imageURL?.absoluteString, "https://ticket.example.jp/images/cover.jpg")
    }

    func testPartialPageKeepsOnlyRecognizedFields() throws {
        let html = "<html><body><p>次回公演は2026年10月2日(金)です。詳細は追って発表します。</p></body></html>"

        let details = try XCTUnwrap(parser.parse(
            html: html,
            sourceURL: try XCTUnwrap(URL(string: "https://organizer.example.com/news/1"))
        ))

        let day = try components(details.date)
        XCTAssertEqual([day.year, day.month, day.day], [2026, 10, 2])
        XCTAssertNil(details.venue)
        XCTAssertNil(details.openTime)
        XCTAssertTrue(details.ticketOptions.isEmpty)
    }

    func testPageWithoutEventSignalsReturnsNil() throws {
        let html = """
        <html><head><title>Example Domain</title></head>
        <body><h1>Example Domain</h1><p>This domain is for use in illustrative examples.</p></body></html>
        """

        XCTAssertNil(parser.parse(
            html: html,
            sourceURL: try XCTUnwrap(URL(string: "https://example.com"))
        ))
    }
}
