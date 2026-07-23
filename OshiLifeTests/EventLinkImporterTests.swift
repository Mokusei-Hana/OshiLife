import Foundation
import XCTest
@testable import OshiLife

final class EventLinkImporterTests: XCTestCase {
    func testParsesHeroinesEventPage() throws {
        let html = """
        <html><body>
        <h1>5月開催「HEROINES LEAGUEⅠ」公演概要とチケット販売に関するご案内</h1>
        <time>2026.04.30</time>
        <div>【公演概要】<br>
        2026年5月20日(水)<br>
        「HEROINES LEAGUEⅠ」<br>
        @ Kanadevia Hall<br>
        OPEN 13:30 / START 14:30<br>
        出演：chuLa / TENRIN / iLiFE!<br>
        ▼チケット情報<br>
        Sチケット ￥9,000<br>
        Aチケット ￥4,000</div>
        </body></html>
        """
        let sourceURL = try XCTUnwrap(URL(string: "https://heroines.jp/news/public/_/event.html"))

        let details = try XCTUnwrap(HeroinesEventPageParser().parse(html: html, sourceURL: sourceURL))

        XCTAssertEqual(details.title, "「HEROINES LEAGUEⅠ」")
        XCTAssertEqual(details.venue, "Kanadevia Hall")
        XCTAssertEqual(details.performers, ["chuLa", "TENRIN", "iLiFE!"])
        XCTAssertEqual(details.ticketOptions.map(\.name), ["Sチケット", "Aチケット"])
        XCTAssertEqual(details.ticketOptions.map(\.price), [9000, 4000])
        XCTAssertTrue(details.ticketInformation?.contains("￥9,000") == true)
        XCTAssertEqual(details.linkedURL, sourceURL)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        XCTAssertEqual(calendar.component(.year, from: try XCTUnwrap(details.date)), 2026)
        XCTAssertEqual(calendar.component(.month, from: try XCTUnwrap(details.date)), 5)
        XCTAssertEqual(calendar.component(.day, from: try XCTUnwrap(details.date)), 20)
        XCTAssertEqual(calendar.component(.hour, from: try XCTUnwrap(details.openTime)), 13)
        XCTAssertEqual(calendar.component(.hour, from: try XCTUnwrap(details.startTime)), 14)
    }

    func testParsesTicketDescriptionsAndDoesNotUsePublicationDate() throws {
        let sourceURL = try XCTUnwrap(URL(string: "https://heroines.jp/news/event-with-tickets"))
        let html = """
        <h1>掲載 2026.01.01 「春公演」</h1>
        <div>【公演概要】<br>
        2026年3月8日(日)<br>
        「春公演」<br>
        @ Zepp DiverCity<br>
        OPEN 16:00 / START 17:00<br>
        出演：A / B<br>
        ▼チケット情報<br>
        Sチケット ¥9,000 前方エリア<br>
        1Fチケット ¥4,000<br>
        2Fチケット ¥3,500</div>
        """

        let details = try XCTUnwrap(HeroinesEventPageParser().parse(html: html, sourceURL: sourceURL))

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        XCTAssertEqual(calendar.component(.month, from: try XCTUnwrap(details.date)), 3)
        XCTAssertEqual(details.ticketOptions[0].description, "前方エリア")
        XCTAssertEqual(details.ticketOptions.map(\.price), [9000, 4000, 3500])
    }

    func testRejectsNonEventHeroinesPageWithoutGuessing() throws {
        let sourceURL = try XCTUnwrap(URL(string: "https://heroines.jp/faq"))
        let html = "<html><body><h1>よくある質問</h1><p>会員登録について</p></body></html>"

        XCTAssertNil(HeroinesEventPageParser().parse(html: html, sourceURL: sourceURL))
    }

    func testParsesTitlePlacedBeforeDate() throws {
        let sourceURL = try XCTUnwrap(URL(string: "https://heroines.jp/news/older-event"))
        let html = """
        <h1>先行受付開始</h1>
        <div>【公演概要】<br>
        HEROINES FES 〜6周年記念LIVE〜<br>
        2025年5月5日（月・祝）<br>
        @ Spotify O-EAST<br>
        open 11:30 / start 12:00<br>
        前方チケット ¥10,000</div>
        """

        let details = try XCTUnwrap(HeroinesEventPageParser().parse(html: html, sourceURL: sourceURL))

        XCTAssertEqual(details.title, "HEROINES FES 〜6周年記念LIVE〜")
        XCTAssertEqual(details.venue, "Spotify O-EAST")
    }

    func testExtractsUniqueWebLinksFromTweetText() throws {
        let urls = EventLinkImporter.urls(
            in: "詳細 https://heroines.jp/news/1 と https://example.com/tickets"
        )

        XCTAssertEqual(urls.map(\.absoluteString), [
            "https://heroines.jp/news/1",
            "https://example.com/tickets"
        ])
    }

    func testUnsupportedWebsiteIsKeptAsLinkWithoutGuessedFields() async throws {
        let link = try XCTUnwrap(URL(string: "https://example.com/tickets/42"))

        let imported = try await EventLinkImporter().importDetails(from: [link])
        let details = try XCTUnwrap(imported)

        XCTAssertEqual(details.linkedURL, link)
        XCTAssertNil(details.title)
        XCTAssertNil(details.date)
        XCTAssertNil(details.venue)
        XCTAssertNil(details.startTime)
        XCTAssertTrue(details.performers.isEmpty)
    }

    func testEventDetailsDecodesPayloadsCreatedBeforeTicketOptions() throws {
        let sourceURL = try XCTUnwrap(URL(string: "https://heroines.jp/news/event"))
        let data = Data(#"{"linkedURL":"https://heroines.jp/news/event","performers":["A"],"title":"旧イベント"}"#.utf8)

        let details = try JSONDecoder().decode(EventImportDetails.self, from: data)

        XCTAssertEqual(details.linkedURL, sourceURL)
        XCTAssertEqual(details.title, "旧イベント")
        XCTAssertEqual(details.performers, ["A"])
        XCTAssertTrue(details.ticketOptions.isEmpty)
    }
}
