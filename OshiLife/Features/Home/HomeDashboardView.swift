import SwiftUI

/// Card-style Home content: the upcoming-event hero carousel with its
/// countdown, followed by the attended-event history shelf.
struct HomeDashboardView: View {
    let events: [LiveEvent]
    let imageStore: ImageStore
    @Binding var focusedEventID: UUID?
    let onOpen: (LiveEvent) -> Void
    let onEdit: (LiveEvent) -> Void

    @State private var showsCarouselPageIndicator = false
    @State private var carouselIndicatorDismissTask: Task<Void, Never>?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            content(now: context.date)
        }
    }

    private func content(now: Date) -> some View {
        let upcoming = LiveListViewModel.upcomingEvents(in: events, now: now)
        let remaining = LiveListViewModel.supplementaryDashboardEvents(
            in: events,
            excluding: upcoming
        )

        return LazyVStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 16) {
                sectionTitle("home.upcoming", systemImage: "calendar.badge.clock")
                if upcoming.isEmpty {
                    ContentUnavailableView("home.no_upcoming", systemImage: "calendar")
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                } else {
                    upcomingHero(events: upcoming, now: now)
                }
            }

            if !remaining.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    sectionTitle("home.other_events", systemImage: "clock.arrow.circlepath")
                    historicalEvents(remaining)
                }
            }
        }
        .padding(.vertical, 18)
        .animation(.snappy, value: events.map(\.id))
    }

    private func upcomingHero(events: [LiveEvent], now: Date) -> some View {
        VStack(spacing: 0) {
            eventCarousel(events, now: now)

            CarouselPageIndicator(
                numberOfPages: events.count,
                currentPage: focusedEventIndex(in: events)
            )
            .frame(height: 28)
            .opacity(events.count > 1 && showsCarouselPageIndicator ? 1 : 0)
            .accessibilityHidden(!showsCarouselPageIndicator)
        }
    }

    private func eventCarousel(_ events: [LiveEvent], now: Date) -> some View {
        GeometryReader { proxy in
            let cardWidth = min(360, max(288, proxy.size.width - 32))
            let horizontalMargin = max(16, (proxy.size.width - cardWidth) / 2)

            ScrollView(.horizontal) {
                LazyHStack(spacing: 16) {
                    ForEach(events) { event in
                        EventLinkButton(event: event, onOpen: onOpen, onEdit: onEdit) {
                            eventHeroCard(event, now: now, width: cardWidth)
                            .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1 : 0.85)
                                    .opacity(phase.isIdentity ? 1 : 0.62)
                            }
                        }
                        .zIndex(focusedEventID == event.id ? 1 : 0)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollClipDisabled()
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $focusedEventID, anchor: .center)
            .contentMargins(.horizontal, horizontalMargin, for: .scrollContent)
            .onScrollPhaseChange { _, newPhase in
                updateCarouselIndicator(for: newPhase)
            }
            .onAppear {
                synchronizeFocus(with: events)
            }
            .onChange(of: events.map(\.id)) { _, _ in
                synchronizeFocus(with: events)
            }
            .onDisappear {
                carouselIndicatorDismissTask?.cancel()
                carouselIndicatorDismissTask = nil
                showsCarouselPageIndicator = false
            }
        }
        .frame(height: 640)
    }

    private func eventHeroCard(_ event: LiveEvent, now: Date, width: CGFloat) -> some View {
        VStack(spacing: 0) {
            HomeEventCarouselCard(
                event: event,
                imageStore: imageStore,
                width: width
            )

            countdownCard(for: event, now: now)
        }
        .frame(width: width)
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: DesignRadius.large))
        .overlay {
            RoundedRectangle(cornerRadius: DesignRadius.large)
                .stroke(.primary.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.10), radius: 14, y: 6)
        .contentShape(.rect(cornerRadius: DesignRadius.large))
    }

    private func historicalEvents(_ events: [LiveEvent]) -> some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 14) {
                ForEach(events) { event in
                    EventLinkButton(event: event, onOpen: onOpen, onEdit: onEdit) {
                        HistoricalEventCard(
                            event: event,
                            imageStore: imageStore
                        )
                    }
                }
            }
            .scrollTargetLayout()
        }
        .frame(height: 196)
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
        .contentMargins(.horizontal, 18, for: .scrollContent)
    }

    private func focusedEventIndex(in events: [LiveEvent]) -> Int {
        guard let focusedEventID else { return 0 }
        return events.firstIndex { $0.id == focusedEventID } ?? 0
    }

    private func synchronizeFocus(with events: [LiveEvent]) {
        guard focusedEventID == nil || !events.contains(where: { $0.id == focusedEventID }) else {
            return
        }
        focusedEventID = events.first?.id
    }

    private func updateCarouselIndicator(for phase: ScrollPhase) {
        carouselIndicatorDismissTask?.cancel()

        switch phase {
        case .tracking, .interacting, .decelerating:
            withAnimation(.easeOut(duration: 0.16)) {
                showsCarouselPageIndicator = true
            }
        case .idle:
            guard showsCarouselPageIndicator else { return }
            carouselIndicatorDismissTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(700))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.22)) {
                    showsCarouselPageIndicator = false
                }
            }
        case .animating:
            break
        @unknown default:
            break
        }
    }

    private func sectionTitle(
        _ title: LocalizedStringResource,
        systemImage: String
    ) -> some View {
        Label(title, systemImage: systemImage)
            .font(.title2.bold())
            .padding(.horizontal, 18)
    }

    @ViewBuilder
    private func countdownCard(for event: LiveEvent?, now: Date) -> some View {
        if let event {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Label("home.selected_live_countdown", systemImage: "timer")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.tint)

                    Spacer(minLength: 8)

                    Text(event.eventDate, format: .dateTime.year().month().day().weekday())
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Text(EventCountdownFormatter.shortText(until: event.eventDate, now: now))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.tint)
                    .monospacedDigit()

                Text(event.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.tint.opacity(0.10))
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(.tint.opacity(0.18))
                    .frame(height: 1)
            }
        }
    }
}
