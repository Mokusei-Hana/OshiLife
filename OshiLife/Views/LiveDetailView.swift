import SwiftUI

struct LiveDetailView: View {
    let event: LiveEvent
    let imageStore: ImageStore
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var confirmsDelete = false
    @State private var mapError: String?
    @State private var isOpeningMap = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                CoverImageView(relativePath: event.coverImagePath, imageStore: imageStore, height: 340)
                    .clipShape(.rect(cornerRadius: 30))
                    .overlay(alignment: .topTrailing) {
                        StatusBadge(status: event.status).padding(16)
                    }

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

    private var infoSection: some View {
        detailSection("detail.information") {
            VStack(alignment: .leading, spacing: 16) {
                Label {
                    VStack(alignment: .leading) {
                        Text(event.eventDate, format: .dateTime.year().month().day().weekday())
                        if let openTime = event.openTime {
                            LabeledContent("field.open_time") {
                                Text(openTime, format: .dateTime.hour().minute())
                            }
                            .foregroundStyle(.secondary)
                        }
                        if let startTime = event.startTime {
                            LabeledContent("field.start_time") {
                                Text(startTime, format: .dateTime.hour().minute())
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                } icon: {
                    Image(systemName: "calendar")
                }

                if !event.venue.isEmpty || !event.address.isEmpty {
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

                    Button {
                        Task { await openMap() }
                    } label: {
                        if isOpeningMap {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Label("detail.open_maps", systemImage: "map").frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.glass)
                    .disabled(isOpeningMap)
                }
            }
        }
    }

    private var ticketSection: some View {
        detailSection("editor.tickets") {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(event.ticketOptions) { option in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(option.name).font(.body.weight(.medium))
                            if let description = option.description, !description.isEmpty {
                                Text(description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if let price = option.price {
                            Text("¥\(price.formatted())")
                                .monospacedDigit()
                        }
                        if event.selectedTicketID == option.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.tint)
                                .accessibilityLabel(Text("ticket.selected"))
                        }
                    }
                }
            }
        }
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

    @MainActor
    private func openMap() async {
        isOpeningMap = true
        defer { isOpeningMap = false }
        do {
            try await MapService().open(
                venue: event.venue,
                address: event.address,
                latitude: event.latitude,
                longitude: event.longitude
            )
        } catch {
            mapError = error.localizedDescription
        }
    }
}
