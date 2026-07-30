import SwiftUI

struct LiveCardView: View {
    let event: LiveEvent
    let imageStore: ImageStore

    var body: some View {
        HStack(spacing: 0) {
            CoverImageView(
                relativePath: event.coverImagePath,
                imageStore: imageStore,
                height: 132
            )
            .frame(width: 116)
            .overlay(alignment: .topLeading) {
                if !event.scheduleLabel.isEmpty {
                    ScheduleBadge(label: event.scheduleLabel, maximumWidth: 96)
                        .padding(8)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(event.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Label {
                    Text(event.eventDate, format: .dateTime.year().month().day().weekday())
                } icon: {
                    Image(systemName: "calendar")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                if !event.venue.isEmpty {
                    VenueTag(venue: event.venue)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
        .frame(minHeight: 132)
        .clipShape(.rect(cornerRadius: DesignRadius.large))
        .glassEffect(.regular, in: .rect(cornerRadius: DesignRadius.large))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("card.accessibility \(event.artistName) \(event.title)"))
        .accessibilityIdentifier("eventCard")
    }
}
