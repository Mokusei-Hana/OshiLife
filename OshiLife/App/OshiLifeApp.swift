import SwiftData
import SwiftUI

@main
struct OshiLifeApp: App {
    private let container: ModelContainer
    private let startupWarning: String?

    init() {
        do {
            container = try ModelContainerFactory.makePersistent()
            startupWarning = nil
        } catch {
            do {
                container = try ModelContainerFactory.makeInMemory()
                startupWarning = String(localized: "error.persistence_fallback \(error.localizedDescription)")
            } catch {
                fatalError("Unable to create a SwiftData container: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(container: container, startupWarning: startupWarning)
        }
        .modelContainer(container)
    }
}
