import SwiftUI

struct StatusBadge: View {
    let status: LiveStatus

    private var color: Color {
        switch status {
        case .planned: EventPresentation.accent
        case .attended: Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.42, green: 0.80, blue: 0.72, alpha: 1)
            : UIColor(red: 0.08, green: 0.40, blue: 0.34, alpha: 1) })
        case .cancelled: .secondary
        }
    }

    var body: some View {
        Label(status.localizedName, systemImage: status.systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(EventPresentation.surface, in: .capsule)
            .overlay { Capsule().strokeBorder(color.opacity(0.25), lineWidth: 1) }
            .accessibilityElement(children: .combine)
    }
}
