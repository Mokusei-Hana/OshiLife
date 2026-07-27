import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import OshiLife

/// Regression tests for the X import pipeline order: extract URLs, resolve
/// t.co redirects, classify the final URLs, route to the site parser, and
/// treat the event website as the source of truth over the X post.
final class XImportURLResolutionTests: XCTestCase {
    /// Serves canned HTML per host and records every fetched URL, so importer
    /// tests never touch the network.
    private final class HostRoutingURLProtocolStub: URLProtocol, @unchecked Sendable {
        nonisolated(unsafe) static var responsesByHost: [String: (status: Int, html: String)] = [:]
        nonisolated(unsafe) static var requestedURLs: [URL] = []

        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

        override func startLoading() {
            let host = request.url?.host?.lowercased() ?? ""
            if let url = request.url { Self.requestedURLs.append(url) }
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

    /// Maps short links to fixed destinations; unknown URLs resolve to
    /// themselves, which is the resolver's failure fallback behavior.
    private struct StubShortLinkResolver: ShortLinkResolving {
        var resolutions: [URL: URL] = [:]

        func resolve(_ url: URL) async -> URL { resolutions[url] ?? url }
    }

    private func stubbedImporter(
        responsesByHost: [String: (status: Int, html: String)],
        resolutions: [URL: URL] = [:]
    ) -> EventLinkImporter {
        HostRoutingURLProtocolStub.responsesByHost = responsesByHost
        HostRoutingURLProtocolStub.requestedURLs = []
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [HostRoutingURLProtocolStub.self]
        return EventLinkImporter(
            session: URLSession(configuration: configuration),
            shortLinkResolver: StubShortLinkResolver(resolutions: resolutions)
        )
    }

    private let shortURL = URL(string: "https://t.co/SPT3fbKaK6")!
    private let ticketDiveURL = URL(string: "https://ticketdive.com/event/idolsummerjungle2026")!

    /// Condensed TicketDive festival page: an overall multi-day range with
    /// DAY blocks, day lineups and a slash-separated price listing.
    private let ticketDiveFestivalHTML = """
    <html><head>
    <title>IDOL SUMMER JUNGLE 2026 | TicketDive</title>
    <meta property="og:title" content="IDOL SUMMER JUNGLE 2026 | TicketDive"/>
    <meta property="og:site_name" content="TicketDive"/>
    </head><body>
    <div>IDOL SUMMER JUNGLE 2026</div>
    <div>公演日時2026/8/7(金)〜8/9(日)</div>
    <div>会場お台場R地区</div>
    <div>TICKET INFO販売情報</div>
    <div>DAY1日時2026/8/7(金)</div>
    <div>開場時刻 9:00 / 開演時刻 10:00</div>
    <div>出演アキシブproject/</div>
    <div>chuLa</div>
    <div>選択する</div>
    <div>DAY2日時2026/8/8(土)</div>
    <div>開場時刻 9:00 / 開演時刻 10:00</div>
    <div>出演iON!/</div>
    <div>TENRIN</div>
    <div>選択する</div>
    <div>DAY3日時2026/8/9(日)</div>
    <div>開場時刻 9:00 / 開演時刻 10:00</div>
    <div>出演iLiFE!</div>
    <div>選択する</div>
    <div>詳細『IDOL SUMMER JUNGLE 2026』</div>
    <div>日程：2026年8月7日(金)-9日(日)</div>
    <div>会場：お台場R地区</div>
    <div>開場 / 開演：09:00 / 10:00</div>
    <div>料金：VIPチケット ¥28,000 / 一般¥5,000- / 女性¥4,000-</div>
    </body></html>
    """

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

    // MARK: - t.co resolution and parser routing

    func testShortLinkResolvesToTicketDiveAndRoutesToItsParser() async throws {
        let importer = stubbedImporter(
            responsesByHost: ["ticketdive.com": (200, ticketDiveFestivalHTML)],
            resolutions: [shortURL: ticketDiveURL]
        )

        let imported = try await importer.importDetails(from: [shortURL])
        let details = try XCTUnwrap(imported)

        // The resolved URL — not the t.co link — reached the TicketDive parser.
        XCTAssertEqual(details.linkedURL, ticketDiveURL)
        XCTAssertEqual(details.shortenedLinkURLs, [shortURL])
        XCTAssertEqual(details.title, "IDOL SUMMER JUNGLE 2026")
        XCTAssertEqual(details.venue, "お台場R地区")
        try assertDay(details.date, year: 2026, month: 8, day: 7)
        try assertDay(details.endDate, year: 2026, month: 8, day: 9)
        XCTAssertEqual(details.ticketOptions.map(\.price), [28000, 5000, 4000])
        XCTAssertEqual(HostRoutingURLProtocolStub.requestedURLs, [ticketDiveURL])
    }

    func testDeduplicatesOriginalAndResolvedURLs() async throws {
        let importer = stubbedImporter(
            responsesByHost: ["ticketdive.com": (200, ticketDiveFestivalHTML)],
            resolutions: [shortURL: ticketDiveURL]
        )

        let imported = try await importer.importDetails(from: [shortURL, ticketDiveURL])
        let details = try XCTUnwrap(imported)

        XCTAssertEqual(details.linkedURL, ticketDiveURL)
        // The duplicate collapses into a single classification and fetch.
        XCTAssertEqual(HostRoutingURLProtocolStub.requestedURLs, [ticketDiveURL])
    }

    func testShortLinkResolutionFailureKeepsOriginalURLWithoutFailingImport() async throws {
        // No mapping: the resolver returns the original URL, its failure
        // fallback, and the import continues with the t.co link.
        let importer = stubbedImporter(responsesByHost: [:])

        let imported = try await importer.importDetails(from: [shortURL])
        let details = try XCTUnwrap(imported)

        XCTAssertEqual(details.linkedURL, shortURL)
        XCTAssertNil(details.title)
        XCTAssertTrue(details.ticketOptions.isEmpty)
    }

    func testShortLinkResolvingToXPostIsNotUsedAsEventLink() async throws {
        let postURL = try XCTUnwrap(URL(string: "https://x.com/iLiFE_official/status/99"))
        let importer = stubbedImporter(
            responsesByHost: [:],
            resolutions: [shortURL: postURL]
        )

        let details = try await importer.importDetails(from: [shortURL])

        XCTAssertNil(details)
    }

    func testShortLinkResolvedHeroinesPageKeepsExistingBehavior() async throws {
        let heroinesShortURL = try XCTUnwrap(URL(string: "https://t.co/heroines1"))
        let heroinesURL = try XCTUnwrap(URL(string: "https://heroines.jp/news/event"))
        let importer = stubbedImporter(
            responsesByHost: [
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
            ],
            resolutions: [heroinesShortURL: heroinesURL]
        )

        let imported = try await importer.importDetails(from: [heroinesShortURL])
        let details = try XCTUnwrap(imported)

        XCTAssertEqual(details.linkedURL, heroinesURL)
        XCTAssertEqual(details.shortenedLinkURLs, [heroinesShortURL])
        XCTAssertEqual(details.title, "「HEROINES LEAGUEⅠ」")
        XCTAssertEqual(details.venue, "Kanadevia Hall")
        XCTAssertEqual(details.performers, ["chuLa", "TENRIN", "iLiFE!"])
        XCTAssertEqual(details.ticketOptions.map(\.price), [9000, 4000])
        try assertDay(details.date, year: 2026, month: 5, day: 20)
    }

    // MARK: - Media placeholder URLs

    func testPicTwitterURLIsNeverTheEventOrTicketLink() async throws {
        let mediaURL = try XCTUnwrap(URL(string: "http://pic.twitter.com/T86Fe2z2Nb"))
        let fallbackURL = try XCTUnwrap(URL(string: "https://example.com/tickets"))
        let importer = stubbedImporter(responsesByHost: [:])

        let imported = try await importer.importDetails(from: [mediaURL, fallbackURL])
        let details = try XCTUnwrap(imported)

        // The media placeholder is skipped even though it appeared first.
        XCTAssertEqual(details.linkedURL, fallbackURL)
    }

    func testImportWithOnlyMediaPlaceholderURLsFindsNoLink() async throws {
        let importer = stubbedImporter(responsesByHost: [:])
        let urls = [
            try XCTUnwrap(URL(string: "http://pic.twitter.com/T86Fe2z2Nb")),
            try XCTUnwrap(URL(string: "https://pic.twitter.com/abc")),
            try XCTUnwrap(URL(string: "https://pic.x.com/def"))
        ]

        let details = try await importer.importDetails(from: urls)

        XCTAssertNil(details)
    }

    // MARK: - Partial TicketDive data

    func testTicketDivePartialDataKeepsPartialResult() async throws {
        let importer = stubbedImporter(
            responsesByHost: [
                "ticketdive.com": (200, """
                <html><head>
                <meta property="og:title" content="準備中イベント | TicketDive"/>
                <meta property="og:site_name" content="TicketDive"/>
                </head><body>
                <div>準備中イベント</div>
                <div>会場お台場R地区</div>
                </body></html>
                """)
            ],
            resolutions: [shortURL: ticketDiveURL]
        )

        let imported = try await importer.importDetails(from: [shortURL])
        let details = try XCTUnwrap(imported)

        XCTAssertEqual(details.linkedURL, ticketDiveURL)
        XCTAssertEqual(details.title, "準備中イベント")
        XCTAssertEqual(details.venue, "お台場R地区")
        XCTAssertNil(details.date)
        XCTAssertTrue(details.ticketOptions.isEmpty)
    }

    // MARK: - Website as source of truth over the X post

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

    func testMultiDayWebsiteDataIsNotOverriddenByPostDay() async throws {
        let canonicalURL = try XCTUnwrap(URL(string: "https://x.com/iLiFE_official/status/42"))
        let metadata = XOEmbedMetadata(
            canonicalURL: canonicalURL,
            authorName: "iLiFE!",
            postText: """
            2026年8月9日は！「IDOL SUMMER JUNGLE 2026」に出演いたします❤︎
            🎫チケット販売中！
            https://t.co/SPT3fbKaK6
            #iLiFE pic.twitter.com/T86Fe2z2Nb
            """,
            linkedURLs: [shortURL]
        )
        let importer = stubbedImporter(
            responsesByHost: ["ticketdive.com": (200, ticketDiveFestivalHTML)],
            resolutions: [shortURL: ticketDiveURL]
        )
        let builder = XImportDraftBuilder(
            client: StubXOEmbedClient(metadata: metadata),
            eventLinkImporter: importer,
            fxTwitterClient: StubFXTwitterClient(),
            imageDownloader: StubImageDownloader()
        )

        let draft = try await builder.makeDraft(from: canonicalURL)

        let details = try XCTUnwrap(draft.eventDetails)
        // The website's full range survives; the post's 8/9 mention does not
        // pick a day or reshape the range.
        XCTAssertEqual(details.linkedURL, ticketDiveURL)
        XCTAssertEqual(details.shortenedLinkURLs, [shortURL])
        try assertDay(details.date, year: 2026, month: 8, day: 7)
        try assertDay(details.endDate, year: 2026, month: 8, day: 9)
        XCTAssertEqual(details.title, "IDOL SUMMER JUNGLE 2026")
        XCTAssertEqual(details.venue, "お台場R地区")
        XCTAssertEqual(details.ticketOptions.map(\.price), [28000, 5000, 4000])
    }

    func testPostEndDateNeverAttachesToWebsiteSingleDay() throws {
        let websiteURL = try XCTUnwrap(URL(string: "https://ticketdive.com/event/single"))
        let websiteDay = Date(timeIntervalSince1970: 1_800_000_000)
        let website = EventImportDetails(date: websiteDay, linkedURL: websiteURL)
        let postText = EventImportDetails(
            date: websiteDay.addingTimeInterval(2 * 86_400),
            endDate: websiteDay.addingTimeInterval(4 * 86_400),
            linkedURL: websiteURL
        )

        let merged = website.fillingMissingFields(from: postText)

        XCTAssertEqual(merged.date, websiteDay)
        XCTAssertNil(merged.endDate)
    }

    func testMissingRangeIsStillFilledAsAWholeFromPostText() throws {
        let linkURL = try XCTUnwrap(URL(string: "https://example.com/event"))
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let end = start.addingTimeInterval(2 * 86_400)
        let bareLink = EventImportDetails(linkedURL: linkURL)
        let postText = EventImportDetails(date: start, endDate: end, linkedURL: linkURL)

        let merged = bareLink.fillingMissingFields(from: postText)

        XCTAssertEqual(merged.date, start)
        XCTAssertEqual(merged.endDate, end)
    }
}
