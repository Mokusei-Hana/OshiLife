import SwiftUI
import UIKit

/// The concert journal palette. Dynamic colors keep the same hierarchy in dark mode.
enum EventPresentation {
    static let inset: CGFloat = 20
    static let cornerRadius: CGFloat = 24
    static let background = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.075, green: 0.08, blue: 0.085, alpha: 1)
        : UIColor(red: 0.96, green: 0.945, blue: 0.915, alpha: 1) })
    static let surface = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.13, green: 0.14, blue: 0.15, alpha: 1)
        : UIColor(red: 1, green: 0.995, blue: 0.98, alpha: 1) })
    static let accent = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 1, green: 0.43, blue: 0.32, alpha: 1)
        : UIColor(red: 0.73, green: 0.20, blue: 0.12, alpha: 1) })
    static let buttonFill = Color(red: 0.73, green: 0.20, blue: 0.12)
    static let ink = Color(red: 0.10, green: 0.13, blue: 0.15)
    static let rule = Color.primary.opacity(0.12)
}

struct JournalSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(EventPresentation.surface, in: .rect(cornerRadius: EventPresentation.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: EventPresentation.cornerRadius)
                    .strokeBorder(EventPresentation.rule, lineWidth: 1)
                    .allowsHitTesting(false)
            }
    }
}

extension View {
    func journalSurface() -> some View { modifier(JournalSurface()) }
}

struct JournalButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .foregroundStyle(.white)
            .background(EventPresentation.buttonFill, in: .rect(cornerRadius: 16))
            .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.4)
    }
}

struct JournalHeading: View {
    let title: LocalizedStringKey
    let symbol: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol).foregroundStyle(EventPresentation.accent)
            Text(title).font(.headline)
            Spacer(minLength: 0)
        }
        .accessibilityAddTraits(.isHeader)
    }
}

struct EventSection<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Capsule().fill(EventPresentation.accent).frame(width: 4, height: 18)
                Text(title).font(.headline).accessibilityAddTraits(.isHeader)
            }
            content()
        }
        .journalSurface()
    }
}

struct TicketRule: View {
    var body: some View {
        Rectangle()
            .fill(.clear)
            .frame(height: 1)
            .overlay {
                GeometryReader { geometry in
                    Path { path in
                        path.move(to: .zero)
                        path.addLine(to: CGPoint(x: geometry.size.width, y: 0))
                    }
                    .stroke(EventPresentation.rule, style: StrokeStyle(lineWidth: 1, dash: [4, 5]))
                }
            }
            .accessibilityHidden(true)
    }
}

struct EventDateStamp: View {
    let date: Date
    var body: some View {
        VStack(spacing: 2) {
            Text(date, format: .dateTime.month(.abbreviated))
                .font(.caption.weight(.bold))
            Text(date, format: .dateTime.day())
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .monospacedDigit()
            Text(date, format: .dateTime.weekday(.abbreviated)).font(.caption2)
        }
        .foregroundStyle(EventPresentation.accent)
        .padding(12)
        .frame(minWidth: 74)
        .background(EventPresentation.accent.opacity(0.08), in: .rect(cornerRadius: 14))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(date, format: .dateTime.year().month().day().weekday()))
    }
}

struct EventSchedule: View {
    let openTime: Date?
    let startTime: Date?
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 24) { times }
            VStack(alignment: .leading, spacing: 12) { times }
        }
    }
    @ViewBuilder private var times: some View {
        if let openTime { time("field.open_time", date: openTime) }
        if let startTime { time("field.start_time", date: startTime) }
    }
    private func time(_ title: LocalizedStringKey, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(date, format: .dateTime.hour().minute())
                .font(.system(.title3, design: .monospaced).weight(.medium))
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
            Image(systemName: systemImage).foregroundStyle(EventPresentation.accent)
        }
        .font(.subheadline)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(EventPresentation.accent.opacity(0.08), in: .rect(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}
