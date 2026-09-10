import XCTest

final class OshiLifeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchesAndOpensNewLiveEditor() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(ja)"]
        app.launch()

        XCTAssertTrue(app.navigationBars["OshiLife"].waitForExistence(timeout: 5))
        let addButton = app.buttons["addLiveButton"].firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.tap()
        XCTAssertTrue(app.navigationBars["新しいライブ"].waitForExistence(timeout: 3))
    }

    func testOpensSettings() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(ja)"]
        app.launch()

        let settingsButton = app.buttons["settingsButton"].firstMatch
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()

        XCTAssertTrue(app.navigationBars["設定"].waitForExistence(timeout: 3))
    }
}

extension OshiLifeUITests {
    /// Exercise the actual view bindings and persisted model through the new editor.
    func testCreatesLiveAndReopensPersistedFields() {
        let app = japaneseApp()
        let title = "UI Journal \(UUID().uuidString.prefix(8))"
        app.buttons["addLiveButton"].firstMatch.tap()

        let titleField = app.descendants(matching: .any)["titleField"].firstMatch
        reveal(titleField, in: app)
        titleField.tap()
        titleField.typeText(title)
        let artist = app.textFields["artistField"]
        reveal(artist, in: app)
        artist.tap()
        artist.typeText("Journal Artist")
        let chooseDate = app.buttons["chooseEventDateButton"]
        reveal(chooseDate, in: app)
        chooseDate.tap()
        let save = app.buttons["saveLiveButton"]
        XCTAssertTrue(save.isEnabled)
        save.tap()

        app.terminate()
        app.launch()
        XCTAssertTrue(app.navigationBars["OshiLife"].waitForExistence(timeout: 5))
        let event = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", title)).firstMatch
        reveal(event, in: app)
        event.tap()
        app.buttons["editLiveButton"].tap()
        let savedTitle = app.descendants(matching: .any)["titleField"].firstMatch
        reveal(savedTitle, in: app)
        XCTAssertEqual(savedTitle.value as? String, title)
        XCTAssertEqual(app.textFields["artistField"].value as? String, "Journal Artist")
        app.navigationBars.buttons["キャンセル"].tap()

        app.buttons["liveActionsMenu"].tap()
        app.buttons["削除"].firstMatch.tap()
        app.buttons["削除"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["OshiLife"].waitForExistence(timeout: 3))
        XCTAssertFalse(event.exists)
    }

    func testManualImportValidationWithoutNetworkRequest() {
        let app = japaneseApp()
        app.buttons["manualXImportEntryButton"].tap()
        let action = app.buttons["manualXImportButton"]
        XCTAssertTrue(action.waitForExistence(timeout: 3))
        XCTAssertFalse(action.isEnabled)
        let field = app.descendants(matching: .any)["manualImportURLField"].firstMatch
        field.tap()
        field.typeText("https://example.com/not-an-x-post")
        XCTAssertTrue(action.isEnabled)
        action.tap()
        XCTAssertTrue(app.staticTexts["有効なX投稿URLではありません。"].waitForExistence(timeout: 3))
    }

    func testAllSettingsDestinationsRemainReachable() {
        let app = japaneseApp()
        app.buttons["settingsButton"].tap()
        for title in ["アプリの外観", "アクセントカラーモード", "表示言語", "このアプリについて"] {
            let destination = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", title)).firstMatch
            // Return to the top before looking for each independent settings destination.
            app.swipeDown()
            reveal(destination, in: app)
            destination.tap()
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 3))
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }

    private func japaneseApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(ja)"]
        app.launch()
        XCTAssertTrue(app.navigationBars["OshiLife"].waitForExistence(timeout: 5))
        return app
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        for _ in 0..<12 {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.exists && element.isHittable, "Expected a reachable control", file: file, line: line)
    }
}
