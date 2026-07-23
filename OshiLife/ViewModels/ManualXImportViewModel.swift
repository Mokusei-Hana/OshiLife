import Foundation
import Observation

@MainActor
@Observable
final class ManualXImportViewModel {
    private let draftBuilder: XImportDraftBuilder
    private var didCheckClipboard = false

    var urlString = ""
    var clipboardSuggestion: URL?
    var isLoading = false
    var errorMessage: String?

    init(draftBuilder: XImportDraftBuilder = XImportDraftBuilder()) {
        self.draftBuilder = draftBuilder
    }

    var normalizedURL: URL? {
        XURLValidator.normalizedPostURL(from: urlString)
    }

    var canImport: Bool {
        !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    func checkClipboard(text: String?) {
        guard !didCheckClipboard else { return }
        didCheckClipboard = true
        clipboardSuggestion = text.flatMap(XURLValidator.firstPostURL(in:))
    }

    func useClipboardSuggestion() {
        guard let clipboardSuggestion else { return }
        urlString = clipboardSuggestion.absoluteString
        self.clipboardSuggestion = nil
        errorMessage = nil
    }

    func importDraft() async -> PendingShareImport? {
        guard let normalizedURL else {
            errorMessage = String(localized: "error.invalid_x_url")
            return nil
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            return try await draftBuilder.makeDraft(from: normalizedURL)
        } catch is CancellationError {
            return nil
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
