import SwiftUI

/// Opens an event on tap and offers editing from the context menu.
/// Shared by every event presentation on the Home screen.
struct EventLinkButton<Label: View>: View {
    let event: LiveEvent
    let onOpen: (LiveEvent) -> Void
    let onEdit: (LiveEvent) -> Void
    let label: () -> Label

    init(
        event: LiveEvent,
        onOpen: @escaping (LiveEvent) -> Void,
        onEdit: @escaping (LiveEvent) -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.event = event
        self.onOpen = onOpen
        self.onEdit = onEdit
        self.label = label
    }

    var body: some View {
        Button(action: { onOpen(event) }) {
            label()
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("common.edit", systemImage: "pencil") {
                onEdit(event)
            }
        }
    }
}
