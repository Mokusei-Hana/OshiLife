import XCTest
import UIKit
@testable import OshiLife

final class ImageStoreTests: XCTestCase {
    func testNormalizesAndDeletesImage() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "OshiLifeImageTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let source = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 16)).image { context in
            UIColor.systemPink.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 32, height: 16))
        }
        let data = try XCTUnwrap(source.pngData())
        let store = ImageStore(rootURL: directory)

        let path = try store.saveJPEG(data: data)
        XCTAssertTrue(path.hasPrefix("Images/"))
        XCTAssertNotNil(store.image(at: path))

        try store.remove(relativePath: path)
        XCTAssertNil(store.image(at: path))
    }

    func testRejectsInvalidImageData() {
        let store = ImageStore(rootURL: FileManager.default.temporaryDirectory)
        XCTAssertThrowsError(try store.saveJPEG(data: Data([0x00, 0x01])))
    }
}
