import SwiftUI
import UIKit

private struct EditorRoute: Identifiable {
    let id = UUID()
    let event: LiveEvent?
}

struct LiveListView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppSettings.self) private var settings
    private let liveStore: LiveStore
    private let imageStore: ImageStore
    private let startupWarning: String?

    @State private var viewModel: LiveListViewModel
    @State private var importCoordinator: PendingImportCoordinator
    @State private var editorRoute: EditorRoute?
    @State private var showsManualImport = false
    @State private var showsSettings = false
    @State private var manualImportDraft: PendingShareImport?
    @State private var path: [UUID] = []
    @State private var focusedEventID: UUID?
    @State private var showsCarouselPageIndicator = false
    @State private var carouselIndicatorDismissTask: Task<Void, Never>?

    init(
        liveStore: LiveStore,
        imageStore: ImageStore,
        pendingStore: PendingImportStore?,
        startupWarning: String?
    ) {
        self.liveStore = liveStore
        self.imageStore = imageStore
        self.startupWarning = startupWarning
        _viewModel = State(initialValue: LiveListViewModel(store: liveStore))
        _importCoordinator = State(initialValue: PendingImportCoordinator(pendingStore: pendingStore, liveStore: liveStore))
    }

    var body: some View {
        @Bindable var importCoordinator = importCoordinator

        let navigation = navigationContent(viewModel: viewModel)
        let lifecycleContent = navigation.task {
            viewModel.load()
            importCoordinator.checkQueue()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            viewModel.load()
            importCoordinator.checkQueue()
        }
        .onOpenURL { importCoordinator.open(url: $0) }
        let warningContent = lifecycleContent.safeAreaInset(edge: .top) {
            if let startupWarning {
                warningBanner(startupWarning)
                    .padding(.horizontal, 12)
            }
        }
        let editorContent = warningContent.sheet(item: $editorRoute) { route in
            LiveEditorHost(
                store: liveStore,
                imageStore: imageStore,
                event: route.event,
                onSaved: { viewModel.load() }
            )
        }
        let manualImportContent = editorContent.sheet(isPresented: $showsManualImport, onDismiss: {
            guard let draft = manualImportDraft else { return }
            manualImportDraft = nil
            importCoordinator.presentManual(draft)
        }) {
            ManualXImportView { pending in
                manualImportDraft = pending
                showsManualImport = false
            }
        }
        let importContent = manualImportContent.sheet(item: $importCoordinator.current) { pending in
            ImportEditorHost(
                store: liveStore,
                imageStore: imageStore,
                pending: pending,
                imageData: importCoordinator.currentImageData,
                duplicate: importCoordinator.duplicateEvent,
                onOpenDuplicate: { event in
                    importCoordinator.discardCurrent()
                    path.append(event.id)
                },
                onSaved: {
                    importCoordinator.consumeCurrent()
                    viewModel.load()
                },
                onDiscard: { importCoordinator.discardCurrent() }
            )
            .interactiveDismissDisabled()
        }

        return importContent.alert("common.error", isPresented: Binding(
            get: { viewModel.errorMessage != nil || importCoordinator.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil; importCoordinator.errorMessage = nil } }
        )) {
            Button("common.ok") {
                viewModel.errorMessage = nil
                importCoordinator.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? importCoordinator.errorMessage ?? "")
        }
    }

    private func navigationContent(viewModel: LiveListViewModel) -> some View {
        @Bindable var viewModel = viewModel

        return NavigationStack(path: $path) {
            Group {
                if viewModel.isLoading && viewModel.events.isEmpty {
                    ProgressView("common.loading")
                } else if viewModel.filteredEvents.isEmpty {
                    ContentUnavailableView {
                        Label("list.empty.title", systemImage: "sparkles.rectangle.stack")
                    } description: {
                        Text("list.empty.message")
                    } actions: {
                        addMenu
                            .buttonStyle(.glassProminent)
                    }
                } else {
                    eventContent(viewModel.filteredEvents)
                        .refreshable { viewModel.load() }
                }
            }
            .navigationTitle("app.name")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    sidebarMenu(selection: $viewModel.filter)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    addMenu
                    .buttonStyle(.glassProminent)
                }
            }
            .navigationDestination(for: UUID.self) { id in
                eventDestination(id: id, viewModel: viewModel)
            }
            .navigationDestination(isPresented: $showsSettings) {
                SettingsView(settings: settings)
            }
        }
    }

    private func sidebarMenu(
        selection: Binding<LiveListViewModel.StatusFilter>
    ) -> some View {
        Menu {
            Picker("filter.title", selection: selection) {
                ForEach(LiveListViewModel.StatusFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }

            Divider()

            Button("settings.title", systemImage: "gearshape") {
                showsSettings = true
            }
            .accessibilityIdentifier("settingsButton")
        } label: {
            Label("home.sidebar", systemImage: "sidebar.left")
        }
        .accessibilityIdentifier("sidebarButton")
    }

    private var addMenu: some View {
        Menu {
            Button("live.create_manually", systemImage: "square.and.pencil") {
                editorRoute = EditorRoute(event: nil)
            }

            Button("manual_import.title", systemImage: "square.and.arrow.down") {
                showsManualImport = true
            }
            .accessibilityIdentifier("manualXImportEntryButton")
        } label: {
            Label("live.add", systemImage: "plus")
        }
        .accessibilityIdentifier("addLiveButton")
    }

    @ViewBuilder
    private func eventDestination(id: UUID, viewModel: LiveListViewModel) -> some View {
        if let event = viewModel.events.first(where: { $0.id == id }) {
            LiveDetailView(
                event: event,
                imageStore: imageStore,
                onEdit: { editorRoute = EditorRoute(event: event) },
                onDelete: { delete(event, id: id, viewModel: viewModel) }
            )
        } else {
            ContentUnavailableView("error.missing_live", systemImage: "exclamationmark.triangle")
        }
    }

    private func delete(_ event: LiveEvent, id: UUID, viewModel: LiveListViewModel) {
        viewModel.delete(event, imageStore: imageStore)
        path.removeAll { $0 == id }
    }

    @ViewBuilder
    private func eventContent(_ events: [LiveEvent]) -> some View {
        switch settings.homeDisplayStyle {
        case .card:
            homeContent(events)
        case .list:
            eventList(events)
        }
    }

    private func eventList(_ events: [LiveEvent]) -> some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(events) { event in
                        eventLink(event) {
                            LiveListRowView(
                                event: event,
                                imageStore: imageStore,
                                now: context.date
                            )
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
        }
        .animation(.snappy, value: settings.homeDisplayStyle)
    }

    private func homeContent(_ events: [LiveEvent]) -> some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            homeContent(events, now: context.date)
        }
    }

    private func homeContent(_ events: [LiveEvent], now: Date) -> some View {
        let upcoming = events
            .filter { $0.status == .planned && $0.eventDate > now }
            .sorted { $0.eventDate < $1.eventDate }
        let history = events
            .filter { $0.status == .attended }
            .sorted { $0.eventDate > $1.eventDate }

        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 28) {
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

                if !history.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        sectionTitle("home.attended", systemImage: "checkmark.seal")
                        historicalEvents(history)
                    }
                }
            }
            .padding(.vertical, 18)
        }
        .scrollIndicators(.hidden)
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
                        eventLink(event) {
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
                    eventLink(event) {
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

    private func eventLink<Label: View>(
        _ event: LiveEvent,
        @ViewBuilder label: () -> Label
    ) -> some View {
        Button(action: {
            path.append(event.id)
        }) {
            label()
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("common.edit", systemImage: "pencil") {
                editorRoute = EditorRoute(event: event)
            }
        }
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

                Text(countdownText(until: event.eventDate, now: now))
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

    private func countdownText(until date: Date, now: Date) -> String {
        let seconds = max(0, Int(date.timeIntervalSince(now)))
        let days = seconds / 86_400
        let hours = (seconds % 86_400) / 3_600
        let minutes = (seconds % 3_600) / 60
        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }

    private func warningBanner(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.footnote)
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .glassEffect(.regular.tint(.orange.opacity(0.12)), in: .rect(cornerRadius: 16))
    }
}

private struct CarouselPageIndicator: UIViewRepresentable {
    let numberOfPages: Int
    let currentPage: Int

    func makeUIView(context: Context) -> UIPageControl {
        let pageControl = UIPageControl()
        pageControl.backgroundStyle = .minimal
        pageControl.hidesForSinglePage = true
        pageControl.allowsContinuousInteraction = false
        pageControl.isUserInteractionEnabled = false
        pageControl.isAccessibilityElement = false
        pageControl.currentPageIndicatorTintColor = .label.withAlphaComponent(0.72)
        pageControl.pageIndicatorTintColor = .secondaryLabel.withAlphaComponent(0.28)
        return pageControl
    }

    func updateUIView(_ pageControl: UIPageControl, context: Context) {
        pageControl.numberOfPages = numberOfPages
        pageControl.currentPage = currentPage
    }
}
