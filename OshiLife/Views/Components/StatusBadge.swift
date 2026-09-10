import SwiftUI

struct StatusBadge: View {
    let status: LiveStatus

    var body: some View {
        Label(status.localizedName, systemImage: status.systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(status.tint)
            .accessibilityElement(children: .combine)
    }
}
