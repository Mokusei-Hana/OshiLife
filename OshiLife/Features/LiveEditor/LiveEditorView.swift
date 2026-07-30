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
    @State private var showsPerformerPicker = false
    @State private var showsAllSelectedPerformers = false
    private let collapsedPerformerLimit = 3

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
                    if viewModel.scheduleOptions.count > 1 {
                        scheduleDayPicker
                    }
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

                performerSection

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
            .sheet(isPresented: $showsPerformerPicker) {
                PerformerPickerView(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private var performerSection: some View {
        Section {
            TagFlowLayout(spacing: 8) {
                ForEach(visibleSelectedPerformers, id: \.self) { performer in
                    Button {
                        viewModel.removePerformer(performer)
                    } label: {
                        HStack(spacing: 6) {
                            Text(performer)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: 200)
                            Image(systemName: "xmark")
                                .font(.caption.bold())
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(.secondary.opacity(0.12), in: Capsule())
                    }
                    .frame(minHeight: 44)
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("performer.remove \(performer)"))
                }

                if viewModel.performers.count > collapsedPerformerLimit {
                    Button {
                        withAnimation(.snappy) {
                            showsAllSelectedPerformers.toggle()
                        }
                    } label: {
                        Label {
                            Text(
                                showsAllSelectedPerformers
                                    ? String(localized: "performer.show_less")
                                    : "+\(viewModel.performers.count - collapsedPerformerLimit)"
                            )
                        } icon: {
                            Image(systemName: showsAllSelectedPerformers ? "chevron.up" : "ellipsis")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(.secondary.opacity(0.12), in: Capsule())
                    }
                    .frame(minHeight: 44)
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("performer.show_more"))
                }

                Button {
                    showsPerformerPicker = true
                } label: {
                    Image(systemName: "plus")
                        .font(.subheadline.bold())
                        .frame(width: 42, height: 32)
                        .overlay {
                            Capsule()
                                .stroke(
                                    .secondary,
                                    style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                                )
                        }
                }
                .frame(minHeight: 44)
                .buttonStyle(.plain)
                .contentShape(Capsule())
                .accessibilityLabel(Text("performer.add"))
            }
            .padding(.vertical, 4)
        } header: {
            Text("field.performers")
        } footer: {
            Text("performer.help")
        }
    }

    private var visibleSelectedPerformers: ArraySlice<String> {
        showsAllSelectedPerformers
            ? viewModel.performers[...]
            : viewModel.performers.prefix(collapsedPerformerLimit)
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

    // MARK: - Day selector

    private var scheduleDayPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            scheduleChipRow(
                title: "schedule.participation",
                systemImage: "checkmark.circle"
            ) { option in
                participationChip(option)
            }

            scheduleChipRow(
                title: "schedule.editing",
                systemImage: "pencil"
            ) { option in
                editingChip(option)
            }
        }
        .padding(.vertical, 2)
    }

    private func scheduleChipRow<Chip: View>(
        title: LocalizedStringKey,
        systemImage: String,
        @ViewBuilder chip: @escaping (EventScheduleOption) -> Chip
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(viewModel.scheduleOptions) { option in
                        chip(option)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
            .defaultScrollAnchor(.leading)
        }
    }

    private func participationChip(_ option: EventScheduleOption) -> some View {
        let isSelected = viewModel.selectedScheduleOptionIDs.contains(option.id)

        return Button {
            viewModel.setScheduleParticipation(option, isSelected: !isSelected)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                Text(option.dayLabel)
                    .lineLimit(1)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(
                isSelected ? Color.accentColor.opacity(0.14) : Color.secondary.opacity(0.08),
                in: Capsule()
            )
        }
        .frame(minHeight: 44)
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel(
            Text("\(option.dayLabel), \(option.date.formatted(date: .abbreviated, time: .omitted))")
        )
        .accessibilityHint(
            Text(LocalizedStringKey(
                isSelected ? "schedule.remove_participation" : "schedule.add_participation"
            ))
        )
    }

    private func editingChip(_ option: EventScheduleOption) -> some View {
        let participates = viewModel.selectedScheduleOptionIDs.contains(option.id)
        let isActive = viewModel.activeScheduleOptionID == option.id

        return Button {
            viewModel.selectScheduleDay(option)
        } label: {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    if isActive {
                        Image(systemName: "pencil")
                            .font(.caption.bold())
                    }
                    Text(option.dayLabel)
                        .lineLimit(1)
                }
                Text(option.date, format: .dateTime.month().day().weekday())
                    .font(.caption2)
                    .opacity(0.8)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isActive ? Color.white : Color.primary)
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(
                isActive ? Color.accentColor : Color.secondary.opacity(0.1),
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
        .disabled(!participates)
        .opacity(participates ? 1 : 0.35)
        .accessibilityAddTraits(isActive ? .isSelected : [])
        .accessibilityLabel(
            Text("\(option.dayLabel), \(option.date.formatted(date: .abbreviated, time: .omitted))")
        )
        .accessibilityHint(Text("schedule.editing"))
    }
}
