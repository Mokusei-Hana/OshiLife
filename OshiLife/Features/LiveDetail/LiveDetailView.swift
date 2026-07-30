import SwiftUI

struct LiveDetailView: View {
    let event: LiveEvent
    let imageStore: ImageStore
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var confirmsDelete = false
    @State private var showsMapOptions = false
    @State private var mapError: String?

    init(
        event: LiveEvent,
        imageStore: ImageStore,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.event = event
        self.imageStore = imageStore
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                eventHeader

                infoSection

                if !event.performers.isEmpty {
                    detailSection("field.performers") {
                        Text(event.performers.joined(separator: " / "))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                }

                if !event.ticketOptions.isEmpty || event.ticketURL != nil {
                    ticketSection
                }

                if !event.notes.isEmpty {
                    detailSection("field.notes") {
                        Text(event.notes)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                }

                if event.sourceURL != nil {
                    detailSection("detail.links") {
                        GlassEffectContainer(spacing: 12) {
                            VStack(spacing: 12) {
                                if let sourceURL = event.sourceURL {
                                    Link(destination: sourceURL) {
                                        Label("detail.source", systemImage: "link")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.glass)
                                }
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
        .navigationTitle("detail.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("common.edit", systemImage: "pencil", action: onEdit)
                Button("common.delete", systemImage: "trash", role: .destructive) { confirmsDelete = true }
            }
        }
        .confirmationDialog("delete.title", isPresented: $confirmsDelete, titleVisibility: .visible) {
            Button("common.delete", role: .destructive, action: onDelete)
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("delete.message")
        }
        .alert("common.error", isPresented: Binding(
            get: { mapError != nil },
            set: { if !$0 { mapError = nil } }
        )) {
            Button("common.ok") { mapError = nil }
        } message: {
            Text(mapError ?? "")
        }
    }

    private var eventHeader: some View {
        VStack(alignment: .leading, spacing: 18) {
            CoverImageView(
                relativePath: event.coverImagePath,
                imageStore: imageStore,
                aspectRatio: 4.0 / 5.0
            )
            .clipShape(.rect(cornerRadius: DesignRadius.large))
            .overlay(alignment: .top) {
                HStack(alignment: .top) {
                    if !event.scheduleLabel.isEmpty {
                        ScheduleBadge(label: event.scheduleLabel)
                    }
                    Spacer(minLength: 8)
                    StatusBadge(status: event.status)
                }
                .padding(16)
            }
            .shadow(color: .black.opacity(0.16), radius: 18, y: 10)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity, alignment: .center)

            VStack(alignment: .leading, spacing: 8) {
                if !event.artistName.isEmpty {
                    Text(event.artistName)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                Text(event.title)
                    .font(.largeTitle.bold())
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var infoSection: some View {
        detailSection("detail.information") {
            VStack(alignment: .leading, spacing: 16) {
                Label {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(event.eventDate, format: .dateTime.year().month().day().weekday())

                        if event.openTime != nil || event.startTime != nil {
                            HStack(alignment: .top, spacing: 16) {
                                if let openTime = event.openTime {
                                    timeDisplay(
                                        title: "field.open_time",
                                        time: openTime,
                                        isProminent: false
                                    )
                                }
                                if event.openTime != nil, event.startTime != nil {
                                    Divider()
                                }
                                if let startTime = event.startTime {
                                    timeDisplay(
                                        title: "field.start_time",
                                        time: startTime,
                                        isProminent: true
                                    )
                                }
                            }
                        }
                    }
                } icon: {
                    Image(systemName: "calendar")
                }

                if !mapQuery.isEmpty {
                    Button {
                        showsMapOptions = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.and.ellipse")
                                .frame(width: 20)
                                .foregroundStyle(ThemeSystem.locationColor)

                            VStack(alignment: .leading, spacing: 2) {
                                if !event.venue.isEmpty {
                                    Text(event.venue)
                                        .foregroundStyle(.primary)
                                }
                                if !event.address.isEmpty {
                                    Text(event.address)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer(minLength: 8)

                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            ThemeSystem.locationColor.opacity(0.08),
                            in: .rect(cornerRadius: DesignRadius.medium)
                        )
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(Text("detail.open_maps"))
                    .accessibilityIdentifier("venueMapButton")
                    .confirmationDialog(
                        "detail.open_maps",
                        isPresented: $showsMapOptions,
                        titleVisibility: .visible
                    ) {
                        Button {
                            openMap(with: .apple)
                        } label: {
                            Label("map.apple", systemImage: "apple.logo")
                        }
                        Button {
                            openMap(with: .google)
                        } label: {
                            Label("map.google", systemImage: "globe")
                        }
                        Button("common.cancel", role: .cancel) {}
                    }
                }
            }
        }
    }

    private var ticketSection: some View {
        detailSection("editor.tickets") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(event.ticketOptions.enumerated()), id: \.element.id) { index, option in
                    ticketRow(option, isSelected: option.id == event.selectedTicketID)
                    if index < event.ticketOptions.count - 1 {
                        Divider()
                    }
                }

                if !event.ticketOptions.isEmpty, event.ticketActionURL != nil {
                    Divider()
                }

                if let actionURL = event.ticketActionURL {
                    Link(destination: actionURL) {
                        if event.selectedTicketID == nil {
                            Label("ticket.purchase", systemImage: "cart")
                                .frame(maxWidth: .infinity)
                        } else {
                            Label("ticket.open_purchased", systemImage: "ticket.fill")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.glassProminent)
                    .accessibilityIdentifier("ticketActionButton")
                }
            }
        }
    }

    private func timeDisplay(
        title: LocalizedStringKey,
        time: Date,
        isProminent: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(isProminent ? .bold : .semibold))
                .foregroundStyle(isProminent ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            Text(time, format: .dateTime.hour().minute())
                .font(isProminent ? .title.bold() : .title2.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(isProminent ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
        }
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
    }

    private func ticketRow(_ option: TicketOption, isSelected: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(option.name)
                    .font(.body.weight(isSelected ? .semibold : .medium))
                if let description = option.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if isSelected {
                    Label("ticket.selected", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tint)
                }
            }
            Spacer(minLength: 8)
            if let price = option.price {
                Text("¥\(price.formatted())")
                    .fontWeight(isSelected ? .bold : .regular)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)
    }

    private func detailSection<Content: View>(
        _ title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.regularMaterial, in: .rect(cornerRadius: DesignRadius.large))
    }

    private var mapQuery: String {
        let venue = event.venue.trimmingCharacters(in: .whitespacesAndNewlines)
        if !venue.isEmpty { return venue }
        return event.address.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @MainActor
    private func openMap(with provider: MapProvider) {
        do {
            try MapService().open(
                provider: provider,
                venue: mapQuery
            )
        } catch {
            mapError = error.localizedDescription
        }
    }
}
