import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import OshiLife

final class ShortLinkResolverTests: XCTestCase {
    /// Serves canned responses keyed by "METHOD url" and records every
    /// request, so redirect walking is tested without any network access.
    private final class StubTransport: RedirectHTTPTransport, @unchecked Sendable {
        enum Outcome {
            case response(status: Int, headers: [String: String])
            case failure
        }

        private let lock = NSLock()
        private let outcomes: [String: Outcome]
        private var requestLog: [String] = []

        init(_ outcomes: [String: Outcome]) {
            self.outcomes = outcomes
        }

        var requests: [String] {
            lock.lock()
            defer { lock.unlock() }
            return requestLog
        }

        private func recordedOutcome(for key: String) -> Outcome? {
            lock.lock()
            defer { lock.unlock() }
            requestLog.append(key)
            return outcomes[key]
        }

        func send(_ request: URLRequest) async throws -> HTTPURLResponse {
            let url = try XCTUnwrap(request.url)
            let key = "\(request.httpMethod ?? "GET") \(url.absoluteString)"
            switch recordedOutcome(for: key) {
            case .response(let status, let headers):
                return try XCTUnwrap(HTTPURLResponse(
                    url: url,
                    statusCode: status,
                    httpVersion: nil,
                    headerFields: headers
                ))
            case .failure, nil:
                throw URLError(.cannotConnectToHost)
            }
        }
    }

    private let shortURL = URL(string: "https://t.co/SPT3fbKaK6")!
    private let eventURL = URL(string: "https://ticketdive.com/event/idolsummerjungle2026")!

    func testResolvesShortLinkThroughHeadRedirects() async {
        let transport = StubTransport([
            "HEAD https://t.co/SPT3fbKaK6":
                .response(status: 301, headers: ["Location": eventURL.absoluteString]),
            "HEAD https://ticketdive.com/event/idolsummerjungle2026":
                .response(status: 200, headers: [:])
        ])

        let resolved = await ShortLinkResolver(transport: transport).resolve(shortURL)

        XCTAssertEqual(resolved, eventURL)
        XCTAssertEqual(transport.requests, [
            "HEAD https://t.co/SPT3fbKaK6",
            "HEAD https://ticketdive.com/event/idolsummerjungle2026"
        ])
    }

    func testFallsBackToGetWhenHeadRequestFails() async {
        let transport = StubTransport([
            "GET https://t.co/SPT3fbKaK6":
                .response(status: 301, headers: ["Location": eventURL.absoluteString]),
            "GET https://ticketdive.com/event/idolsummerjungle2026":
                .response(status: 200, headers: [:])
        ])

        let resolved = await ShortLinkResolver(transport: transport).resolve(shortURL)

        XCTAssertEqual(resolved, eventURL)
        XCTAssertEqual(transport.requests, [
            "HEAD https://t.co/SPT3fbKaK6",
            "GET https://t.co/SPT3fbKaK6",
            "HEAD https://ticketdive.com/event/idolsummerjungle2026",
            "GET https://ticketdive.com/event/idolsummerjungle2026"
        ])
    }

    func testFallsBackToGetWhenHeadIsRejectedWithStatus() async {
        let transport = StubTransport([
            "HEAD https://t.co/SPT3fbKaK6": .response(status: 405, headers: [:]),
            "GET https://t.co/SPT3fbKaK6":
                .response(status: 302, headers: ["Location": eventURL.absoluteString]),
            "HEAD https://ticketdive.com/event/idolsummerjungle2026":
                .response(status: 200, headers: [:])
        ])

        let resolved = await ShortLinkResolver(transport: transport).resolve(shortURL)

        XCTAssertEqual(resolved, eventURL)
    }

    func testResolutionFailureFallsBackToOriginalURL() async {
        let transport = StubTransport([:])

        let resolved = await ShortLinkResolver(transport: transport).resolve(shortURL)

        XCTAssertEqual(resolved, shortURL)
    }

    func testRedirectLoopStopsAndFallsBackToOriginalURL() async {
        let transport = StubTransport([
            "HEAD https://t.co/SPT3fbKaK6":
                .response(status: 301, headers: ["Location": "https://a.example.com/x"]),
            "HEAD https://a.example.com/x":
                .response(status: 301, headers: ["Location": "https://b.example.com/y"]),
            "HEAD https://b.example.com/y":
                .response(status: 301, headers: ["Location": "https://a.example.com/x"])
        ])

        let resolved = await ShortLinkResolver(transport: transport).resolve(shortURL)

        XCTAssertEqual(resolved, shortURL)
        XCTAssertEqual(transport.requests.count, 3)
    }

    func testRedirectChainIsBoundedAndFallsBackToOriginalURL() async {
        var outcomes: [String: StubTransport.Outcome] = [
            "HEAD https://t.co/SPT3fbKaK6":
                .response(status: 301, headers: ["Location": "https://hop.example.com/1"])
        ]
        for hop in 1...20 {
            outcomes["HEAD https://hop.example.com/\(hop)"] =
                .response(status: 301, headers: ["Location": "https://hop.example.com/\(hop + 1)"])
        }
        let transport = StubTransport(outcomes)

        let resolved = await ShortLinkResolver(transport: transport).resolve(shortURL)

        XCTAssertEqual(resolved, shortURL)
        XCTAssertEqual(transport.requests.count, ShortLinkResolver.maximumRedirects)
    }

    func testResolvesRelativeRedirectLocation() async {
        let transport = StubTransport([
            "HEAD https://t.co/SPT3fbKaK6":
                .response(status: 301, headers: ["Location": "https://ticketdive.com/gate"]),
            "HEAD https://ticketdive.com/gate":
                .response(status: 302, headers: ["Location": "/event/idolsummerjungle2026"]),
            "HEAD https://ticketdive.com/event/idolsummerjungle2026":
                .response(status: 200, headers: [:])
        ])

        let resolved = await ShortLinkResolver(transport: transport).resolve(shortURL)

        XCTAssertEqual(resolved, eventURL)
    }

    func testRecognizesShortLinkHosts() {
        XCTAssertTrue(ShortLinkResolver.isShortLink(URL(string: "https://t.co/abc")!))
        XCTAssertTrue(ShortLinkResolver.isShortLink(URL(string: "http://t.co/abc")!))
        XCTAssertFalse(ShortLinkResolver.isShortLink(URL(string: "https://ticketdive.com/event/a")!))
        XCTAssertFalse(ShortLinkResolver.isShortLink(URL(string: "https://x.com/oshi/status/1")!))
    }
}
