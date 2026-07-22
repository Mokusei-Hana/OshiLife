import SwiftUI

private struct EditorRoute: Identifiable {
    let id = UUID()
    let event: LiveEvent?
}

struct LiveListView: View {
    @Environment(\.scenePhase) private var scenePhase
    private let liveStore: LiveStore
    private let imageStore: ImageStore
    private let startupWarning: String?

    @State private var viewModel: LiveListViewModel
    @State private var importCoordinator: PendingImportCoordinator
    @State private var editorRoute: EditorRoute?
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
        @Bindable var viewModel = viewModel
        @Bindable var importCoordinator = importCoordinator

        NavigationStack(path: $path) {
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
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            ForEach(viewModel.filteredEvents) { event in
                                NavigationLink(value: event.id) {
                                    LiveCardView(event: event, imageStore: imageStore)
                                }
                                .buttonStyle(.plain)
                                .matchedTransitionSource(id: event.id, in: cardNamespace)
                                .contextMenu {
                                    Button("common.edit", systemImage: "pencil") {
                                        editorRoute = EditorRoute(event: event)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                    }
                    .refreshable { viewModel.load() }
                }
            }
            .navigationTitle("app.name")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("filter.title", selection: $viewModel.filter) {
                            ForEach(LiveListViewModel.StatusFilter.allCases) { filter in
                                Text(filter.title).tag(filter)
                            }
                        }
                    } label: {
                        Label(viewModel.filter.title, systemImage: "line.3.horizontal.decrease")
                    }
                }
                ToolbarSpacer(.flexible, placement: .topBar)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("live.add", systemImage: "plus") {
                        editorRoute = EditorRoute(event: nil)
                    }
                    .buttonStyle(.glassProminent)
                    .accessibilityIdentifier("addLiveButton")
                }
            }
            .navigationDestination(for: UUID.self) { id in
                if let event = viewModel.events.first(where: { $0.id == id }) {
                    LiveDetailView(
                        event: event,
                        imageStore: imageStore,
                        onEdit: { editorRoute = EditorRoute(event: event) },
                        onDelete: {
                            viewModel.delete(event, imageStore: imageStore)
                            path.removeAll { $0 == id }
                        }
                    )
                    .navigationTransition(.zoom(sourceID: id, in: cardNamespace))
                } else {
                    ContentUnavailableView("error.missing_live", systemImage: "exclamationmark.triangle")
                }
            }
        }
        .task {
            viewModel.load()
            importCoordinator.checkQueue()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            viewModel.load()
            importCoordinator.checkQueue()
        }
        .onOpenURL { importCoordinator.open(url: $0) }
        .safeAreaInset(edge: .top) {
            if let startupWarning {
                warningBanner(startupWarning)
                    .padding(.horizontal, 12)
            }
        }
        .sheet(item: $editorRoute) { route in
            LiveEditorHost(
                store: liveStore,
                imageStore: imageStore,
                event: route.event,
                onSaved: { viewModel.load() }
            )
        }
        .sheet(item: $importCoordinator.current) { pending in
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
        .alert("common.error", isPresented: Binding(
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

    private func warningBanner(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.footnote)
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .glassEffect(.regular.tint(.orange.opacity(0.12)), in: .rect(cornerRadius: 16))
    }
}
