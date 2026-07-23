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
    @Namespace private var cardNamespace

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
                    eventList(viewModel.filteredEvents, displayMode: displayMode)
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
            .navigationTransition(.zoom(sourceID: id, in: cardNamespace))
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

    private func eventList(
        _ events: [LiveEvent],
        displayMode: EventDisplayMode
    ) -> some View {
        ScrollView {
            LazyVStack(spacing: displayMode == .card ? 16 : 10) {
                ForEach(events) { event in
                    eventLink(event, displayMode: displayMode)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .animation(.snappy, value: displayMode)
    }

    private func eventLink(
        _ event: LiveEvent,
        displayMode: EventDisplayMode
    ) -> some View {
        NavigationLink(value: event.id) {
            switch displayMode {
            case .list:
                LiveListRowView(event: event)
            case .card:
                LiveCardView(event: event, imageStore: imageStore)
            }
        }
        .buttonStyle(.plain)
        .matchedTransitionSource(id: event.id, in: cardNamespace)
        .contextMenu {
            Button("common.edit", systemImage: "pencil") {
                editorRoute = EditorRoute(event: event)
            }
        }
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
