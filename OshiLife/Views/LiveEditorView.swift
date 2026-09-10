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
    @State private var showsVenuePicker = false

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
                                .buttonStyle(.borderless)
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

                Section("field.performers") {
                    TextField("field.performers", text: $viewModel.performersText, axis: .vertical)
                        .lineLimit(2...6)
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
                    Toggle("field.open_time.enabled", isOn: $viewModel.hasOpenTime)
                    if viewModel.hasOpenTime {
                        DatePicker("field.open_time", selection: $viewModel.openTime, displayedComponents: .hourAndMinute)
                    }
                    Toggle("field.start_time.enabled", isOn: $viewModel.hasStartTime)
                    if viewModel.hasStartTime {
                        DatePicker("field.start_time", selection: $viewModel.startTime, displayedComponents: .hourAndMinute)
                    }
                }

                Section("editor.location") {
                    if viewModel.venue.isEmpty && viewModel.address.isEmpty {
                        Button {
                            showsVenuePicker = true
                        } label: {
                            Label("venue.choose", systemImage: "map.fill")
                        }
                        .buttonStyle(.borderless)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Label {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(viewModel.venue)
                                        .font(.headline)
                                    if !viewModel.address.isEmpty {
                                        Text(viewModel.address)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            } icon: {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundStyle(.tint)
                            }

                            HStack {
                                Button("venue.change", systemImage: "map") {
                                    showsVenuePicker = true
                                }
                                .buttonStyle(.borderless)
                                Button("venue.clear", systemImage: "xmark", role: .destructive) {
                                    viewModel.clearVenue()
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                if !viewModel.ticketOptions.isEmpty {
                    Section("editor.tickets") {
                        Picker("field.selected_ticket", selection: $viewModel.selectedTicketID) {
                            Text("ticket.none").tag(UUID?.none)
                            ForEach(viewModel.ticketOptions) { option in
                                Text(ticketLabel(option)).tag(Optional(option.id))
                            }
                        }
                        ForEach(viewModel.ticketOptions) { option in
                            LabeledContent {
                                VStack(alignment: .trailing, spacing: 2) {
                                    if let price = option.price {
                                        Text("¥\(price.formatted())")
                                            .monospacedDigit()
                                    }
                                    if let description = option.description, !description.isEmpty {
                                        Text(description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            } label: {
                                Text(option.name)
                            }
                        }
                    }
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
                        .frame(minHeight: 140)
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
            .formStyle(.grouped)
            .scrollDismissesKeyboard(.interactively)
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
                    .buttonStyle(.glassProminent)
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
            .sheet(isPresented: $showsVenuePicker) {
                VenuePickerView { selection in
                    viewModel.selectVenue(selection)
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func ticketLabel(_ option: TicketOption) -> String {
        guard let price = option.price else { return option.name }
        return "\(option.name) ¥\(price.formatted())"
    }

    private var coverSection: some View {
        Section("field.cover") {
            Group {
                if let data = viewModel.coverImageData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .clipShape(.rect(cornerRadius: 18))
                } else if !viewModel.removesExistingCover, viewModel.existingCoverPath != nil {
                    CoverImageView(relativePath: viewModel.existingCoverPath, imageStore: imageStore, height: 220)
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
