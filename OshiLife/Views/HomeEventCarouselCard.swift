import SwiftUI

struct HomeEventCarouselCard: View {
    let event: LiveEvent
    let imageStore: ImageStore
    let width: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CoverImageView(
                relativePath: event.coverImagePath,
                imageStore: imageStore,
                height: 310
            )
            .clipShape(.rect(cornerRadius: 24))
            .overlay(alignment: .topTrailing) {
                StatusBadge(status: event.status)
                    .padding(14)
            }

            VStack(alignment: .leading, spacing: 10) {
                if !event.artistName.isEmpty {
                    Text(event.artistName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text(event.title)
                    .font(.title3.bold())
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
                    Label(event.venue, systemImage: "mappin.and.ellipse")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, minHeight: 154, alignment: .topLeading)
        }
        .frame(width: width)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("card.accessibility \(event.artistName) \(event.title)"))
        .accessibilityIdentifier("eventCard")
    }
}

struct HistoricalEventCard: View {
    let event: LiveEvent
    let imageStore: ImageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CoverImageView(
                relativePath: event.coverImagePath,
                imageStore: imageStore,
                height: 122
            )

            VStack(alignment: .leading, spacing: 5) {
                Text(event.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text(event.eventDate, format: .dateTime.year().month().day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
        }
        .frame(width: 208)
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
        .contentShape(.rect(cornerRadius: 18))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("card.accessibility \(event.artistName) \(event.title)"))
        .accessibilityIdentifier("historicalEventCard")
    }
}
