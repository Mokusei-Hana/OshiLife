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
        XCTAssertEqual(settings.customAccentColor, .oshiLifeDefault)
        XCTAssertEqual(settings.oshiColor, .purple)
        XCTAssertEqual(settings.homeDisplayStyle, .card)
        XCTAssertEqual(settings.language, .system)
    }

    func testPersistsSelections() {
        let settings = AppSettings(defaults: defaults)
        settings.accentColorMode = .oshiColor
        settings.appearance = .dark
        settings.customAccentColor = AccentColorValue(red: 0.1, green: 0.2, blue: 0.3)
        settings.oshiColor = .blue
        settings.homeDisplayStyle = .list
        settings.language = .simplifiedChinese

        let reloaded = AppSettings(defaults: defaults)

        XCTAssertEqual(reloaded.accentColorMode, .oshiColor)
        XCTAssertEqual(reloaded.appearance, .dark)
        XCTAssertEqual(
            reloaded.customAccentColor,
            AccentColorValue(red: 0.1, green: 0.2, blue: 0.3)
        )
        XCTAssertEqual(reloaded.oshiColor, .blue)
        XCTAssertEqual(reloaded.homeDisplayStyle, .list)
        XCTAssertEqual(reloaded.language, .simplifiedChinese)
    }

    func testUnknownRawValuesFallBackToDefaults() {
        defaults.set("unknown", forKey: "settings.accentColorMode")
        defaults.set("unknown", forKey: "settings.appearance")
        defaults.set("unknown", forKey: "settings.homeDisplayStyle")
        defaults.set("unknown", forKey: "settings.language")
        defaults.set("unknown", forKey: "settings.oshiColor")

        let settings = AppSettings(defaults: defaults)

        XCTAssertEqual(settings.accentColorMode, .oshiLifeDefault)
        XCTAssertEqual(settings.appearance, .system)
        XCTAssertEqual(settings.homeDisplayStyle, .card)
        XCTAssertEqual(settings.language, .system)
        XCTAssertEqual(settings.oshiColor, .purple)
    }

    func testInvalidCustomColorFallsBackToDefault() {
        defaults.set(Data("invalid".utf8), forKey: "settings.customAccentColor")

        let settings = AppSettings(defaults: defaults)

        XCTAssertEqual(settings.customAccentColor, .oshiLifeDefault)
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
