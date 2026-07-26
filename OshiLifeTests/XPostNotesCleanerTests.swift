import Foundation
import XCTest
@testable import OshiLife

final class XPostNotesCleanerTests: XCTestCase {
    func testRemovesMediaPlaceholderURLsInEveryRendering() {
        let text = """
        告知です pic.twitter.com/T86Fe2z2Nb
        写真 http://pic.twitter.com/abc123
        続報 https://pic.twitter.com/DEF456
        """

        let cleaned = XPostNotesCleaner.cleanedNotes(text)

        XCTAssertFalse(cleaned.contains("pic.twitter.com"))
        XCTAssertTrue(cleaned.contains("告知です"))
        XCTAssertTrue(cleaned.contains("写真"))
        XCTAssertTrue(cleaned.contains("続報"))
    }

    func testRemovesStoredURLsIncludingSchemelessRendering() throws {
        let shortURL = try XCTUnwrap(URL(string: "https://t.co/SPT3fbKaK6"))
        let eventURL = try XCTUnwrap(URL(string: "https://ticketdive.com/event/idolsummerjungle2026"))
        let sourceURL = try XCTUnwrap(URL(string: "https://x.com/iLiFE_official/status/42"))
        let text = """
        🎫チケット販売中！
        https://t.co/SPT3fbKaK6
        t.co/SPT3fbKaK6
        https://ticketdive.com/event/idolsummerjungle2026
        https://x.com/iLiFE_official/status/42
        """

        let cleaned = XPostNotesCleaner.cleanedNotes(text, removing: [shortURL, eventURL, sourceURL])

        XCTAssertEqual(cleaned, "🎫チケット販売中！")
    }

    func testKeepsProseHashtagsMentionsAndWarnings() {
        let text = """
        8月9日は！「IDOL SUMMER JUNGLE 2026」に出演いたします❤︎

        マジでガチでホンキでブチ熱い1日にするぞー！！！！！
        byうさ

        🎫チケット販売中！
        https://t.co/SPT3fbKaK6

        ※後日終演後特典会参加券の受付をいたします。（ @iLiFE_STAFF ）にてお知らせ予定。#iLiFE pic.twitter.com/T86Fe2z2Nb
        """
        let shortURL = URL(string: "https://t.co/SPT3fbKaK6")!

        let cleaned = XPostNotesCleaner.cleanedNotes(text, removing: [shortURL])

        XCTAssertFalse(cleaned.contains("pic.twitter.com/T86Fe2z2Nb"))
        XCTAssertFalse(cleaned.contains("t.co/SPT3fbKaK6"))
        XCTAssertTrue(cleaned.contains("「IDOL SUMMER JUNGLE 2026」に出演いたします❤︎"))
        XCTAssertTrue(cleaned.contains("マジでガチでホンキでブチ熱い1日にするぞー！！！！！"))
        XCTAssertTrue(cleaned.contains("#iLiFE"))
        XCTAssertTrue(cleaned.contains("@iLiFE_STAFF"))
        XCTAssertTrue(cleaned.contains("※後日終演後特典会参加券の受付をいたします。"))
    }

    func testCollapsesWhitespaceLeftByRemovedURLs() {
        let text = "本文\n\nhttps://t.co/abc\n\n\n続き   #tag"
        let cleaned = XPostNotesCleaner.cleanedNotes(text, removing: [URL(string: "https://t.co/abc")!])

        XCTAssertEqual(cleaned, "本文\n\n続き #tag")
    }

    func testTextWithoutNoiseIsUnchanged() {
        let text = "通常の告知\n#hashtag @mention"

        XCTAssertEqual(XPostNotesCleaner.cleanedNotes(text), text)
    }
}
