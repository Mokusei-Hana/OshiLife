import SwiftUI

struct StatusBadge: View {
    let status: LiveStatus

    var body: some View {
        Label(status.localizedName, systemImage: status.systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(status.tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .glassEffect(.regular.tint(status.tint.opacity(0.15)), in: .capsule)
            .accessibilityElement(children: .combine)
    }
}
