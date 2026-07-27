import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.colorScheme) private var colorScheme
    private let liveStore: LiveStore
    private let imageStore: ImageStore
    private let pendingStore: PendingImportStore?
    private let startupWarning: String?
    @State private var settings: AppSettings

    init(container: ModelContainer, startupWarning: String?) {
        let liveStore = LiveStore(container: container)
        self.liveStore = liveStore
        self.startupWarning = startupWarning
        _settings = State(initialValue: AppSettings())

        if let sharedURL = try? FileManager.default.oshiLifeSharedContainerURL() {
            imageStore = ImageStore(rootURL: sharedURL)
            pendingStore = PendingImportStore(rootURL: sharedURL)
        } else {
            let fallback = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appending(path: "OshiLife", directoryHint: .isDirectory)
            imageStore = ImageStore(rootURL: fallback)
            pendingStore = nil
        }
    }

    var body: some View {
        @Bindable var settings = settings
        let localeOverride = settings.language.locale

        LiveListView(
            liveStore: liveStore,
            imageStore: imageStore,
            pendingStore: pendingStore,
            startupWarning: startupWarning
        )
        .environment(settings)
        .tint(ThemeSystem.palette(
            for: settings,
            colorScheme: settings.appearance.colorScheme ?? colorScheme
        ).primary)
        .preferredColorScheme(settings.appearance.colorScheme)
        .transformEnvironment(\.locale) { locale in
            if let localeOverride {
                locale = localeOverride
            }
        }
    }
}
