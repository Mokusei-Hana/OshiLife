import SwiftUI

struct ScheduleBadge: View {
    let label: String

    var body: some View {
        Label {
            Text(label)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        } icon: {
            Image(systemName: "calendar.day.timeline.left")
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.primary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.thickMaterial, in: Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.22), lineWidth: 1)
        }
        .accessibilityLabel(Text("schedule.badge \(label)"))
    }
}
