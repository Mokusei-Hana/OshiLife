import SwiftUI

struct LiveDetailView: View {
    let event: LiveEvent
    let imageStore: ImageStore
    let onEdit: () -> Void
    let onDelete: () -> Void
    let transitionNamespace: Namespace.ID?
    let transitionID: UUID?

    @State private var confirmsDelete = false
    @State private var mapError: String?

    init(
        event: LiveEvent,
        imageStore: ImageStore,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        transitionNamespace: Namespace.ID? = nil,
        transitionID: UUID? = nil
    ) {
        self.event = event
        self.imageStore = imageStore
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.transitionNamespace = transitionNamespace
        self.transitionID = transitionID
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                detailCoverImage

                VStack(alignment: .leading, spacing: 8) {
                    Text(event.artistName)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(event.title)
                        .font(.largeTitle.bold())
                        .textSelection(.enabled)
                }

                infoSection

                if !event.performers.isEmpty {
                    detailSection("field.performers") {
                        Text(event.performers.joined(separator: " / "))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                }

                if !event.ticketOptions.isEmpty {
                    ticketSection
                }

                if !event.notes.isEmpty {
                    detailSection("field.notes") {
                        Text(event.notes)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                }

                if event.ticketURL != nil || event.sourceURL != nil {
                    detailSection("detail.links") {
                        GlassEffectContainer(spacing: 12) {
                            VStack(spacing: 12) {
                                if let ticketURL = event.ticketURL {
                                    Link(destination: ticketURL) {
                                        Label("detail.ticket", systemImage: "ticket")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.glassProminent)
                                }
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

    @ViewBuilder
    private var detailCoverImage: some View {
        if let transitionNamespace, let transitionID {
            coverImage
                .matchedGeometryEffect(
                    id: "cover-\(transitionID.uuidString)",
                    in: transitionNamespace,
                    properties: .frame,
                    anchor: .center,
                    isSource: false
                )
        } else {
            coverImage
        }
    }

    private var coverImage: some View {
        CoverImageView(relativePath: event.coverImagePath, imageStore: imageStore, height: 340)
            .clipShape(.rect(cornerRadius: 30))
            .overlay(alignment: .topTrailing) {
                StatusBadge(status: event.status).padding(16)
            }
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

                if !event.venue.isEmpty || !event.address.isEmpty || hasMapCoordinates {
                    Label {
                        VStack(alignment: .leading) {
                            if !event.venue.isEmpty { Text(event.venue) }
                            if !event.address.isEmpty {
                                Text(event.address).foregroundStyle(.secondary)
                            }
                        }
                    } icon: {
                        Image(systemName: "mappin.and.ellipse")
                    }

                    if hasMapCoordinates {
                        Menu {
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
                        } label: {
                            Label("detail.open_maps", systemImage: "map")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glass)
                    }
                }
            }
        }
    }

    private var ticketSection: some View {
        detailSection("editor.tickets") {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("detail.available_tickets")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ForEach(Array(event.ticketOptions.enumerated()), id: \.element.id) { index, option in
                        ticketRow(option)
                        if index < event.ticketOptions.count - 1 {
                            Divider()
                        }
                    }
                }

                if let selectedTicket = event.selectedTicket {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("field.selected_ticket", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.tint)
                        ticketRow(selectedTicket, isSelected: true)
                    }
                    .padding(14)
                    .background(.tint.opacity(0.12), in: .rect(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(.tint.opacity(0.45), lineWidth: 1)
                    }
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
        .background(.regularMaterial, in: .rect(cornerRadius: 22))
    }

    private var hasMapCoordinates: Bool {
        MapService.hasValidCoordinates(latitude: event.latitude, longitude: event.longitude)
    }

    @MainActor
    private func openMap(with provider: MapProvider) {
        do {
            try MapService().open(
                provider: provider,
                venue: event.venue,
                latitude: event.latitude,
                longitude: event.longitude
            )
        } catch {
            mapError = error.localizedDescription
        }
    }
}
