import SwiftUI

struct LiveListRowView: View {
    let event: LiveEvent

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            RoundedRectangle(cornerRadius: 2)
                .fill(event.status.tint)
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(event.eventDate, format: .dateTime.day().weekday(.abbreviated))
                        .font(.title3.weight(.semibold))
                    Spacer()
                    if let start = event.startTime {
                        Text(start, format: .dateTime.hour().minute())
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                if !event.artistName.isEmpty {
                    Text(event.artistName).font(.subheadline).foregroundStyle(.secondary)
                }
                Text(event.title).font(.headline).fixedSize(horizontal: false, vertical: true)
                if !event.venue.isEmpty {
                    Label(event.venue, systemImage: "mappin")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                StatusBadge(status: event.status)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .fixedSize(horizontal: false, vertical: true)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("eventListRow")
    }
}
