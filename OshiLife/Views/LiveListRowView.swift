import SwiftUI

struct LiveListRowView: View {
    let event: LiveEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(event.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Spacer(minLength: 8)

                StatusBadge(status: event.status)
            }

            HStack(spacing: 14) {
                Label {
                    Text(event.eventDate, format: .dateTime.year().month().day().weekday())
                } icon: {
                    Image(systemName: "calendar")
                }

                if !event.venue.isEmpty {
                    Label(event.venue, systemImage: "mappin.and.ellipse")
                        .lineLimit(1)
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("card.accessibility \(event.artistName) \(event.title)"))
        .accessibilityIdentifier("eventListRow")
    }
}
