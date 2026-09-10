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
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    importNotices
                    identity
                    schedule
                    location
                    informationDestinations
                    if !viewModel.validationMessages.isEmpty {
                        EventSection(title: "validation.title") {
                            ForEach(viewModel.validationMessages, id: \.self) { message in
                                InlineNotice(message: message)
                            }
                        }
                    }
                }
                .padding(EventPresentation.inset)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(EventPresentation.background)
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
                    .fontWeight(.bold)
                    .disabled(!viewModel.canSave)
                    .accessibilityIdentifier("saveLiveButton")
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
        .tint(EventPresentation.accent)
        .presentationDragIndicator(.visible)
    }

    private var informationDestinations: some View {
        VStack(alignment: .leading, spacing: 14) {
            JournalHeading(title: "detail.information", symbol: "square.grid.2x2")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                NavigationLink {
                    editorPage("field.performers") {
                        EventSection(title: "field.performers") {
                            field("field.performers", text: $viewModel.performersText, lines: 6...16)
                        }
                    }
                } label: {
                    destination("field.performers", symbol: "person.2", preview: viewModel.performersText)
                }
                if !viewModel.ticketOptions.isEmpty {
                    NavigationLink {
                        editorPage("editor.tickets") { tickets }
                    } label: {
                        destination("editor.tickets", symbol: "ticket", preview: viewModel.ticketOptions.first(where: { $0.id == viewModel.selectedTicketID }).map(ticketLabel) ?? "")
                    }
                }
                NavigationLink {
                    editorPage("editor.links") { links }
                } label: {
                    destination("editor.links", symbol: "link", preview: viewModel.ticketURLString)
                }
                NavigationLink {
                    editorPage("field.notes") {
                        TextEditor(text: $viewModel.notes)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 360)
                            .accessibilityLabel(Text("field.notes"))
                            .journalSurface()
                    }
                } label: {
                    destination("field.notes", symbol: "text.alignleft", preview: viewModel.notes)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func destination(_ title: LocalizedStringKey, symbol: String, preview: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: symbol).font(.title2).foregroundStyle(EventPresentation.accent)
                Spacer()
                Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(.secondary)
            }
            Text(title).font(.headline).foregroundStyle(.primary)
            if !preview.isEmpty {
                Text(preview).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .topLeading)
        .journalSurface()
        .contentShape(.rect)
    }

    private func editorPage<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20, content: content)
                .padding(EventPresentation.inset)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
        }
        .background(EventPresentation.background)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private var importNotices: some View {
        if let duplicate {
            EventSection(title: "import.duplicate.title") {
                Text("import.duplicate.message \(duplicate.title)")
                    .font(.subheadline).foregroundStyle(.secondary)
                Button("import.duplicate.open") { onOpenDuplicate?() }
                    .buttonStyle(.bordered)
            }
        }
        if let warning = viewModel.importWarning {
            VStack(alignment: .leading, spacing: 12) {
                InlineNotice(message: warning)
                Button {
                    Task { await viewModel.retryImportMetadata() }
                } label: {
                    HStack {
                        Label("import.retry", systemImage: "arrow.clockwise")
                        Spacer()
                        if viewModel.isRetryingMetadata { ProgressView() }
                    }
                    .padding(.vertical, 8)
                }
                .disabled(viewModel.isRetryingMetadata)
            }
            .journalSurface()
        }
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: 20) {
            cover
                .frame(height: 210)
                .clipped()
                .clipShape(.rect(cornerRadius: 16))
                .accessibilityLabel(Text("field.cover"))
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) { coverActions }
                VStack(alignment: .leading, spacing: 12) { coverActions }
            }
            TicketRule()
            field("field.title", text: $viewModel.title, lines: 2...5, identifier: "titleField")
            VStack(alignment: .leading, spacing: 8) {
                Text("field.artist").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                TextField("field.artist", text: $viewModel.artistName)
                    .accessibilityIdentifier("artistField")
                    .textContentType(.organizationName)
                    .padding(14)
                    .background(EventPresentation.background, in: .rect(cornerRadius: 12))
            }
            Picker("field.status", selection: $viewModel.status) {
                ForEach(LiveStatus.allCases) { status in
                    Label(status.localizedName, systemImage: status.systemImage).tag(status)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(EventPresentation.background, in: .rect(cornerRadius: 12))
        }
        .journalSurface()
        .onChange(of: selectedPhoto) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    viewModel.coverImageData = data
                    viewModel.removesExistingCover = false
                }
            }
        }
    }

    @ViewBuilder private var coverActions: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            Label("cover.choose", systemImage: "photo.badge.plus")
                .padding(.vertical, 10)
        }

        if viewModel.coverImageData != nil || (!viewModel.removesExistingCover && viewModel.existingCoverPath != nil) {
            Button("cover.remove", role: .destructive) {
                viewModel.coverImageData = nil
                viewModel.removesExistingCover = true
                selectedPhoto = nil
            }
            .padding(.vertical, 10)
        }
    }

    @ViewBuilder private var cover: some View {
        if let data = viewModel.coverImageData, let image = UIImage(data: data) {
            GeometryReader { geometry in
                Image(uiImage: image).resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        } else {
            CoverImageView(
                relativePath: viewModel.removesExistingCover ? nil : viewModel.existingCoverPath,
                imageStore: imageStore,
                height: 210
            )
        }
    }

    private var schedule: some View {
        EventSection(title: "editor.schedule") {
            if let eventDate = viewModel.eventDate {
                DisclosureGroup(isExpanded: $showsCalendar) {
                    DatePicker("field.date", selection: Binding(
                        get: { viewModel.eventDate ?? eventDate },
                        set: { viewModel.eventDate = $0 }
                    ), displayedComponents: .date)
                    .datePickerStyle(.compact)
                    Button("field.date.clear", role: .destructive) { viewModel.eventDate = nil }
                        .padding(.vertical, 10)
                } label: {
                    HStack(spacing: 16) {
                        EventDateStamp(date: eventDate)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("field.date").font(.caption).foregroundStyle(.secondary)
                            Text(eventDate, format: .dateTime.year().month().day())
                                .font(.headline).foregroundStyle(.primary)
                        }
                    }
                }
            } else {
                Button("field.date.choose", systemImage: "calendar.badge.plus") {
                    viewModel.eventDate = .now
                    showsCalendar = true
                }
                .padding(.vertical, 12)
                .accessibilityIdentifier("chooseEventDateButton")
            }
            TicketRule()
            Toggle("field.open_time.enabled", isOn: $viewModel.hasOpenTime)
                .accessibilityIdentifier("openTimeToggle")
            if viewModel.hasOpenTime {
                DatePicker("field.open_time", selection: $viewModel.openTime, displayedComponents: .hourAndMinute)
            }
            Toggle("field.start_time.enabled", isOn: $viewModel.hasStartTime)
                .accessibilityIdentifier("startTimeToggle")
            if viewModel.hasStartTime {
                DatePicker("field.start_time", selection: $viewModel.startTime, displayedComponents: .hourAndMinute)
            }
        }
    }

    private var location: some View {
        EventSection(title: "editor.location") {
            Button { showsVenuePicker = true } label: {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.title2)
                        .padding(12)
                        .background(EventPresentation.accent.opacity(0.08), in: .rect(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 6) {
                        if viewModel.venue.isEmpty && viewModel.address.isEmpty {
                            Text("venue.choose").font(.headline)
                        } else {
                            Text(viewModel.venue).font(.headline).foregroundStyle(.primary)
                            if !viewModel.address.isEmpty {
                                Text(viewModel.address).font(.subheadline).foregroundStyle(.secondary)
                            }
                            Text("venue.change").font(.caption)
                        }
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right")
                }
                .padding(.vertical, 8)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            if !viewModel.venue.isEmpty || !viewModel.address.isEmpty {
                Button("venue.clear", role: .destructive) { viewModel.clearVenue() }
                    .padding(.vertical, 8)
            }
        }
    }

    private var tickets: some View {
        EventSection(title: "editor.tickets") {
            Text("field.selected_ticket").font(.caption).foregroundStyle(.secondary)
            ticketChoice(id: nil, title: String(localized: "ticket.none"), description: nil)
            Text("detail.available_tickets").font(.caption).foregroundStyle(.secondary)
            ForEach(viewModel.ticketOptions) { option in
                ticketChoice(id: option.id, title: ticketLabel(option), description: option.description)
            }
        }
    }

    private func ticketChoice(id: UUID?, title: String, description: String?) -> some View {
        Button {
            viewModel.selectedTicketID = id
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: viewModel.selectedTicketID == id ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(EventPresentation.accent)
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(.headline).foregroundStyle(.primary)
                    if let description, !description.isEmpty {
                        Text(description).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(EventPresentation.background, in: .rect(cornerRadius: 12))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(viewModel.selectedTicketID == id ? .isSelected : [])
    }

    private var links: some View {
        EventSection(title: "editor.links") {
            urlField("field.ticket_url", text: $viewModel.ticketURLString)
            if !viewModel.ticketURLString.isEmpty, LiveEvent.validHTTPURL(viewModel.ticketURLString) == nil {
                validationLabel("validation.ticket_url")
            }
            urlField("field.source_url", text: $viewModel.sourceURLString)
            if !viewModel.sourceURLString.isEmpty, LiveEvent.validHTTPURL(viewModel.sourceURLString) == nil {
                validationLabel("validation.source_url")
            }
        }
    }

    private func field(_ title: LocalizedStringKey, text: Binding<String>, lines: ClosedRange<Int>, identifier: String = "") -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            TextField(title, text: text, axis: .vertical)
                .lineLimit(lines)
                .padding(14)
                .background(EventPresentation.background, in: .rect(cornerRadius: 12))
                .accessibilityLabel(Text(title))
                .accessibilityIdentifier(identifier)
        }
    }

    private func urlField(_ title: LocalizedStringKey, text: Binding<String>) -> some View {
        field(title, text: text, lines: 2...5)
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
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
