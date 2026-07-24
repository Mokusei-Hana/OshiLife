import XCTest
@testable import OshiLife

final class AppVersionInfoTests: XCTestCase {
    func testLoadsVersionInformation() {
        let info = AppVersionInfo(infoDictionary: [
            "CFBundleDisplayName": "OshiLife Test",
            "CFBundleShortVersionString": "2.3",
            "CFBundleVersion": "45"
        ])

        XCTAssertEqual(info.applicationName, "OshiLife Test")
        XCTAssertEqual(info.version, "2.3")
        XCTAssertEqual(info.build, "45")
    }

    func testMissingVersionInformationUsesFallbacks() {
        let info = AppVersionInfo(infoDictionary: [:])

        XCTAssertFalse(info.applicationName.isEmpty)
        XCTAssertEqual(info.version, "—")
        XCTAssertEqual(info.build, "—")
    }
}
