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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppSettings.self) private var settings
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
                    VStack(spacing: 24) {
                        Image(systemName: "waveform")
                            .font(.system(size: 60, weight: .ultraLight))
                            .foregroundStyle(EventPresentation.accent)
                            .accessibilityHidden(true)
                        ProgressView("common.loading")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredEvents.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            Image(systemName: "ticket")
                                .font(.system(size: 72, weight: .ultraLight))
                                .foregroundStyle(EventPresentation.accent)
                                .padding(.top, 24)
                                .accessibilityHidden(true)
                            Text("list.empty.title")
                                .font(.system(.largeTitle, design: .serif).weight(.bold))
                            TicketRule()
                            Text("list.empty.message")
                                .font(.body).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Button("live.add") { editorRoute = EditorRoute(event: nil) }
                                .buttonStyle(JournalButtonStyle())
                                .accessibilityIdentifier("addLiveButton")
                        }
                        .journalSurface()
                        .padding(EventPresentation.inset)
                        .frame(maxWidth: 600)
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    eventContent(viewModel.filteredEvents)
                        .refreshable { viewModel.load() }
                }
            }
            .background(EventPresentation.background)
            .navigationTitle("app.name")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView(settings: settings)
                    } label: {
                        Label("settings.title", systemImage: "slider.horizontal.3")
                    }
                    .accessibilityIdentifier("settingsButton")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack(spacing: 12) {
                    filterMenu(selection: $viewModel.filter)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    displayModeMenu
                        .frame(minWidth: 44, minHeight: 44)
                }
                .padding(.horizontal, EventPresentation.inset)
                .background(EventPresentation.background)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) { creationActions }
                    VStack(spacing: 10) { creationActions }
                }
                .padding(.horizontal, EventPresentation.inset)
                .padding(.vertical, 12)
                .background(EventPresentation.background)
            }
            .navigationDestination(for: UUID.self) { id in
                eventDestination(id: id, viewModel: viewModel)
            }
        }
    }

    @ViewBuilder private var creationActions: some View {
        Button {
            showsManualImport = true
        } label: {
            Label("manual_import.title", systemImage: "square.and.arrow.down")
                .font(.subheadline.weight(.semibold))
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(EventPresentation.surface, in: .rect(cornerRadius: 16))
                .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(EventPresentation.rule) }
        }
        .accessibilityIdentifier("manualXImportEntryButton")
        Button {
            editorRoute = EditorRoute(event: nil)
        } label: {
            Label("live.add", systemImage: "plus")
        }
        .buttonStyle(JournalButtonStyle())
        .accessibilityIdentifier("addLiveButton")
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
            Label(displayMode.title, systemImage: displayMode.systemImage)
                .font(.subheadline.weight(.semibold))
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
        let months = Dictionary(grouping: events) {
            Calendar.current.dateInterval(of: .month, for: $0.eventDate)?.start ?? $0.eventDate
        }
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                ForEach(months.keys.sorted(), id: \.self) { month in
                    VStack(alignment: .leading, spacing: 14) {
                        Text(month, format: .dateTime.year().month(.wide))
                            .font(.system(.title2, design: .serif).weight(.bold))
                            .accessibilityAddTraits(.isHeader)
                        VStack(spacing: 14) {
                            ForEach(months[month] ?? []) { event in
                                eventLink(event) { LiveListRowView(event: event) }
                                if event.id != months[month]?.last?.id { TicketRule() }
                            }
                        }
                        .journalSurface()
                    }
                }
            }
            .padding(EventPresentation.inset)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
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

        let upcomingIDs = Set(upcoming.map(\.id))
        let remaining = events
            .filter { !upcomingIDs.contains($0.id) && $0.status != .attended }
            .sorted { $0.eventDate > $1.eventDate }

        return ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .firstTextBaseline) {
                    Text("journal.collection")
                        .font(.system(.largeTitle, design: .serif).weight(.bold))
                    Spacer()
                    Text(events.count, format: .number)
                        .font(.title2.monospacedDigit())
                        .foregroundStyle(EventPresentation.accent)
                        .accessibilityLabel(Text("journal.event_count \(events.count)"))
                }
                .padding(.horizontal, EventPresentation.inset)
                if upcoming.isEmpty {
                    ContentUnavailableView("home.no_upcoming", systemImage: "calendar")
                } else {
                    let focused = upcoming.first { $0.id == focusedEventID } ?? upcoming[0]
                    countdownCard(for: focused, now: now, isNext: focused.id == upcoming.first?.id)
                        .padding(.horizontal, EventPresentation.inset)
                    eventCarousel(upcoming)
                    if upcoming.count > 1 {
                        EventSection(title: "home.upcoming") {
                            ForEach(upcoming.dropFirst()) { event in
                                eventLink(event) { LiveListRowView(event: event) }
                                Divider()
                            }
                        }
                        .padding(.horizontal, EventPresentation.inset)
                    }
                }
                if !remaining.isEmpty {
                    EventSection(title: "journal.other_events") {
                        ForEach(remaining) { event in
                            eventLink(event) { LiveListRowView(event: event) }
                        }
                    }
                    .padding(.horizontal, EventPresentation.inset)
                }
                if !history.isEmpty {
                    EventSection(title: "home.attended") {
                        ForEach(history) { event in
                            eventLink(event) {
                                HistoricalEventCard(event: event, imageStore: imageStore)
                            }
                        }
                    }
                    .padding(.horizontal, EventPresentation.inset)
                }
            }
            .padding(.vertical, 24)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
    }

    private func eventCarousel(_ events: [LiveEvent]) -> some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 24) {
                    ForEach(events) { event in
                        eventLink(event) {
                            HomeEventCarouselCard(event: event, imageStore: imageStore)
                        }
                        .containerRelativeFrame(.horizontal)
                        .id(event.id)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, EventPresentation.inset, for: .scrollContent)
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $focusedEventID, anchor: .center)
            .onScrollPhaseChange { _, phase in updateCarouselIndicator(for: phase) }
            .onAppear { synchronizeFocus(with: events) }
            .onChange(of: events.map(\.id)) { _, _ in synchronizeFocus(with: events) }
            .onDisappear {
                carouselIndicatorDismissTask?.cancel()
                carouselIndicatorDismissTask = nil
                showsCarouselPageIndicator = false
            }
            CarouselPageIndicator(numberOfPages: events.count, currentPage: focusedEventIndex(in: events))
                .frame(height: events.count > 1 ? 20 : 0)
                .opacity(showsCarouselPageIndicator ? 1 : 0)
                .accessibilityHidden(true)
        }
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
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.16)) {
                showsCarouselPageIndicator = true
            }
        case .idle:
            guard showsCarouselPageIndicator else { return }
            carouselIndicatorDismissTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(700))
                guard !Task.isCancelled else { return }
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.22)) {
                    showsCarouselPageIndicator = false
                }
            }
        case .animating:
            break
        @unknown default:
            break
        }
    }

    @ViewBuilder
    private func countdownCard(for event: LiveEvent?, now: Date, isNext: Bool) -> some View {
        if let event {
            VStack(alignment: .leading, spacing: 6) {
                Label(isNext ? LocalizedStringKey("home.next_live") : LocalizedStringKey("home.selected_live_countdown"), systemImage: "timer")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(countdownText(until: event.eventDate, now: now))
                    .font(.system(.largeTitle, design: .monospaced).weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(.tint)
                    .contentTransition(.numericText())
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(EventPresentation.accent.opacity(0.08), in: .rect(cornerRadius: 20))
            .overlay(alignment: .trailing) {
                Image(systemName: "sparkle")
                    .font(.largeTitle).foregroundStyle(EventPresentation.accent.opacity(0.2))
                    .padding(24).accessibilityHidden(true)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private func countdownText(until date: Date, now: Date) -> String {
        let seconds = max(0, Int(date.timeIntervalSince(now)))
        let days = seconds / 86_400
        let hours = (seconds % 86_400) / 3_600
        let minutes = (seconds % 3_600) / 60
        if days > 0 { return String(localized: "journal.countdown.days \(days) \(hours)") }
        if hours > 0 { return String(localized: "journal.countdown.hours \(hours) \(minutes)") }
        return String(localized: "journal.countdown.minutes \(minutes)")
    }

    private func warningBanner(_ message: String) -> some View {
        InlineNotice(message: message)
            .background(EventPresentation.background)
    }
}

private struct CarouselPageIndicator: View {
    let numberOfPages: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 12) {
            Text(verbatim: "\(currentPage + 1) / \(numberOfPages)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            GeometryReader { geometry in
                Capsule().fill(EventPresentation.rule)
                    .overlay(alignment: .leading) {
                        Capsule().fill(EventPresentation.accent)
                            .frame(width: geometry.size.width * CGFloat(currentPage + 1) / CGFloat(max(1, numberOfPages)))
                    }
            }
            .frame(width: 72, height: 3)
        }
        .accessibilityHidden(true)
    }
}
