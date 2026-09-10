import SwiftUI

enum EventPresentation {
    static let inset: CGFloat = 24
    static let cornerRadius: CGFloat = 28
    static let background = Color(uiColor: .systemBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
}

/// An editorial section on a continuous surface, rather than another card.
struct EventSection<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Divider()
            Text(title)
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EventDateStamp: View {
    let date: Date

    var body: some View {
        VStack(spacing: 0) {
            Text(date, format: .dateTime.month(.abbreviated))
                .font(.caption.weight(.bold))
                .foregroundStyle(.tint)
            Text(date, format: .dateTime.day())
                .font(.largeTitle.weight(.light))
                .monospacedDigit()
            Text(date, format: .dateTime.weekday(.abbreviated))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 56)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(date, format: .dateTime.year().month().day().weekday()))
    }
}

struct EventSchedule: View {
    let openTime: Date?
    let startTime: Date?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 32) { times }
            VStack(alignment: .leading, spacing: 16) { times }
        }
    }

    @ViewBuilder private var times: some View {
        if let openTime { time("field.open_time", date: openTime) }
        if let startTime { time("field.start_time", date: startTime) }
    }

    private func time(_ title: LocalizedStringKey, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Text(date, format: .dateTime.hour().minute())
                .font(.title2.weight(.medium))
                .monospacedDigit()
        }
    }
}

struct InlineNotice: View {
    let message: String
    var systemImage = "exclamationmark.circle"

    var body: some View {
        Label {
            Text(message).foregroundStyle(.primary)
        } icon: {
            Image(systemName: systemImage).foregroundStyle(.orange)
        }
        .font(.subheadline)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}
