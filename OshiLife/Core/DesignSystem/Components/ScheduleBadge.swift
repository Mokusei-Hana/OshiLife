import SwiftUI

struct ScheduleBadge: View {
    let label: String
    var maximumWidth: CGFloat = 150

    var body: some View {
        ViewThatFits(in: .horizontal) {
            badgeContent
                .fixedSize(horizontal: true, vertical: false)

            badgeContent
        }
        .frame(maxWidth: maximumWidth, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("schedule.badge \(label)"))
    }

    private var badgeContent: some View {
        HStack(spacing: 5) {
            Image(systemName: "calendar")
                .font(.caption.weight(.semibold))

            Text(label)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .glassEffect(.regular.tint(Color.accentColor.opacity(0.15)), in: .capsule)
    }
}
