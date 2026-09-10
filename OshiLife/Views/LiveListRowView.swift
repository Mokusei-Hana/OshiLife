import SwiftUI

struct LiveListRowView: View {
    let event: LiveEvent

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            EventDateStamp(date: event.eventDate)
            VStack(alignment: .leading, spacing: 8) {
                Text(event.title).font(.headline).fixedSize(horizontal: false, vertical: true)
                if !event.artistName.isEmpty {
                    Text(event.artistName).font(.subheadline).foregroundStyle(.secondary)
                }
                if !event.venue.isEmpty {
                    Label(event.venue, systemImage: "mappin.and.ellipse")
                        .font(.caption).foregroundStyle(.secondary)
                }
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) { statusAndTime }
                    VStack(alignment: .leading, spacing: 8) { statusAndTime }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
        .foregroundStyle(.primary)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("eventListRow")
    }

    @ViewBuilder private var statusAndTime: some View {
        StatusBadge(status: event.status)
        if let start = event.startTime {
            Text(start, format: .dateTime.hour().minute())
                .font(.caption.monospaced()).foregroundStyle(.secondary)
        }
    }
}
