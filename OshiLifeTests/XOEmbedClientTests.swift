import Foundation
import XCTest
@testable import OshiLife

final class XOEmbedClientTests: XCTestCase {
    private final class URLProtocolStub: URLProtocol, @unchecked Sendable {
        nonisolated(unsafe) static var response: (status: Int, data: Data) = (200, Data())

        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

        override func startLoading() {
            let value = Self.response
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: value.status,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: value.data)
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }

    func testExtractsPostParagraphAndDecodesHTML() {
        let html = #"<blockquote><p lang="ja">推し &amp; ライブ<br>最高！ <a href="https://t.co/x">pic.twitter.com/x</a></p>&mdash; Author</blockquote>"#
        let text = XOEmbedClient.postText(from: html)
        XCTAssertEqual(text, "推し & ライブ\n最高！ pic.twitter.com/x")
    }

    func testMissingParagraphIsRecoverable() {
        XCTAssertNil(XOEmbedClient.postText(from: "<blockquote>No paragraph</blockquote>"))
    }

    func testExtractsAndDeduplicatesLinkTargets() {
        let html = #"""
        <p>
          <a href="https://heroines.jp/news/event?a=1&amp;b=2">詳細</a>
          <a href="https://heroines.jp/news/event?a=1&amp;b=2">同じ詳細</a>
          <a href="mailto:info@example.com">メール</a>
        </p>
        """#

        XCTAssertEqual(
            XOEmbedClient.linkedURLs(from: html).map(\.absoluteString),
            ["https://heroines.jp/news/event?a=1&b=2"]
        )
    }

    func testFetchDecodesMetadata() async throws {
        URLProtocolStub.response = (200, Data(#"{"url":"https://x.com/oshi/status/42","author_name":"推し","author_url":"https://x.com/oshi","html":"<blockquote><p>ライブ情報</p></blockquote>"}"#.utf8))
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let client = XOEmbedClient(session: URLSession(configuration: configuration))

        let metadata = try await client.fetch(postURL: XCTUnwrap(URL(string: "https://x.com/oshi/status/42")))
        XCTAssertEqual(metadata.authorName, "推し")
        XCTAssertEqual(metadata.postText, "ライブ情報")
        XCTAssertEqual(metadata.canonicalURL.absoluteString, "https://x.com/oshi/status/42")
    }

    func testFetchRejectsHTTPErrorAndOversizedResponse() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let client = XOEmbedClient(session: URLSession(configuration: configuration))
        let postURL = try XCTUnwrap(URL(string: "https://x.com/oshi/status/42"))

        URLProtocolStub.response = (503, Data())
        do {
            _ = try await client.fetch(postURL: postURL)
            XCTFail("Expected an HTTP error")
        } catch let error as XOEmbedError {
            guard case .httpStatus(503) = error else { return XCTFail("Unexpected error: \(error)") }
        }

        URLProtocolStub.response = (200, Data(repeating: 0x20, count: XOEmbedClient.maximumResponseBytes + 1))
        do {
            _ = try await client.fetch(postURL: postURL)
            XCTFail("Expected a size error")
        } catch let error as XOEmbedError {
            guard case .responseTooLarge = error else { return XCTFail("Unexpected error: \(error)") }
        }
    }
}
