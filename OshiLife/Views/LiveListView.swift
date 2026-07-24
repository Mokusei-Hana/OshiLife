import SwiftUI

private struct EditorRoute: Identifiable {
    let id = UUID()
    let event: LiveEvent?
}

private enum EventDisplayMode: String, CaseIterable, Identifiable {
    case list
    case card

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .list: "display_mode.list"
        case .card: "display_mode.card"
        }
    }

    var systemImage: String {
        switch self {
        case .list: "list.bullet"
        case .card: "rectangle.grid.1x2"
        }
    }
}

struct LiveListView: View {
    @Environment(\.scenePhase) private var scenePhase
    private let liveStore: LiveStore
    private let imageStore: ImageStore
    private let startupWarning: String?

    @AppStorage("eventDisplayMode") private var displayMode = EventDisplayMode.card
    @State private var viewModel: LiveListViewModel
    @State private var importCoordinator: PendingImportCoordinator
    @State private var editorRoute: EditorRoute?
    @State private var showsManualImport = false
    @State private var manualImportDraft: PendingShareImport?
    @State private var path: [UUID] = []
    @State private var focusedEventID: UUID?

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
                        Button("live.add") { editorRoute = EditorRoute(event: nil) }
                            .buttonStyle(.glassProminent)
                            .accessibilityIdentifier("addLiveButton")
                    }
                } else {
                    eventContent(viewModel.filteredEvents)
                        .refreshable { viewModel.load() }
                }
            }
            .navigationTitle("app.name")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    filterMenu(selection: $viewModel.filter)
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    displayModeMenu
                    Button("manual_import.title", systemImage: "square.and.arrow.down") {
                        showsManualImport = true
                    }
                    .accessibilityIdentifier("manualXImportEntryButton")
                    Button("live.add", systemImage: "plus") {
                        editorRoute = EditorRoute(event: nil)
                    }
                    .buttonStyle(.glassProminent)
                    .accessibilityIdentifier("addLiveButton")
                }
            }
            .navigationDestination(for: UUID.self) { id in
                eventDestination(id: id, viewModel: viewModel)
            }
        }
    }

    private var displayModeMenu: some View {
        Menu {
            Picker("display_mode.title", selection: $displayMode) {
                ForEach(EventDisplayMode.allCases) { mode in
                    Label(mode.title, systemImage: mode.systemImage)
                        .tag(mode)
                }
            }
        } label: {
            Image(systemName: displayMode.systemImage)
        }
        .accessibilityLabel(Text("display_mode.title"))
        .accessibilityValue(Text(displayMode.title))
        .accessibilityIdentifier("displayModeMenu")
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

    private func filterMenu(
        selection: Binding<LiveListViewModel.StatusFilter>
    ) -> some View {
        Menu {
            Picker("filter.title", selection: selection) {
                ForEach(LiveListViewModel.StatusFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
        } label: {
            Label(selection.wrappedValue.title, systemImage: "line.3.horizontal.decrease")
        }
    }

    @ViewBuilder
    private func eventContent(_ events: [LiveEvent]) -> some View {
        switch displayMode {
        case .card:
            homeContent(events)
        case .list:
            eventList(events)
        }
    }

    private func eventList(_ events: [LiveEvent]) -> some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(events) { event in
                    eventLink(event) {
                        LiveListRowView(event: event)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .animation(.snappy, value: displayMode)
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
                VStack(alignment: .leading, spacing: 8) {
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
            eventCarousel(events)

            Divider()
                .padding(.horizontal, 18)

            countdownCard(
                for: focusedEvent(in: events),
                now: now
            )
        }
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 16, y: 10)
        .padding(.horizontal, 18)
    }

    private func eventCarousel(_ events: [LiveEvent]) -> some View {
        GeometryReader { proxy in
            let cardWidth = min(328, max(280, proxy.size.width - 56))
            let horizontalMargin = max(28, (proxy.size.width - cardWidth) / 2)

            ScrollView(.horizontal) {
                LazyHStack(spacing: 16) {
                    ForEach(events) { event in
                        eventLink(event) {
                            HomeEventCarouselCard(
                                event: event,
                                imageStore: imageStore,
                                width: cardWidth
                            )
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
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $focusedEventID, anchor: .center)
            .contentMargins(.horizontal, horizontalMargin, for: .scrollContent)
            .onAppear {
                synchronizeFocus(with: events)
            }
            .onChange(of: events.map(\.id)) { _, _ in
                synchronizeFocus(with: events)
            }
        }
        .frame(height: 464)
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

    private func focusedEvent(in events: [LiveEvent]) -> LiveEvent? {
        guard let focusedEventID else { return events.first }
        return events.first { $0.id == focusedEventID } ?? events.first
    }

    private func synchronizeFocus(with events: [LiveEvent]) {
        guard focusedEventID == nil || !events.contains(where: { $0.id == focusedEventID }) else {
            return
        }
        focusedEventID = events.first?.id
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
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 8)

                    Text(event.eventDate, format: .dateTime.year().month().day().weekday())
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Text(countdownText(until: event.eventDate, now: now))
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Text(event.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
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
