import SwiftUI

struct ScheduleBadge: View {
    let label: String

    var body: some View {
        Label {
            Text(label)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: 116)
        } icon: {
            Image(systemName: "calendar")
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .glassEffect(.regular.tint(Color.accentColor.opacity(0.15)), in: .capsule)
        .accessibilityLabel(Text("schedule.badge \(label)"))
    }
}
