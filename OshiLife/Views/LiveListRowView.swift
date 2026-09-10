import SwiftUI

struct LiveListRowView: View {
    let event: LiveEvent

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 2) {
                Text(event.eventDate, format: .dateTime.month(.abbreviated))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tint)
                Text(event.eventDate, format: .dateTime.day())
                    .font(.title.bold())
                    .monospacedDigit()
            }
            .frame(minWidth: 44)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                if !event.artistName.isEmpty {
                    Text(event.artistName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text(event.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(event.eventDate, format: .dateTime.year().month().day().weekday())
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if !event.venue.isEmpty {
                    Label(event.venue, systemImage: "mappin.and.ellipse")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                StatusBadge(status: event.status)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("card.accessibility \(event.artistName) \(event.title)"))
        .accessibilityIdentifier("eventListRow")
    }
}
