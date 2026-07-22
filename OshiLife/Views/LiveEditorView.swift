import PhotosUI
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

struct LiveEditorView: View {
    @Bindable var viewModel: LiveEditorViewModel
    let imageStore: ImageStore
    var duplicate: LiveEvent? = nil
    var onOpenDuplicate: (() -> Void)? = nil
    let onSaved: () -> Void
    let onCancel: () -> Void

    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Form {
                if let duplicate {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("import.duplicate.title", systemImage: "doc.on.doc.fill")
                                .font(.headline)
                            Text("import.duplicate.message \(duplicate.title)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Button("import.duplicate.open") { onOpenDuplicate?() }
                                .buttonStyle(.glass)
                        }
                        .padding(.vertical, 4)
                    }
                }

                if let warning = viewModel.importWarning {
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            Label(warning, systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                            Button {
                                Task { await viewModel.retryImportMetadata() }
                            } label: {
                                if viewModel.isRetryingMetadata {
                                    ProgressView()
                                } else {
                                    Label("import.retry", systemImage: "arrow.clockwise")
                                }
                            }
                            .disabled(viewModel.isRetryingMetadata)
                        }
                    }
                }

                coverSection

                Section("editor.basic") {
                    TextField("field.artist", text: $viewModel.artistName)
                        .textContentType(.organizationName)
                    TextField("field.title", text: $viewModel.title, axis: .vertical)
                        .lineLimit(1...3)
                    Picker("field.status", selection: $viewModel.status) {
                        ForEach(LiveStatus.allCases) { status in
                            Label(status.localizedName, systemImage: status.systemImage).tag(status)
                        }
                    }
                }

                Section("editor.schedule") {
                    if let eventDate = viewModel.eventDate {
                        DatePicker(
                            "field.date",
                            selection: Binding(
                                get: { eventDate },
                                set: { viewModel.eventDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                        Button("field.date.clear", role: .destructive) { viewModel.eventDate = nil }
                    } else {
                        Button("field.date.choose", systemImage: "calendar.badge.plus") {
                            viewModel.eventDate = .now
                        }
                    }
                    Toggle("field.start_time.enabled", isOn: $viewModel.hasStartTime)
                    if viewModel.hasStartTime {
                        DatePicker("field.start_time", selection: $viewModel.startTime, displayedComponents: .hourAndMinute)
                    }
                }

                Section("editor.location") {
                    TextField("field.venue", text: $viewModel.venue)
                    TextField("field.address", text: $viewModel.address, axis: .vertical)
                        .lineLimit(1...3)
                }

                Section("editor.links") {
                    TextField("field.ticket_url", text: $viewModel.ticketURLString)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if !viewModel.ticketURLString.isEmpty, LiveEvent.validHTTPURL(viewModel.ticketURLString) == nil {
                        validationLabel("validation.ticket_url")
                    }
                    TextField("field.source_url", text: $viewModel.sourceURLString)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if !viewModel.sourceURLString.isEmpty, LiveEvent.validHTTPURL(viewModel.sourceURLString) == nil {
                        validationLabel("validation.source_url")
                    }
                }

                Section("field.notes") {
                    TextEditor(text: $viewModel.notes)
                        .frame(minHeight: 120)
                }

                if !viewModel.validationMessages.isEmpty {
                    Section("validation.title") {
                        ForEach(viewModel.validationMessages, id: \.self) { message in
                            Label(message, systemImage: "exclamationmark.circle")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle(viewModel.isEditing ? "editor.edit_title" : "editor.new_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") {
                        if viewModel.save(imageStore: imageStore) != nil { onSaved() }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .alert("common.error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("common.ok") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var coverSection: some View {
        Section("field.cover") {
            Group {
                if let data = viewModel.coverImageData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 190)
                        .frame(maxWidth: .infinity)
                        .clipShape(.rect(cornerRadius: 18))
                } else if !viewModel.removesExistingCover, viewModel.existingCoverPath != nil {
                    CoverImageView(relativePath: viewModel.existingCoverPath, imageStore: imageStore, height: 190)
                        .clipShape(.rect(cornerRadius: 18))
                }
            }

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label("cover.choose", systemImage: "photo.on.rectangle")
            }
            .onChange(of: selectedPhoto) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        viewModel.coverImageData = data
                        viewModel.removesExistingCover = false
                    }
                }
            }

            if viewModel.coverImageData != nil || (!viewModel.removesExistingCover && viewModel.existingCoverPath != nil) {
                Button("cover.remove", role: .destructive) {
                    viewModel.coverImageData = nil
                    viewModel.removesExistingCover = true
                    selectedPhoto = nil
                }
            }
        }
    }

    private func validationLabel(_ key: LocalizedStringKey) -> some View {
        Label(key, systemImage: "exclamationmark.circle")
            .font(.caption)
            .foregroundStyle(.red)
    }
}
