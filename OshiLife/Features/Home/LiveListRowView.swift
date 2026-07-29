import SwiftUI

struct LiveListRowView: View {
    let event: LiveEvent
    let imageStore: ImageStore
    let now: Date

    var body: some View {
        HStack(spacing: 12) {
            CoverImageView(
                relativePath: event.coverImagePath,
                imageStore: imageStore,
                height: 88
            )
            .frame(width: 82)
            .clipShape(.rect(cornerRadius: DesignRadius.small))

            VStack(alignment: .leading, spacing: 7) {
                if !event.scheduleLabel.isEmpty {
                    ScheduleBadge(label: event.scheduleLabel)
                }
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Spacer(minLength: 4)

                    StatusBadge(status: event.status)
                }

                Label {
                    Text(event.eventDate, format: .dateTime.year().month().day().weekday())
                } icon: {
                    Image(systemName: "calendar")
                }
                .lineLimit(1)

                if !event.venue.isEmpty {
                    VenueTag(venue: event.venue)
                }

                if event.status == .planned, event.eventDate > now {
                    Label {
                        Text(event.eventDate, style: .relative)
                    } icon: {
                        Image(systemName: "timer")
                    }
                    .foregroundStyle(.tint)
                    .lineLimit(1)
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .padding(10)
        .glassEffect(.regular, in: .rect(cornerRadius: DesignRadius.medium))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("card.accessibility \(event.artistName) \(event.title)"))
        .accessibilityIdentifier("eventListRow")
    }
}
