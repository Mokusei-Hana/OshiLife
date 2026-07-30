import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import OshiLife

final class TicketDiveEventPageParserTests: XCTestCase {
    /// Serves canned HTML per host so importer tests never touch the network.
    private final class TicketDiveRoutingURLProtocolStub: URLProtocol, @unchecked Sendable {
        nonisolated(unsafe) static var responsesByHost: [String: (status: Int, html: String)] = [:]

        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

        override func startLoading() {
            let host = request.url?.host?.lowercased() ?? ""
            let stubbed = Self.responsesByHost[host] ?? (404, "")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: stubbed.status,
                httpVersion: nil,
                headerFields: ["Content-Type": "text/html; charset=utf-8"]
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(stubbed.html.utf8))
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }

    private func stubbedImporter(responsesByHost: [String: (status: Int, html: String)]) -> EventLinkImporter {
        TicketDiveRoutingURLProtocolStub.responsesByHost = responsesByHost
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [TicketDiveRoutingURLProtocolStub.self]
        return EventLinkImporter(session: URLSession(configuration: configuration))
    }

    private var tokyoCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }

    private func assertDay(
        _ date: Date?,
        year: Int,
        month: Int,
        day: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let date = try XCTUnwrap(date, file: file, line: line)
        let components = tokyoCalendar.dateComponents([.year, .month, .day], from: date)
        XCTAssertEqual(components.year, year, file: file, line: line)
        XCTAssertEqual(components.month, month, file: file, line: line)
        XCTAssertEqual(components.day, day, file: file, line: line)
    }

    private func assertTime(
        _ date: Date?,
        hour: Int,
        minute: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let date = try XCTUnwrap(date, file: file, line: line)
        let components = tokyoCalendar.dateComponents([.hour, .minute], from: date)
        XCTAssertEqual(components.hour, hour, file: file, line: line)
        XCTAssertEqual(components.minute, minute, file: file, line: line)
    }

    // MARK: - 1. Festival event page

    /// Condensed from a real TicketDive festival page: labels concatenated
    /// with their values, DAY blocks with lineups and purchase buttons, a
    /// 詳細 section repeating the announcement, and trailing notice sections.
    private let festivalHTML = """
    <html><head>
    <title>IDOL SUMMER JUNGLE 2026 | TicketDive</title>
    <meta property="og:title" content="IDOL SUMMER JUNGLE 2026 | TicketDive"/>
    <meta property="og:site_name" content="TicketDive"/>
    <meta property="og:image" content="https://storage.googleapis.com/ticketdive/ogp.webp"/>
    <script id="__NEXT_DATA__" type="application/json">{"props":{"pageProps":{"__superjsonProps":{"json":{"eventDetail":{"event":{"name":"IDOL SUMMER JUNGLE 2026","topImage":"https://storage.googleapis.com/playyte-ticket-prod_event/cover.jpeg"}}}}}}}</script>
    </head><body>
    <div>イベント主催者向けログイン</div>
    <div>IDOL SUMMER JUNGLE 2026</div>
    <div>公演日時2026/8/7(金)〜8/9(日)</div>
    <div>会場お台場R地区</div>
    <div>TICKET INFO販売情報</div>
    <div>受付中一般販売一般販売</div>
    <div>DAY1日時2026/8/7(金)</div>
    <div>開場時刻 9:00 / 開演時刻 10:00</div>
    <div>会場お台場R地区</div>
    <div>出演アキシブproject/</div>
    <div>Appare!/</div>
    <div>Mirror,Mirror/</div>
    <div>chuLa</div>
    <div>選択する</div>
    <div>受付中一般販売一般販売</div>
    <div>DAY2日時2026/8/8(土)</div>
    <div>開場時刻 9:00 / 開演時刻 10:00</div>
    <div>会場お台場R地区</div>
    <div>出演iON!/</div>
    <div>TENRIN</div>
    <div>選択する</div>
    <div>詳細『IDOL SUMMER JUNGLE 2026』</div>
    <div>日程：2026年8月7日(金)-9日(日)</div>
    <div>会場：お台場R地区</div>
    <div>開場 / 開演：09:00 / 10:00</div>
    <div>料金：VIPチケット ¥28,000 / 一般¥5,000- / 女性¥4,000-</div>
    <div>※通し券なし/各税込/1D代別途</div>
    <div>【公演に関する注意事項】</div>
    <div>※入場時、ドリンク代¥600別途必要</div>
    <div>※営利目的のチケット転売禁止</div>
    <div>公演に関するお問合せ先</div>
    <div>チケットサービスに関するお問い合わせは こちら から</div>
    <div>運営会社利用規約プライバシーポリシー</div>
    </body></html>
    """

    func testParsesFestivalEventPage() throws {
        let sourceURL = try XCTUnwrap(URL(string: "https://ticketdive.com/event/idolsummerjungle2026"))

        let details = try XCTUnwrap(TicketDiveEventPageParser().parse(html: festivalHTML, sourceURL: sourceURL))

        XCTAssertEqual(details.title, "IDOL SUMMER JUNGLE 2026")
        XCTAssertEqual(details.venue, "お台場R地区")
        XCTAssertEqual(details.linkedURL, sourceURL)
        try assertDay(details.date, year: 2026, month: 8, day: 7)
        try assertDay(details.endDate, year: 2026, month: 8, day: 9)
        try assertTime(details.openTime, hour: 9, minute: 0)
        try assertTime(details.startTime, hour: 10, minute: 0)
        XCTAssertEqual(details.performers, ["アキシブproject", "Appare!", "Mirror,Mirror", "chuLa"])
        XCTAssertEqual(details.ticketOptions.map(\.name), ["VIPチケット", "一般", "女性"])
        XCTAssertEqual(details.ticketOptions.map(\.price), [28000, 5000, 4000])
        // Prices inside notice sections must not become ticket options.
        XCTAssertFalse(details.ticketOptions.contains { $0.price == 600 })
        XCTAssertFalse(details.ticketInformation?.contains("転売") == true)
    }

    func testPrefersEmbeddedTopImageOverGenericOGImage() throws {
        let sourceURL = try XCTUnwrap(URL(string: "https://ticketdive.com/event/idolsummerjungle2026"))

        let details = try XCTUnwrap(TicketDiveEventPageParser().parse(html: festivalHTML, sourceURL: sourceURL))

        XCTAssertEqual(
            details.imageURL?.absoluteString,
            "https://storage.googleapis.com/playyte-ticket-prod_event/cover.jpeg"
        )
    }

    // MARK: - 2. Single-day event

    func testParsesSingleDayEvent() throws {
        let sourceURL = try XCTUnwrap(URL(string: "https://ticketdive.com/event/summer-oneman"))
        let html = """
        <html><head>
        <meta property="og:image" content="https://images.example.com/oneman.jpg"/>
        </head><body>
        <div>サマーワンマン2026</div>
        <div>公演日時</div><div>2026/9/12(土)</div>
        <div>会場</div><div>Zepp Haneda</div>
        <div>開場時刻 17:00 / 開演時刻 18:00</div>
        <div>料金</div>
        <div>前方 ¥5,000</div>
        <div>Sチケット 9000円</div>
        </body></html>
        """

        let details = try XCTUnwrap(TicketDiveEventPageParser().parse(html: html, sourceURL: sourceURL))

        XCTAssertEqual(details.title, "サマーワンマン2026")
        XCTAssertEqual(details.venue, "Zepp Haneda")
        XCTAssertEqual(details.imageURL?.absoluteString, "https://images.example.com/oneman.jpg")
        try assertDay(details.date, year: 2026, month: 9, day: 12)
        XCTAssertNil(details.endDate)
        try assertTime(details.openTime, hour: 17, minute: 0)
        try assertTime(details.startTime, hour: 18, minute: 0)
        XCTAssertEqual(details.ticketOptions.map(\.name), ["前方", "Sチケット"])
        XCTAssertEqual(details.ticketOptions.map(\.price), [5000, 9000])
    }

    // MARK: - 3. Multi-day event

    func testParsesMultiDayKanjiDateRange() throws {
        let sourceURL = try XCTUnwrap(URL(string: "https://www.ticketdive.com/event/threedays"))
        let html = """
        <html><body>
        <div>公演日時2026年8月7日(金)-9日(日)</div>
        <div>会場お台場R地区</div>
        </body></html>
        """

        let details = try XCTUnwrap(TicketDiveEventPageParser().parse(html: html, sourceURL: sourceURL))

        try assertDay(details.date, year: 2026, month: 8, day: 7)
        try assertDay(details.endDate, year: 2026, month: 8, day: 9)
        XCTAssertEqual(details.venue, "お台場R地区")
    }

    // MARK: - 4. DAY1/DAY2/DAY3 structure

    func testParsesDayBlocksWithoutOverallDateRange() throws {
        let sourceURL = try XCTUnwrap(URL(string: "https://ticketdive.com/event/daybyday"))
        let html = """
        <html><head>
        <meta property="og:title" content="JUNGLE 3DAYS"/>
        </head><body>
        <div>会場</div><div>お台場R地区</div>
        <div>TICKET INFO</div>
        <div>DAY1</div>
        <div>日時</div><div>2026/8/7(金)</div>
        <div>開場時刻 9:00 / 開演時刻 10:00</div>
        <div>料金:</div>
        <div>一般 ¥5,000-</div>
        <div>DAY2</div>
        <div>日時</div><div>2026/8/8(土)</div>
        <div>開場時刻 10:00 / 開演時刻 11:00</div>
        <div>料金:</div>
        <div>一般 ¥5,000-</div>
        <div>DAY3</div>
        <div>日時</div><div>2026/8/9(日)</div>
        <div>料金:</div>
        <div>一般 ¥5,000-</div>
        <div>VIPチケット ¥28,000</div>
        </body></html>
        """

        let details = try XCTUnwrap(TicketDiveEventPageParser().parse(html: html, sourceURL: sourceURL))

        // The overall range spans the day-specific dates.
        try assertDay(details.date, year: 2026, month: 8, day: 7)
        try assertDay(details.endDate, year: 2026, month: 8, day: 9)
        // DAY1 provides the headline OPEN/START.
        try assertTime(details.openTime, hour: 9, minute: 0)
        try assertTime(details.startTime, hour: 10, minute: 0)
        // Repeated day rows collapse into unique options.
        XCTAssertEqual(details.ticketOptions.map(\.name), ["一般", "VIPチケット"])
        XCTAssertEqual(details.ticketOptions.map(\.price), [5000, 28000])
        // Day-specific dates and times stay available as ticket information.
        let information = try XCTUnwrap(details.ticketInformation)
        XCTAssertTrue(information.contains("DAY2"))
        XCTAssertTrue(information.contains("2026/8/8(土)"))
        XCTAssertTrue(information.contains("開場時刻 10:00 / 開演時刻 11:00"))
    }

    // MARK: - 5. Multiple ticket types

    func testParsesMultipleTicketTypesWithDescriptions() throws {
        let sourceURL = try XCTUnwrap(URL(string: "https://ticketdive.com/event/tickets"))
        let html = """
        <html><body>
        <div>公演日時2026/10/3(土)</div>
        <div>チケット情報</div>
        <div>VIPチケット ¥28,000 特典会優先入場</div>
        <div>Sチケット 9000円</div>
        <div>一般¥5,000-</div>
        <div>女性¥4,000-</div>
        <div>前方 ¥5,000</div>
        </body></html>
        """

        let details = try XCTUnwrap(TicketDiveEventPageParser().parse(html: html, sourceURL: sourceURL))

        XCTAssertEqual(details.ticketOptions.map(\.name), ["VIPチケット", "Sチケット", "一般", "女性", "前方"])
        XCTAssertEqual(details.ticketOptions.map(\.price), [28000, 9000, 5000, 4000, 5000])
        XCTAssertEqual(details.ticketOptions.first?.description, "特典会優先入場")
    }

    func testParsesSlashSeparatedPriceListing() throws {
        let sourceURL = try XCTUnwrap(URL(string: "https://ticketdive.com/event/priceline"))
        let html = """
        <html><body>
        <div>公演日時2026/10/3(土)</div>
        <div>料金：VIPチケット ¥28,000 / 一般¥5,000- / 女性¥4,000-</div>
        </body></html>
        """

        let details = try XCTUnwrap(TicketDiveEventPageParser().parse(html: html, sourceURL: sourceURL))

        XCTAssertEqual(details.ticketOptions.map(\.name), ["VIPチケット", "一般", "女性"])
        XCTAssertEqual(details.ticketOptions.map(\.price), [28000, 5000, 4000])
    }

    // MARK: - 6. Price symbol normalization

    func testNormalizesTicketPriceSymbols() throws {
        let sourceURL = try XCTUnwrap(URL(string: "https://ticketdive.com/event/symbols"))
        let html = """
        <html><body>
        <div>公演日時2026/10/3(土)</div>
        <div>料金</div>
        <div>Aチケット ¥3,000</div>
        <div>Bチケット ￥4,500-</div>
        <div>Cチケット 5500円</div>
        <div>Dチケット ￥6,000円-</div>
        </body></html>
        """

        let details = try XCTUnwrap(TicketDiveEventPageParser().parse(html: html, sourceURL: sourceURL))

        XCTAssertEqual(details.ticketOptions.map(\.price), [3000, 4500, 5500, 6000])
        XCTAssertEqual(details.ticketOptions.compactMap(\.description), [])
    }

    // MARK: - 7. Missing ticket information

    func testImportsEventWithoutTicketInformation() throws {
        let sourceURL = try XCTUnwrap(URL(string: "https://ticketdive.com/event/no-tickets"))
        let html = """
        <html><body>
        <div>秋の単独公演</div>
        <div>公演日時2026/11/23(月)</div>
        <div>会場渋谷クアトロ</div>
        <div>開場時刻 18:00 / 開演時刻 19:00</div>
        </body></html>
        """

        let details = try XCTUnwrap(TicketDiveEventPageParser().parse(html: html, sourceURL: sourceURL))

        try assertDay(details.date, year: 2026, month: 11, day: 23)
        XCTAssertEqual(details.venue, "渋谷クアトロ")
        XCTAssertTrue(details.ticketOptions.isEmpty)
        XCTAssertNil(details.ticketInformation)
    }

    func testUnparsableTicketRowsKeepSectionEditableAsText() throws {
        let sourceURL = try XCTUnwrap(URL(string: "https://ticketdive.com/event/tba-tickets"))
        let html = """
        <html><body>
        <div>公演日時2026/11/23(月)</div>
        <div>チケット情報</div>
        <div>チケット料金は後日発表します。</div>
        </body></html>
        """

        let details = try XCTUnwrap(TicketDiveEventPageParser().parse(html: html, sourceURL: sourceURL))

        XCTAssertTrue(details.ticketOptions.isEmpty)
        // The section text survives so ticket options stay editable.
        XCTAssertTrue(details.ticketInformation?.contains("後日発表") == true)
    }

    // MARK: - 8. Missing OPEN/START

    func testImportsEventWithoutOpenAndStartTimes() throws {
        let sourceURL = try XCTUnwrap(URL(string: "https://ticketdive.com/event/no-times"))
        let html = """
        <html><body>
        <div>公演日時2026/12/5(土)</div>
        <div>会場豊洲PIT</div>
        <div>料金</div>
        <div>一般 ¥5,000-</div>
        </body></html>
        """

        let details = try XCTUnwrap(TicketDiveEventPageParser().parse(html: html, sourceURL: sourceURL))

        XCTAssertNil(details.openTime)
        XCTAssertNil(details.startTime)
        try assertDay(details.date, year: 2026, month: 12, day: 5)
        XCTAssertEqual(details.ticketOptions.map(\.price), [5000])
    }

    // MARK: - Performers

    func testParsesTrailingSlashPerformerList() throws {
        let sourceURL = try XCTUnwrap(URL(string: "https://ticketdive.com/event/lineup"))
        let html = """
        <html><body>
        <div>公演日時2026/10/3(土)</div>
        <div>会場お台場R地区</div>
        <div>出演アキシブproject/</div>
        <div>Mirror,Mirror/</div>
        <div>マジカル・パンチライン/</div>
        <div>chuLa</div>
        <div>選択する</div>
        </body></html>
        """

        let details = try XCTUnwrap(TicketDiveEventPageParser().parse(html: html, sourceURL: sourceURL))

        // Names keep their commas and interpuncts; only slashes separate.
        XCTAssertEqual(details.performers, ["アキシブproject", "Mirror,Mirror", "マジカル・パンチライン", "chuLa"])
    }

    func testParsesInlinePerformerList() throws {
        let sourceURL = try XCTUnwrap(URL(string: "https://ticketdive.com/event/lineup-inline"))
        let html = """
        <html><body>
        <div>公演日時2026/10/3(土)</div>
        <div>出演：chuLa / TENRIN / iLiFE!</div>
        </body></html>
        """

        let details = try XCTUnwrap(TicketDiveEventPageParser().parse(html: html, sourceURL: sourceURL))

        XCTAssertEqual(details.performers, ["chuLa", "TENRIN", "iLiFE!"])
    }

    func testKeepsUnseparatedPerformerLinesWithinTheirSchedule() throws {
        let sourceURL = try XCTUnwrap(URL(string: "https://ticketdive.com/event/multi-lineup"))
        let html = """
        <html><body>
        <div>DAY1</div>
        <div>日時2026/10/3(土)</div>
        <div>出演</div>
        <div>chuLa</div>
        <div>Mirror,Mirror</div>
        <div>選択する</div>
        <div>DAY2</div>
        <div>日時2026/10/4(日)</div>
        <div>出演</div>
        <div>TENRIN</div>
        <div>iLiFE!</div>
        <div>選択する</div>
        </body></html>
        """

        let details = try XCTUnwrap(TicketDiveEventPageParser().parse(html: html, sourceURL: sourceURL))

        XCTAssertEqual(details.scheduleOptions.count, 2)
        XCTAssertEqual(details.scheduleOptions[0].performers, ["chuLa", "Mirror,Mirror"])
        XCTAssertEqual(details.scheduleOptions[1].performers, ["TENRIN", "iLiFE!"])
    }

    // MARK: - 9. Fetch failure with X post fallback

    private struct StubXOEmbedClient: XOEmbedFetching {
        var metadata: XOEmbedMetadata

        func fetch(postURL: URL) async throws -> XOEmbedMetadata { metadata }
    }

    private struct StubFXTwitterClient: FXTwitterFetching {
        func fetch(postURL: URL) async throws -> FXTwitterMetadata {
            FXTwitterMetadata(canonicalURL: postURL, imageURLs: [])
        }
    }

    private struct StubImageDownloader: RemoteImageDataFetching {
        func fetchImage(from url: URL) async throws -> Data {
            throw URLError(.fileDoesNotExist)
        }
    }

    func testTicketDiveFetchFailureFallsBackToPostText() async throws {
        let canonicalURL = try XCTUnwrap(URL(string: "https://x.com/oshi/status/42"))
        let eventURL = try XCTUnwrap(URL(string: "https://ticketdive.com/event/idolsummerjungle2026"))
        let metadata = XOEmbedMetadata(
            canonicalURL: canonicalURL,
            authorName: "推し",
            postText: """
            「IDOL SUMMER JUNGLE 2026」に出演いたします!
            日程：2026年8月9日(日)
            会場：お台場R地区
            OPEN 9:00 / START 10:00
            一般 ¥5,000
            """,
            linkedURLs: [eventURL]
        )
        let importer = stubbedImporter(responsesByHost: ["ticketdive.com": (500, "")])
        let builder = XImportDraftBuilder(
            client: StubXOEmbedClient(metadata: metadata),
            eventLinkImporter: importer,
            fxTwitterClient: StubFXTwitterClient(),
            imageDownloader: StubImageDownloader()
        )

        let draft = try await builder.makeDraft(from: canonicalURL)

        let details = try XCTUnwrap(draft.eventDetails)
        // The TicketDive link is kept while the post text fills the fields.
        XCTAssertEqual(details.linkedURL, eventURL)
        XCTAssertEqual(details.title, "IDOL SUMMER JUNGLE 2026")
        XCTAssertEqual(details.venue, "お台場R地区")
        try assertDay(details.date, year: 2026, month: 8, day: 9)
        try assertTime(details.openTime, hour: 9, minute: 0)
        try assertTime(details.startTime, hour: 10, minute: 0)
        XCTAssertEqual(details.ticketOptions.map(\.price), [5000])
    }

    // MARK: - 10. heroines.jp import remains unchanged

    func testHeroinesImportBehaviorRemainsUnchanged() async throws {
        let ticketDiveLink = try XCTUnwrap(URL(string: "https://ticketdive.com/event/other"))
        let heroinesLink = try XCTUnwrap(URL(string: "https://heroines.jp/news/event"))
        let importer = stubbedImporter(responsesByHost: [
            "ticketdive.com": (200, """
            <html><body><div>公演日時2026/12/24(木)</div></body></html>
            """),
            "heroines.jp": (200, """
            <div>【公演概要】<br>
            2026年5月20日(水)<br>
            「HEROINES LEAGUEⅠ」<br>
            @ Kanadevia Hall<br>
            OPEN 13:30 / START 14:30<br>
            出演：chuLa / TENRIN / iLiFE!<br>
            ▼チケット情報<br>
            Sチケット ￥9,000<br>
            Aチケット ￥4,000</div>
            """)
        ])

        let imported = try await importer.importDetails(from: [ticketDiveLink, heroinesLink])
        let details = try XCTUnwrap(imported)

        // The heroines.jp parser still wins and keeps its established output.
        XCTAssertEqual(details.linkedURL, heroinesLink)
        XCTAssertEqual(details.title, "「HEROINES LEAGUEⅠ」")
        XCTAssertEqual(details.venue, "Kanadevia Hall")
        XCTAssertEqual(details.performers, ["chuLa", "TENRIN", "iLiFE!"])
        XCTAssertEqual(details.ticketOptions.map(\.price), [9000, 4000])
        try assertDay(details.date, year: 2026, month: 5, day: 20)
        try assertTime(details.openTime, hour: 13, minute: 30)
        try assertTime(details.startTime, hour: 14, minute: 30)
    }

    func testSupportsTicketDiveHostsOnly() throws {
        let parser = TicketDiveEventPageParser()

        XCTAssertTrue(parser.supports(try XCTUnwrap(URL(string: "https://ticketdive.com/event/a"))))
        XCTAssertTrue(parser.supports(try XCTUnwrap(URL(string: "https://www.ticketdive.com/event/a"))))
        XCTAssertFalse(parser.supports(try XCTUnwrap(URL(string: "https://heroines.jp/news/event"))))
        XCTAssertFalse(parser.supports(try XCTUnwrap(URL(string: "https://example.com/ticketdive"))))
    }

    // MARK: - Importer integration

    func testImporterParsesTicketDivePage() async throws {
        let link = try XCTUnwrap(URL(string: "https://ticketdive.com/event/idolsummerjungle2026"))
        let importer = stubbedImporter(responsesByHost: ["ticketdive.com": (200, festivalHTML)])

        let imported = try await importer.importDetails(from: [link])
        let details = try XCTUnwrap(imported)

        XCTAssertEqual(details.title, "IDOL SUMMER JUNGLE 2026")
        XCTAssertEqual(details.venue, "お台場R地区")
        try assertDay(details.date, year: 2026, month: 8, day: 7)
        try assertDay(details.endDate, year: 2026, month: 8, day: 9)
        try assertTime(details.openTime, hour: 9, minute: 0)
        try assertTime(details.startTime, hour: 10, minute: 0)
        XCTAssertEqual(details.ticketOptions.map(\.price), [28000, 5000, 4000])
        XCTAssertEqual(details.linkedURL, link)
    }

    func testNonEventTicketDivePageFallsBackToGenericParsing() async throws {
        let link = try XCTUnwrap(URL(string: "https://ticketdive.com/special/collab"))
        let importer = stubbedImporter(responsesByHost: [
            "ticketdive.com": (200, """
            <html><head><script type="application/ld+json">
            {"@type":"Event","name":"コラボイベント","startDate":"2026-11-03",
             "location":{"@type":"Place","name":"渋谷ストリーム"}}
            </script></head><body><p>コラボ開催!</p></body></html>
            """)
        ])

        let imported = try await importer.importDetails(from: [link])
        let details = try XCTUnwrap(imported)

        XCTAssertEqual(details.title, "コラボイベント")
        XCTAssertEqual(details.venue, "渋谷ストリーム")
        XCTAssertNotNil(details.date)
    }
}
