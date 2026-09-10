import SwiftUI

struct LiveCardView: View {
    let event: LiveEvent
    let imageStore: ImageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                EventDateStamp(date: event.eventDate)
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.artistName).font(.subheadline).foregroundStyle(.secondary)
                    Text(event.title).font(.title2.bold())
                    StatusBadge(status: event.status)
                }
            }
            CoverImageView(relativePath: event.coverImagePath, imageStore: imageStore, height: 200)
                .clipShape(.rect(cornerRadius: 16))
            if !event.venue.isEmpty {
                Label(event.venue, systemImage: "mappin").font(.subheadline)
            }
            EventSchedule(openTime: event.openTime, startTime: event.startTime)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("eventCard")
    }
}
