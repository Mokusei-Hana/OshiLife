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
    @State private var showsCalendar = false

    var body: some View {
        NavigationStack {
            Form {
                importNotices
                identity
                schedule
                location
                Section {
                    NavigationLink {
                        performersEditor
                    } label: {
                        editorDestination("field.performers", symbol: "person.2", value: viewModel.performersText)
                    }
                    if !viewModel.ticketOptions.isEmpty {
                        NavigationLink {
                            ticketEditor
                        } label: {
                            Label("editor.tickets", systemImage: "ticket")
                        }
                    }
                    NavigationLink {
                        linksEditor
                    } label: {
                        Label("editor.links", systemImage: "link")
                    }
                    NavigationLink {
                        notesEditor
                    } label: {
                        editorDestination("field.notes", symbol: "text.alignleft", value: viewModel.notes)
                    }
                } header: {
                    Text("detail.information")
                }
                if !viewModel.validationMessages.isEmpty {
                    Section("validation.title") {
                        ForEach(viewModel.validationMessages, id: \.self) { message in
                            InlineNotice(message: message)
                        }
                    }
                }
            }
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
                VenuePickerView { viewModel.selectVenue($0) }
            }
        }
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder private var importNotices: some View {
        if let duplicate {
            Section {
                Label("import.duplicate.title", systemImage: "doc.on.doc")
                    .font(.headline)
                Text("import.duplicate.message \(duplicate.title)")
                    .font(.subheadline).foregroundStyle(.secondary)
                Button("import.duplicate.open") { onOpenDuplicate?() }
            }
        }
        if let warning = viewModel.importWarning {
            Section {
                InlineNotice(message: warning)
                Button {
                    Task { await viewModel.retryImportMetadata() }
                } label: {
                    HStack {
                        Label("import.retry", systemImage: "arrow.clockwise")
                        Spacer()
                        if viewModel.isRetryingMetadata { ProgressView() }
                    }
                }
                .disabled(viewModel.isRetryingMetadata)
            }
        }
    }

    private var identity: some View {
        Section {
            HStack(alignment: .top, spacing: 16) {
                cover
                    .frame(width: 88, height: 112)
                    .clipShape(.rect(cornerRadius: 12))
                    .accessibilityLabel(Text("field.cover"))
                VStack(alignment: .leading, spacing: 12) {
                    TextField("field.title", text: $viewModel.title, axis: .vertical)
                        .font(.title2.bold())
                        .lineLimit(2...5)
                    TextField("field.artist", text: $viewModel.artistName)
                        .textContentType(.organizationName)
                        .font(.subheadline)
                }
            }
            .padding(.vertical, 12)
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label("cover.choose", systemImage: "photo.badge.plus")
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
            Picker("field.status", selection: $viewModel.status) {
                ForEach(LiveStatus.allCases) { status in
                    Label(status.localizedName, systemImage: status.systemImage).tag(status)
                }
            }
        }
    }

    @ViewBuilder private var cover: some View {
        if let data = viewModel.coverImageData, let image = UIImage(data: data) {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            CoverImageView(
                relativePath: viewModel.removesExistingCover ? nil : viewModel.existingCoverPath,
                imageStore: imageStore,
                height: 112
            )
        }
    }

    private var schedule: some View {
        Section("editor.schedule") {
            if let eventDate = viewModel.eventDate {
                DisclosureGroup(isExpanded: $showsCalendar) {
                    DatePicker("field.date", selection: Binding(
                        get: { eventDate },
                        set: { viewModel.eventDate = $0 }
                    ), displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    Button("field.date.clear", role: .destructive) { viewModel.eventDate = nil }
                } label: {
                    LabeledContent {
                        Text(eventDate, format: .dateTime.year().month().day())
                    } label: {
                        Label("field.date", systemImage: "calendar")
                    }
                }
            } else {
                Button("field.date.choose", systemImage: "calendar.badge.plus") {
                    viewModel.eventDate = .now
                    showsCalendar = true
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
    }

    private var location: some View {
        Section("editor.location") {
            Button { showsVenuePicker = true } label: {
                HStack(spacing: 16) {
                    Image(systemName: "location.circle").font(.title)
                    VStack(alignment: .leading, spacing: 4) {
                        if viewModel.venue.isEmpty && viewModel.address.isEmpty {
                            Text("venue.choose")
                        } else {
                            Text(viewModel.venue).foregroundStyle(.primary)
                            if !viewModel.address.isEmpty {
                                Text(viewModel.address).font(.caption).foregroundStyle(.secondary)
                            }
                            Text("venue.change").font(.caption)
                        }
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").font(.caption)
                }
                .padding(.vertical, 8)
            }
            if !viewModel.venue.isEmpty || !viewModel.address.isEmpty {
                Button("venue.clear", role: .destructive) { viewModel.clearVenue() }
            }
        }
    }

    private var performersEditor: some View {
        Form {
            Section("field.performers") {
                TextField("field.performers", text: $viewModel.performersText, axis: .vertical)
                    .lineLimit(6...16)
            }
        }
        .navigationTitle("field.performers")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var ticketEditor: some View {
        Form {
            Section("field.selected_ticket") {
                Picker("field.selected_ticket", selection: $viewModel.selectedTicketID) {
                    Text("ticket.none").tag(UUID?.none)
                    ForEach(viewModel.ticketOptions) { option in
                        Text(ticketLabel(option)).tag(Optional(option.id))
                    }
                }
                .pickerStyle(.inline)
            }
            Section("detail.available_tickets") {
                ForEach(viewModel.ticketOptions) { option in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(ticketLabel(option)).font(.headline)
                        if let description = option.description, !description.isEmpty {
                            Text(description).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("editor.tickets")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var linksEditor: some View {
        Form {
            Section("field.ticket_url") {
                urlField("field.ticket_url", text: $viewModel.ticketURLString)
                if !viewModel.ticketURLString.isEmpty, LiveEvent.validHTTPURL(viewModel.ticketURLString) == nil {
                    validationLabel("validation.ticket_url")
                }
            }
            Section("field.source_url") {
                urlField("field.source_url", text: $viewModel.sourceURLString)
                if !viewModel.sourceURLString.isEmpty, LiveEvent.validHTTPURL(viewModel.sourceURLString) == nil {
                    validationLabel("validation.source_url")
                }
            }
        }
        .navigationTitle("editor.links")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var notesEditor: some View {
        TextEditor(text: $viewModel.notes)
            .padding(16)
            .navigationTitle("field.notes")
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityLabel(Text("field.notes"))
    }

    private func editorDestination(_ title: LocalizedStringKey, symbol: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: symbol)
            if !value.isEmpty {
                Text(value).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    private func urlField(_ title: LocalizedStringKey, text: Binding<String>) -> some View {
        TextField(title, text: text, axis: .vertical)
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .lineLimit(2...5)
    }

    private func ticketLabel(_ option: TicketOption) -> String {
        guard let price = option.price else { return option.name }
        return "\(option.name) ¥\(price.formatted())"
    }

    private func validationLabel(_ key: LocalizedStringKey) -> some View {
        Label(key, systemImage: "exclamationmark.circle")
            .font(.caption)
            .foregroundStyle(.red)
    }
}
