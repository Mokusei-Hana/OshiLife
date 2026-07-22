import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers

enum ImageStoreError: LocalizedError {
    case invalidImage
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage: String(localized: "error.invalid_image")
        case .encodingFailed: String(localized: "error.image_encoding")
        }
    }
}

struct ImageStore: Sendable {
    private let rootURL: URL
    private let fileManager: FileManager

    init(rootURL: URL, fileManager: FileManager = .default) {
        self.rootURL = rootURL
        self.fileManager = fileManager
    }

    static func appGroup() throws -> ImageStore {
        try ImageStore(rootURL: FileManager.default.oshiLifeSharedContainerURL())
    }

    func saveJPEG(data: Data) throws -> String {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw ImageStoreError.invalidImage
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 2_400
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw ImageStoreError.invalidImage
        }

        let directory = rootURL.appending(path: SharedConstants.imagesDirectory, directoryHint: .isDirectory)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let filename = "\(UUID().uuidString).jpg"
        let destinationURL = directory.appending(path: filename)
        guard let destination = CGImageDestinationCreateWithURL(
            destinationURL as CFURL,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else { throw ImageStoreError.encodingFailed }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.85] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw ImageStoreError.encodingFailed }
        return "\(SharedConstants.imagesDirectory)/\(filename)"
    }

    func image(at relativePath: String?) -> UIImage? {
        guard let relativePath else { return nil }
        return UIImage(contentsOfFile: rootURL.appending(path: relativePath).path)
    }

    func remove(relativePath: String?) throws {
        guard let relativePath else { return }
        let url = rootURL.appending(path: relativePath)
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }
}
