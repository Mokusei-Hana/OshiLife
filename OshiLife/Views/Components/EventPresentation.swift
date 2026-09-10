import SwiftUI

/// Shared content styling. Glass is reserved for navigation and transient controls.
enum EventPresentation {
    static let inset: CGFloat = 20
    static let cornerRadius: CGFloat = 24
    static let background = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
}

struct EventSchedule: View {
    let openTime: Date?
    let startTime: Date?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 24) { times }
            VStack(alignment: .leading, spacing: 12) { times }
        }
    }

    @ViewBuilder private var times: some View {
        if let openTime {
            time("field.open_time", date: openTime)
        }
        if let startTime {
            time("field.start_time", date: startTime)
        }
    }

    private func time(_ title: LocalizedStringKey, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Text(date, format: .dateTime.hour().minute())
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
    }
}
