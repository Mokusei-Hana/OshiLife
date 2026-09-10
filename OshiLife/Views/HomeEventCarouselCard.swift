import SwiftUI

/// A full-width event spread: identity first, artwork second, itinerary last.
struct HomeEventCarouselCard: View {
    let event: LiveEvent
    let imageStore: ImageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                StatusBadge(status: event.status)
                if !event.artistName.isEmpty {
                    Text(event.artistName)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                Text(event.title)
                    .font(.largeTitle.bold())
                    .fixedSize(horizontal: false, vertical: true)
            }

            CoverImageView(relativePath: event.coverImagePath, imageStore: imageStore, height: 280)
                .clipShape(.rect(cornerRadius: EventPresentation.cornerRadius))

            HStack(alignment: .top, spacing: 20) {
                EventDateStamp(date: event.eventDate)
                VStack(alignment: .leading, spacing: 16) {
                    Text(event.eventDate, format: .dateTime.year().month().day())
                        .font(.subheadline.weight(.medium))
                    if !event.venue.isEmpty {
                        Label(event.venue, systemImage: "mappin")
                            .font(.headline)
                    }
                    EventSchedule(openTime: event.openTime, startTime: event.startTime)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .foregroundStyle(.primary)
        .contentShape(.rect)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("eventCard")
    }
}

struct HistoricalEventCard: View {
    let event: LiveEvent
    let imageStore: ImageStore

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            CoverImageView(relativePath: event.coverImagePath, imageStore: imageStore, height: 72)
                .frame(width: 60)
                .clipShape(.rect(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 5) {
                Text(event.title).font(.headline).lineLimit(2)
                Text(event.artistName).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                Text(event.eventDate, format: .dateTime.year().month().day())
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 12)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("historicalEventCard")
    }
}
