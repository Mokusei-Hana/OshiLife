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
