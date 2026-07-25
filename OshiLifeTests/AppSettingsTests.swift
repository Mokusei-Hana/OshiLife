import Foundation
import SwiftUI
import XCTest
@testable import OshiLife

final class AppSettingsTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "AppSettingsTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testDefaults() {
        let settings = AppSettings(defaults: defaults)

        XCTAssertEqual(settings.accentColorMode, .oshiLifeDefault)
        XCTAssertEqual(settings.appearance, .system)
        XCTAssertEqual(settings.homeDisplayStyle, .card)
        XCTAssertEqual(settings.language, .system)
    }

    func testPersistsSelections() {
        let settings = AppSettings(defaults: defaults)
        settings.accentColorMode = .artworkColor
        settings.appearance = .dark
        settings.homeDisplayStyle = .list
        settings.language = .simplifiedChinese

        let reloaded = AppSettings(defaults: defaults)

        XCTAssertEqual(reloaded.accentColorMode, .artworkColor)
        XCTAssertEqual(reloaded.appearance, .dark)
        XCTAssertEqual(reloaded.homeDisplayStyle, .list)
        XCTAssertEqual(reloaded.language, .simplifiedChinese)
    }

    func testUnknownRawValuesFallBackToDefaults() {
        defaults.set("unknown", forKey: "settings.accentColorMode")
        defaults.set("unknown", forKey: "settings.appearance")
        defaults.set("unknown", forKey: "settings.homeDisplayStyle")
        defaults.set("unknown", forKey: "settings.language")

        let settings = AppSettings(defaults: defaults)

        XCTAssertEqual(settings.accentColorMode, .oshiLifeDefault)
        XCTAssertEqual(settings.appearance, .system)
        XCTAssertEqual(settings.homeDisplayStyle, .card)
        XCTAssertEqual(settings.language, .system)
    }

    func testMigratesLegacyHomeDisplayStyle() {
        defaults.set("list", forKey: "eventDisplayMode")

        let settings = AppSettings(defaults: defaults)

        XCTAssertEqual(settings.homeDisplayStyle, .list)
        XCTAssertEqual(defaults.string(forKey: "settings.homeDisplayStyle"), "list")
    }

    func testAppearanceColorSchemeMapping() {
        XCTAssertNil(AppAppearance.system.colorScheme)
        XCTAssertEqual(AppAppearance.light.colorScheme, ColorScheme.light)
        XCTAssertEqual(AppAppearance.dark.colorScheme, ColorScheme.dark)
    }
}
