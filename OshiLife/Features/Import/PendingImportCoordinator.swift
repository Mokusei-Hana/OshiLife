import Foundation
import Observation

@MainActor
@Observable
final class PendingImportCoordinator {
    private let pendingStore: PendingImportStore?
    private let liveStore: LiveStore

    var current: PendingShareImport?
    var currentImageData: Data?
    var duplicateEvent: LiveEvent?
    var errorMessage: String?

    init(pendingStore: PendingImportStore?, liveStore: LiveStore) {
        self.pendingStore = pendingStore
        self.liveStore = liveStore
    }

    func checkQueue() {
        guard current == nil, let pendingStore else { return }
        do {
            if let pending = try pendingStore.oldest() {
                try present(pending)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func open(url: URL) {
        guard url.scheme?.lowercased() == SharedConstants.importScheme,
              url.host?.lowercased() == "import",
              let idText = url.pathComponents.dropFirst().first,
              let id = UUID(uuidString: idText),
              let pendingStore else {
            errorMessage = String(localized: "error.invalid_import")
            return
        }
        do {
            try present(pendingStore.load(id: id))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func presentManual(_ pending: PendingShareImport) {
        current = pending
        currentImageData = pending.imageData
        do {
            duplicateEvent = try liveStore.event(sourceURLString: pending.sourceURL.absoluteString)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func discardCurrent() {
        if let id = current?.id { try? pendingStore?.remove(id: id) }
        clear()
        checkQueue()
    }

    func consumeCurrent() {
        discardCurrent()
    }

    func clear() {
        current = nil
        currentImageData = nil
        duplicateEvent = nil
    }

    private func present(_ pending: PendingShareImport) throws {
        current = pending
        currentImageData = try pendingStore?.imageData(for: pending)
        duplicateEvent = try liveStore.event(sourceURLString: pending.sourceURL.absoluteString)
    }
}
