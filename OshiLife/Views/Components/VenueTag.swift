import SwiftUI

struct VenueTag: View {
    let venue: String

    var body: some View {
        Label(venue, systemImage: "mappin.and.ellipse")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.secondary.opacity(0.08), in: .rect(cornerRadius: DesignRadius.small))
    }
}
