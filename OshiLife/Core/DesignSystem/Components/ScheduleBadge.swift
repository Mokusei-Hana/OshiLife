import SwiftUI

struct ScheduleBadge: View {
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "calendar")
                .font(.caption.weight(.semibold))

            Text(label)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: 110)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .glassEffect(.regular.tint(Color.accentColor.opacity(0.15)), in: .capsule)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("schedule.badge \(label)"))
    }
}
