import SwiftUI

struct HomeEventCarouselCard: View {
    let event: LiveEvent
    let imageStore: ImageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CoverImageView(relativePath: event.coverImagePath, imageStore: imageStore, height: 250)
                .overlay(alignment: .topLeading) {
                    StatusBadge(status: event.status)
                        .padding(16)
                }
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    if !event.artistName.isEmpty {
                        Text(event.artistName).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                    }
                    Text(event.title)
                        .font(.system(.title, design: .serif).weight(.bold))
                        .fixedSize(horizontal: false, vertical: true)
                }
                TicketRule()
                HStack(alignment: .top, spacing: 16) {
                    EventDateStamp(date: event.eventDate)
                    VStack(alignment: .leading, spacing: 10) {
                        Text(event.eventDate, format: .dateTime.year().month().day())
                            .font(.caption).foregroundStyle(.secondary)
                        if !event.venue.isEmpty {
                            Label(event.venue, systemImage: "mappin.and.ellipse").font(.subheadline.weight(.semibold))
                        }
                        EventSchedule(openTime: event.openTime, startTime: event.startTime)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
        }
        .foregroundStyle(.primary)
        .background(EventPresentation.surface)
        .clipShape(.rect(cornerRadius: EventPresentation.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: EventPresentation.cornerRadius)
                .strokeBorder(EventPresentation.rule, lineWidth: 1)
        }
        .contentShape(.rect)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("eventCard")
    }
}

struct HistoricalEventCard: View {
    let event: LiveEvent
    let imageStore: ImageStore

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            CoverImageView(relativePath: event.coverImagePath, imageStore: imageStore, height: 88)
                .frame(width: 68)
                .clipShape(.rect(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 6) {
                Text(event.eventDate, format: .dateTime.year().month().day())
                    .font(.caption.monospaced()).foregroundStyle(EventPresentation.accent)
                Text(event.title).font(.headline).fixedSize(horizontal: false, vertical: true)
                if !event.artistName.isEmpty {
                    Text(event.artistName).font(.subheadline).foregroundStyle(.secondary)
                }
                StatusBadge(status: event.status)
            }
            Spacer(minLength: 0)
            Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .foregroundStyle(.primary)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("historicalEventCard")
    }
}
