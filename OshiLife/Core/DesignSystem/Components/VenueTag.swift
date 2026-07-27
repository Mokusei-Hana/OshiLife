import SwiftUI

struct VenueTag: View {
    let venue: String

    var body: some View {
        Label {
            Text(venue)
                .foregroundStyle(.primary)
        } icon: {
            Image(systemName: "mappin.and.ellipse")
                .foregroundStyle(ThemeSystem.locationColor)
        }
        .font(.footnote)
        .lineLimit(1)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            ThemeSystem.locationColor.opacity(0.12),
            in: .rect(cornerRadius: DesignRadius.small)
        )
    }
}
