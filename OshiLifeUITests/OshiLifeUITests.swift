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
        XCTAssertTrue(app.buttons["displayModeMenu"].waitForExistence(timeout: 3))
        let addButton = app.buttons["addLiveButton"].firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.tap()
        XCTAssertTrue(app.navigationBars["新しいライブ"].waitForExistence(timeout: 3))
    }
}
