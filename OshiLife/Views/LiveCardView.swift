import SwiftUI

struct LiveCardView: View {
    let event: LiveEvent
    let imageStore: ImageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                CoverImageView(relativePath: event.coverImagePath, imageStore: imageStore, height: 230)
                StatusBadge(status: event.status)
                    .padding(14)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(event.artistName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(event.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
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
            .padding(18)
        }
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.10), radius: 20, y: 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("card.accessibility \(event.artistName) \(event.title)"))
    }
}
