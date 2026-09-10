import SwiftUI

struct LiveDetailView: View {
    let event: LiveEvent
    let imageStore: ImageStore
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var confirmsDelete = false
    @State private var showsMapOptions = false
    @State private var mapError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                identity
                CoverImageView(relativePath: event.coverImagePath, imageStore: imageStore, height: 340)
                    .clipShape(.rect(cornerRadius: 16))
                itinerary
                if !event.performers.isEmpty {
                    EventSection(title: "field.performers") {
                        ForEach(Array(event.performers.enumerated()), id: \.offset) { _, performer in
                            Label(performer, systemImage: "person")
                                .font(.body)
                                .textSelection(.enabled)
                        }
                    }
                }
                if !event.ticketOptions.isEmpty { tickets }
                if !event.notes.isEmpty {
                    EventSection(title: "field.notes") {
                        Text(event.notes)
                            .lineSpacing(5)
                            .textSelection(.enabled)
                    }
                }
                if event.ticketURL != nil || event.sourceURL != nil {
                    EventSection(title: "detail.links") {
                        if let url = event.ticketURL {
                            externalLink("detail.ticket", symbol: "ticket", url: url)
                        }
                        if let url = event.sourceURL {
                            externalLink("detail.source", symbol: "link", url: url)
                        }
                    }
                }
            }
            .padding(EventPresentation.inset)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .background(EventPresentation.background)
        .navigationTitle("detail.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("common.edit", systemImage: "pencil", action: onEdit)
            }
            ToolbarItem(placement: .bottomBar) {
                StatusBadge(status: event.status)
            }
            ToolbarItem(placement: .bottomBar) {
                Spacer()
            }
            ToolbarItem(placement: .bottomBar) {
                Button("common.delete", systemImage: "trash", role: .destructive) {
                    confirmsDelete = true
                }
            }
        }
        .confirmationDialog("delete.title", isPresented: $confirmsDelete, titleVisibility: .visible) {
            Button("common.delete", role: .destructive, action: onDelete)
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("delete.message")
        }
        .confirmationDialog("detail.open_maps", isPresented: $showsMapOptions, titleVisibility: .visible) {
            Button { openMap(with: .apple) } label: {
                Label("map.apple", systemImage: "apple.logo")
            }
            Button { openMap(with: .google) } label: {
                Label("map.google", systemImage: "globe")
            }
            Button("common.cancel", role: .cancel) {}
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

    private var identity: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !event.artistName.isEmpty {
                Text(event.artistName)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            Text(event.title)
                .font(.largeTitle.bold())
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
    }

    private var itinerary: some View {
        EventSection(title: "editor.schedule") {
            HStack(alignment: .top, spacing: 24) {
                EventDateStamp(date: event.eventDate)
                VStack(alignment: .leading, spacing: 20) {
                    Text(event.eventDate, format: .dateTime.year().month().day().weekday())
                        .font(.headline)
                    EventSchedule(openTime: event.openTime, startTime: event.startTime)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if !mapQuery.isEmpty {
                Divider()
                Button { showsMapOptions = true } label: {
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: "location.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.tint)
                        VStack(alignment: .leading, spacing: 6) {
                            if !event.venue.isEmpty {
                                Text(event.venue).font(.headline).foregroundStyle(.primary)
                            }
                            if !event.address.isEmpty {
                                Text(event.address).font(.subheadline).foregroundStyle(.secondary)
                            }
                            Text("detail.open_maps").font(.subheadline.weight(.medium))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "arrow.up.right").font(.subheadline)
                    }
                    .padding(.vertical, 8)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityHint(Text("detail.open_maps"))
                .accessibilityIdentifier("venueMapButton")
            }
        }
    }

    private var tickets: some View {
        EventSection(title: "editor.tickets") {
            if let selected = event.selectedTicket {
                VStack(alignment: .leading, spacing: 16) {
                    Label("field.selected_ticket", systemImage: "checkmark.seal.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tint)
                    ticketRow(selected, selected: true)
                }
                .padding(20)
                .background(Color(uiColor: .secondarySystemBackground), in: .rect(cornerRadius: 16))
            }
            Text("detail.available_tickets").font(.subheadline).foregroundStyle(.secondary)
            ForEach(event.ticketOptions) { option in
                ticketRow(option)
                Divider()
            }
        }
    }

    private func ticketRow(_ option: TicketOption, selected: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                Text(option.name).font(selected ? .title2.bold() : .headline)
                Spacer(minLength: 0)
                if let price = option.price {
                    Text("¥\(price.formatted())")
                        .font(selected ? .title2.weight(.medium) : .body)
                        .monospacedDigit()
                }
            }
            if let description = option.description, !description.isEmpty {
                Text(description).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .textSelection(.enabled)
    }

    private func externalLink(_ title: LocalizedStringKey, symbol: String, url: URL) -> some View {
        Link(destination: url) {
            HStack {
                Label(title, systemImage: symbol)
                Spacer()
                Image(systemName: "arrow.up.right")
            }
            .font(.body.weight(.medium))
            .padding(.vertical, 8)
        }
    }

    private var mapQuery: String {
        let venue = event.venue.trimmingCharacters(in: .whitespacesAndNewlines)
        if !venue.isEmpty { return venue }
        return event.address.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @MainActor
    private func openMap(with provider: MapProvider) {
        do {
            try MapService().open(provider: provider, venue: mapQuery)
        } catch {
            mapError = error.localizedDescription
        }
    }
}
