import UIKit
import UniformTypeIdentifiers

@MainActor
final class ShareViewController: UIViewController {
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let actionButton = UIButton(type: .system)
    private var processingTask: Task<Void, Never>?
    private var hasStarted = false

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasStarted else { return }
        hasStarted = true
        processingTask = Task { await processShare() }
    }

    deinit {
        processingTask?.cancel()
    }

    private func configureUI() {
        view.backgroundColor = .systemBackground
        preferredContentSize = CGSize(width: 420, height: 250)

        titleLabel.text = String(localized: "share.title")
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center

        messageLabel.text = String(localized: "share.processing")
        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        spinner.startAnimating()
        actionButton.isHidden = true
        actionButton.configuration = .borderedProminent()
        actionButton.addTarget(self, action: #selector(finish), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [titleLabel, spinner, messageLabel, actionButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            actionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 140)
        ])
    }

    private func processShare() async {
        do {
            let providers = extensionContext?.inputItems
                .compactMap { $0 as? NSExtensionItem }
                .flatMap { $0.attachments ?? [] } ?? []
            guard let postURL = try await findPostURL(in: providers) else {
                showResult(message: String(localized: "share.invalid_url"), button: "common.close")
                return
            }

            async let imageData = firstImageData(in: providers)
            var pending = PendingShareImport(sourceURL: postURL)
            do {
                let metadata = try await XOEmbedClient().fetch(postURL: postURL)
                pending.sourceURL = metadata.canonicalURL
                pending.authorName = metadata.authorName
                pending.postText = metadata.postText
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                pending.warning = String(localized: "share.metadata_warning \(error.localizedDescription)")
            }

            try Task.checkCancellation()
            let store = try PendingImportStore.appGroup()
            pending = try store.stage(pending, imageData: await imageData)
            guard let handoffURL = URL(string: "\(SharedConstants.importScheme)://import/\(pending.id.uuidString)") else {
                throw PendingImportStoreError.invalidIdentifier
            }

            let didOpen = await requestOpen(handoffURL)
            if didOpen {
                extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            } else {
                showResult(message: String(localized: "share.queued"), button: "common.done")
            }
        } catch is CancellationError {
            extensionContext?.cancelRequest(withError: CancellationError())
        } catch {
            showResult(message: error.localizedDescription, button: "common.close")
        }
    }

    private func findPostURL(in providers: [NSItemProvider]) async throws -> URL? {
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            if let value = try await loadItem(provider, type: .url) {
                let url = (value as? URL) ?? (value as? NSURL).map { $0 as URL }
                if let url, let normalized = XURLValidator.normalizedPostURL(from: url) { return normalized }
            }
        }

        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            if let value = try await loadItem(provider, type: .plainText) {
                let text: String?
                if let string = value as? String {
                    text = string
                } else if let attributed = value as? NSAttributedString {
                    text = attributed.string
                } else if let data = value as? Data {
                    text = String(data: data, encoding: .utf8)
                } else {
                    text = nil
                }
                if let text, let url = XURLValidator.firstPostURL(in: text) { return url }
            }
        }
        return nil
    }

    private func firstImageData(in providers: [NSItemProvider]) async -> Data? {
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            if let data = try? await loadData(provider, type: .image),
               !data.isEmpty,
               data.count <= 25 * 1_024 * 1_024 {
                return data
            }
        }
        return nil
    }

    private func loadItem(_ provider: NSItemProvider, type: UTType) async throws -> NSSecureCoding? {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: type.identifier, options: nil) { item, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: item) }
            }
        }
    }

    private func loadData(_ provider: NSItemProvider, type: UTType) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: type.identifier) { data, error in
                if let error { continuation.resume(throwing: error) }
                else if let data { continuation.resume(returning: data) }
                else { continuation.resume(throwing: CocoaError(.fileReadUnknown)) }
            }
        }
    }

    private func requestOpen(_ url: URL) async -> Bool {
        guard let extensionContext else { return false }
        await withCheckedContinuation { continuation in
            extensionContext.open(url) { didOpen in
                continuation.resume(returning: didOpen)
            }
        }
    }

    private func showResult(message: String, button: LocalizedStringResource) {
        spinner.stopAnimating()
        spinner.isHidden = true
        messageLabel.text = message
        actionButton.setTitle(String(localized: button), for: .normal)
        actionButton.isHidden = false
    }

    @objc private func finish() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
