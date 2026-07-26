import Foundation

enum PendingImportStoreError: LocalizedError {
    case invalidIdentifier
    case missingPayload

    var errorDescription: String? {
        switch self {
        case .invalidIdentifier: String(localized: "error.invalid_import")
        case .missingPayload: String(localized: "error.missing_import")
        }
    }
}

struct PendingImportStore {
    private let rootURL: URL
    private let fileManager: FileManager

    init(rootURL: URL, fileManager: FileManager = .default) {
        self.rootURL = rootURL
        self.fileManager = fileManager
    }

    static func appGroup() throws -> PendingImportStore {
        try PendingImportStore(rootURL: FileManager.default.oshiLifeSharedContainerURL())
    }

    func stage(_ value: PendingShareImport, imageData: Data?) throws -> PendingShareImport {
        let incoming = rootURL.appending(path: SharedConstants.pendingDirectory, directoryHint: .isDirectory)
        let directory = incoming.appending(path: value.id.uuidString, directoryHint: .isDirectory)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        var staged = value
        let imageToStage = imageData?.isEmpty == false ? imageData : value.imageData
        staged.imageData = nil
        if let imageToStage, !imageToStage.isEmpty {
            let imageName = "shared-image"
            try imageToStage.write(to: directory.appending(path: imageName), options: .atomic)
            staged.imageRelativePath = "\(SharedConstants.pendingDirectory)/\(value.id.uuidString)/\(imageName)"
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(staged).write(to: directory.appending(path: "payload.json"), options: .atomic)
        return staged
    }

    func load(id: UUID) throws -> PendingShareImport {
        let url = payloadURL(id: id)
        guard fileManager.fileExists(atPath: url.path) else { throw PendingImportStoreError.missingPayload }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(PendingShareImport.self, from: Data(contentsOf: url))
    }

    func oldest() throws -> PendingShareImport? {
        let incoming = rootURL.appending(path: SharedConstants.pendingDirectory, directoryHint: .isDirectory)
        guard let directories = try? fileManager.contentsOfDirectory(
            at: incoming,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return nil }

        return directories.compactMap { directory -> PendingShareImport? in
            guard let id = UUID(uuidString: directory.lastPathComponent) else { return nil }
            return try? load(id: id)
        }.min(by: { $0.createdAt < $1.createdAt })
    }

    func imageData(for value: PendingShareImport) throws -> Data? {
        guard let path = value.imageRelativePath else { return nil }
        return try Data(contentsOf: rootURL.appending(path: path))
    }

    func remove(id: UUID) throws {
        let directory = rootURL
            .appending(path: SharedConstants.pendingDirectory, directoryHint: .isDirectory)
            .appending(path: id.uuidString, directoryHint: .isDirectory)
        guard fileManager.fileExists(atPath: directory.path) else { return }
        try fileManager.removeItem(at: directory)
    }

    private func payloadURL(id: UUID) -> URL {
        rootURL
            .appending(path: SharedConstants.pendingDirectory, directoryHint: .isDirectory)
            .appending(path: id.uuidString, directoryHint: .isDirectory)
            .appending(path: "payload.json")
    }
}
