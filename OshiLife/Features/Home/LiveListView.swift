import SwiftUI

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
    @State private var showsPerformerFilters = false

    init(
        liveStore: LiveStore,
        imageStore: ImageStore,
        pendingStore: PendingImportStore?,
        startupWarning: String?,
        settings: AppSettings
    ) {
        self.liveStore = liveStore
        self.imageStore = imageStore
        self.startupWarning = startupWarning
        _viewModel = State(initialValue: LiveListViewModel(store: liveStore, settings: settings))
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
                onSaved: {
                    if route.event == nil {
                        viewModel.reloadAfterCreatingEvent()
                    } else {
                        viewModel.load()
                        path.removeAll { id in
                            !viewModel.events.contains { $0.id == id }
                        }
                    }
                }
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
                    viewModel.reloadAfterCreatingEvent()
                },
                onDiscard: { importCoordinator.discardCurrent() }
            )
            .interactiveDismissDisabled()
        }

        let performerFilterContent = importContent.sheet(isPresented: $showsPerformerFilters) {
            PerformerFilterSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }

        return performerFilterContent.alert("common.error", isPresented: Binding(
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
                    emptyContent(viewModel: viewModel)
                } else {
                    eventContent(viewModel.filteredEvents, viewModel: viewModel)
                        .id(settings.homeDisplayStyle)
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

    private func emptyContent(viewModel: LiveListViewModel) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                if !viewModel.availablePerformers.isEmpty {
                    performerFilter(viewModel: viewModel)
                }

                ContentUnavailableView {
                    Label("list.empty.title", systemImage: "sparkles.rectangle.stack")
                } description: {
                    Text("list.empty.message")
                } actions: {
                    addMenu
                        .buttonStyle(.glassProminent)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            }
        }
        .refreshable { viewModel.load() }
    }

    private func performerFilter(viewModel: LiveListViewModel) -> some View {
        ViewThatFits(in: .horizontal) {
            performerFilterRow(viewModel: viewModel, visiblePerformerCount: nil)
            performerFilterRow(viewModel: viewModel, visiblePerformerCount: 4)
            performerFilterRow(viewModel: viewModel, visiblePerformerCount: 3)
            performerFilterRow(viewModel: viewModel, visiblePerformerCount: 2)
            performerFilterRow(viewModel: viewModel, visiblePerformerCount: 1)
        }
        .padding(.horizontal, 16)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("filter.performers"))
    }

    private func performerFilterRow(
        viewModel: LiveListViewModel,
        visiblePerformerCount: Int?
    ) -> some View {
        let performers = viewModel.availablePerformers
        let visibleCount = min(visiblePerformerCount ?? performers.count, performers.count)
        let overflowCount = performers.count - visibleCount

        return HStack(spacing: 8) {
                filterButton(
                    label: Text("filter.all"),
                    isSelected: viewModel.selectedPerformers.isEmpty
                ) {
                    viewModel.clearPerformerFilter()
                }

                ForEach(performers.prefix(visibleCount), id: \.self) { performer in
                    filterButton(
                        label: Text(verbatim: performer),
                        isSelected: viewModel.selectedPerformers.contains(performer)
                    ) {
                        viewModel.togglePerformer(performer)
                    }
                }

                if overflowCount > 0 {
                    Button {
                        showsPerformerFilters = true
                    } label: {
                        Text("+\(overflowCount)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(
                                performers.dropFirst(visibleCount).contains {
                                    viewModel.selectedPerformers.contains($0)
                                } ? Color.accentColor : Color.primary
                            )
                            .padding(.horizontal, 11)
                            .frame(height: 32)
                            .background(
                                performers.dropFirst(visibleCount).contains {
                                    viewModel.selectedPerformers.contains($0)
                                } ? Color.accentColor.opacity(0.16) : Color.secondary.opacity(0.1),
                                in: Capsule()
                            )
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .buttonStyle(.plain)
                    .contentShape(Capsule())
                    .accessibilityLabel(Text("performer.show_more"))
                }
            }
            .fixedSize(horizontal: true, vertical: false)
            .padding(.vertical, 2)
    }

    private func filterButton(
        label: Text,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                }
                label
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 140)
            }
            .padding(.horizontal, 11)
            .frame(height: 32)
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
            .background(
                isSelected
                    ? AnyShapeStyle(Color.accentColor.opacity(0.16))
                    : AnyShapeStyle(Color.secondary.opacity(0.1)),
                in: Capsule()
            )
        }
        .frame(minHeight: 44)
        .buttonStyle(.plain)
        .contentShape(Capsule())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
    private func eventContent(_ events: [LiveEvent], viewModel: LiveListViewModel) -> some View {
        switch settings.homeDisplayStyle {
        case .card:
            ScrollView {
                LazyVStack(spacing: 0) {
                    if !viewModel.availablePerformers.isEmpty {
                        performerFilter(viewModel: viewModel)
                    }

                    HomeDashboardView(
                        events: events,
                        imageStore: imageStore,
                        focusedEventID: $focusedEventID,
                        onOpen: { path.append($0.id) },
                        onEdit: { editorRoute = EditorRoute(event: $0) }
                    )
                }
            }
            .scrollIndicators(.hidden)
        case .list:
            eventList(events, viewModel: viewModel)
        }
    }

    private func eventList(_ events: [LiveEvent], viewModel: LiveListViewModel) -> some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            ScrollView {
                LazyVStack(spacing: 0) {
                    if !viewModel.availablePerformers.isEmpty {
                        performerFilter(viewModel: viewModel)
                    }

                    LazyVStack(spacing: 10) {
                        ForEach(events) { event in
                            EventLinkButton(
                                event: event,
                                onOpen: { path.append($0.id) },
                                onEdit: { editorRoute = EditorRoute(event: $0) }
                            ) {
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
        }
        .animation(.snappy, value: settings.homeDisplayStyle)
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

private struct PerformerFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: LiveListViewModel
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("performer.search", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("filter.performers") {
                    Button {
                        viewModel.clearPerformerFilter()
                    } label: {
                        filterRow(
                            title: String(localized: "filter.all"),
                            isSelected: viewModel.selectedPerformers.isEmpty
                        )
                    }

                    ForEach(filteredPerformers, id: \.self) { performer in
                        Button {
                            viewModel.togglePerformer(performer)
                        } label: {
                            filterRow(
                                title: performer,
                                isSelected: viewModel.selectedPerformers.contains(performer)
                            )
                        }
                    }
                }
            }
            .navigationTitle("filter.performers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var filteredPerformers: [String] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return viewModel.availablePerformers }
        return viewModel.availablePerformers.filter {
            $0.localizedCaseInsensitiveContains(query)
        }
    }

    private func filterRow(title: String, isSelected: Bool) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .fontWeight(.semibold)
                    .foregroundStyle(.tint)
            }
        }
        .contentShape(Rectangle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
