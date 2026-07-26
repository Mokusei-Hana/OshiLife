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
            HomeDashboardView(
                events: events,
                imageStore: imageStore,
                focusedEventID: $focusedEventID,
                onOpen: { path.append($0.id) },
                onEdit: { editorRoute = EditorRoute(event: $0) }
            )
        case .list:
            eventList(events)
        }
    }

    private func eventList(_ events: [LiveEvent]) -> some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            ScrollView {
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
