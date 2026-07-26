import Foundation
import SwiftUI

struct LiveEditorHost: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: LiveEditorViewModel
    let imageStore: ImageStore
    let onSaved: () -> Void

    init(store: LiveStore, imageStore: ImageStore, event: LiveEvent?, onSaved: @escaping () -> Void) {
        _viewModel = State(initialValue: LiveEditorViewModel(store: store, event: event))
        self.imageStore = imageStore
        self.onSaved = onSaved
    }

    var body: some View {
        LiveEditorView(viewModel: viewModel, imageStore: imageStore) {
            onSaved()
            dismiss()
        } onCancel: {
            dismiss()
        }
    }
}

struct ImportEditorHost: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: LiveEditorViewModel
    @State private var confirmsDiscard = false

    let imageStore: ImageStore
    let duplicate: LiveEvent?
    let onOpenDuplicate: (LiveEvent) -> Void
    let onSaved: () -> Void
    let onDiscard: () -> Void

    init(
        store: LiveStore,
        imageStore: ImageStore,
        pending: PendingShareImport,
        imageData: Data?,
        duplicate: LiveEvent?,
        onOpenDuplicate: @escaping (LiveEvent) -> Void,
        onSaved: @escaping () -> Void,
        onDiscard: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: LiveEditorViewModel(
            store: store,
            pendingImport: pending,
            pendingImageData: imageData
        ))
        self.imageStore = imageStore
        self.duplicate = duplicate
        self.onOpenDuplicate = onOpenDuplicate
        self.onSaved = onSaved
        self.onDiscard = onDiscard
    }

    var body: some View {
        LiveEditorView(
            viewModel: viewModel,
            imageStore: imageStore,
            duplicate: duplicate,
            onOpenDuplicate: {
                guard let duplicate else { return }
                dismiss()
                onOpenDuplicate(duplicate)
            },
            onSaved: {
                onSaved()
                dismiss()
            },
            onCancel: { confirmsDiscard = true }
        )
        .confirmationDialog("import.discard.title", isPresented: $confirmsDiscard, titleVisibility: .visible) {
            Button("import.discard.action", role: .destructive) {
                onDiscard()
                dismiss()
            }
            Button("common.continue_editing", role: .cancel) {}
        } message: {
            Text("import.discard.message")
        }
    }
}
