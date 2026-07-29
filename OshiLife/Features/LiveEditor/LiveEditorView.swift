import PhotosUI
import SwiftUI

struct LiveEditorView: View {
    @Bindable var viewModel: LiveEditorViewModel
    let imageStore: ImageStore
    var duplicate: LiveEvent? = nil
    var onOpenDuplicate: (() -> Void)? = nil
    let onSaved: () -> Void
    let onCancel: () -> Void

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showsVenuePicker = false
    @State private var showsTicketEntry = false
    @State private var performerDraft = ""

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

                performerSection

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
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glassProminent)
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
                                .buttonStyle(.glass)
                                Button("venue.clear", systemImage: "xmark", role: .destructive) {
                                    viewModel.clearVenue()
                                }
                                .buttonStyle(.glass)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("editor.tickets") {
                    if viewModel.ticketOptions.isEmpty {
                        Text("ticket.empty")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
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
                        .onDelete { viewModel.removeTicketOptions(at: $0) }
                    }
                    Button("ticket.add", systemImage: "plus.circle") {
                        showsTicketEntry = true
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
            .sheet(isPresented: $showsVenuePicker) {
                VenuePickerView { selection in
                    viewModel.selectVenue(selection)
                }
            }
            .sheet(isPresented: $showsTicketEntry) {
                TicketEntryView { name, price, description in
                    viewModel.addTicketOption(name: name, price: price, description: description)
                }
                .presentationDetents([.medium])
            }
        }
    }

    private var performerSection: some View {
        Section {
            ForEach(viewModel.performers, id: \.self) { performer in
                HStack {
                    Label(performer, systemImage: "person.2.fill")
                    Spacer()
                    Button {
                        viewModel.removePerformer(performer)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("performer.remove \(performer)"))
                }
            }

            HStack {
                TextField("performer.add.placeholder", text: $performerDraft)
                    .textContentType(.organizationName)
                    .submitLabel(.done)
                    .onSubmit(addPerformer)
                Button(action: addPerformer) {
                    Image(systemName: "plus.circle.fill")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .disabled(performerDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel(Text("performer.add"))
            }
        } header: {
            Text("field.performers")
        } footer: {
            Text("performer.help")
        }
    }

    private func addPerformer() {
        if viewModel.addPerformer(performerDraft) {
            performerDraft = ""
        }
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
