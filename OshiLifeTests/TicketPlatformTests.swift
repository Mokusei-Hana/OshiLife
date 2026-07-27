import Foundation
import XCTest
@testable import OshiLife

final class TicketPlatformTests: XCTestCase {
    func testDetectsPlatformsFromPurchaseURLs() throws {
        let cases: [(String, TicketPlatform)] = [
            ("https://eplus.jp/sf/detail/123", .ePlus),
            ("https://t.pia.jp/pia/event/event.do?eventCd=123", .ticketPia),
            ("https://l-tike.com/order/?gLcode=123", .lawsonTicket),
            ("https://t.livepocket.jp/e/example", .livePocket),
            ("https://tiget.net/events/123", .tiget),
            ("https://zaiko.io/event/123", .zaiko)
        ]

        for (rawURL, expectedPlatform) in cases {
            let url = try XCTUnwrap(URL(string: rawURL))
            XCTAssertEqual(TicketPlatform.detect(from: url), expectedPlatform)
        }
    }

    func testDoesNotMatchLookalikeOrUnsupportedHosts() throws {
        XCTAssertNil(TicketPlatform.detect(from: try XCTUnwrap(URL(string: "https://eplus.jp.example.com/tickets"))))
        XCTAssertNil(TicketPlatform.detect(from: try XCTUnwrap(URL(string: "https://example.com/tickets"))))
    }

    @MainActor
    func testPurchasedTicketUsesPlatformAccessPage() throws {
        let selectedTicket = TicketOption(name: "Sチケット", price: 9_000)
        let event = LiveEvent(
            artistName: "推し",
            title: "ライブ",
            eventDate: .now,
            ticketURLString: "https://eplus.jp/sf/detail/123",
            ticketOptions: [selectedTicket],
            selectedTicketID: selectedTicket.id
        )

        XCTAssertEqual(event.ticketActionURL, TicketPlatform.ePlus.ticketAccessURL)
    }

    @MainActor
    func testUnpurchasedAndUnknownPlatformTicketsUsePurchaseURL() throws {
        let ePlusPurchaseURL = try XCTUnwrap(URL(string: "https://eplus.jp/sf/detail/123"))
        let unpurchasedEvent = LiveEvent(
            artistName: "推し",
            title: "ライブ",
            eventDate: .now,
            ticketURLString: ePlusPurchaseURL.absoluteString
        )
        XCTAssertEqual(unpurchasedEvent.ticketActionURL, ePlusPurchaseURL)

        let selectedTicket = TicketOption(name: "一般")
        let unknownPurchaseURL = try XCTUnwrap(URL(string: "https://example.com/tickets/123"))
        let legacyEvent = LiveEvent(
            artistName: "推し",
            title: "ライブ",
            eventDate: .now,
            ticketURLString: unknownPurchaseURL.absoluteString,
            ticketOptions: [selectedTicket],
            selectedTicketID: selectedTicket.id
        )
        XCTAssertEqual(legacyEvent.ticketActionURL, unknownPurchaseURL)
    }
}
