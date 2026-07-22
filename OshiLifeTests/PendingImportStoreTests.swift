import Foundation
import XCTest
@testable import OshiLife

final class PendingImportStoreTests: XCTestCase {
    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appending(path: "OshiLifeTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if FileManager.default.fileExists(atPath: temporaryDirectory.path) {
            try FileManager.default.removeItem(at: temporaryDirectory)
        }
    }

    func testStagesLoadsAndRemovesPayloadWithImage() throws {
        let store = PendingImportStore(rootURL: temporaryDirectory)
        let pending = PendingShareImport(
            sourceURL: try XCTUnwrap(URL(string: "https://x.com/oshi/status/42")),
            authorName: "推し",
            postText: "ライブ情報",
            createdAt: Date(timeIntervalSince1970: 100)
        )
        let imageData = Data([0x01, 0x02, 0x03])

        let staged = try store.stage(pending, imageData: imageData)
        XCTAssertNotNil(staged.imageRelativePath)
        XCTAssertEqual(try store.load(id: pending.id), staged)
        XCTAssertEqual(try store.imageData(for: staged), imageData)
        XCTAssertEqual(try store.oldest()?.id, pending.id)

        try store.remove(id: pending.id)
        XCTAssertNil(try store.oldest())
    }

    func testOldestUsesCreationDate() throws {
        let store = PendingImportStore(rootURL: temporaryDirectory)
        let url = try XCTUnwrap(URL(string: "https://x.com/oshi/status/42"))
        let newer = PendingShareImport(sourceURL: url, createdAt: Date(timeIntervalSince1970: 200))
        let older = PendingShareImport(sourceURL: url, createdAt: Date(timeIntervalSince1970: 100))
        _ = try store.stage(newer, imageData: nil)
        _ = try store.stage(older, imageData: nil)
        XCTAssertEqual(try store.oldest()?.id, older.id)
    }
}
