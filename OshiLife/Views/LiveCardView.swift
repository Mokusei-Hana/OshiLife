import SwiftUI

/// Alternate entry point uses the same concert pass as the collection.
struct LiveCardView: View {
    let event: LiveEvent
    let imageStore: ImageStore

    var body: some View {
        HomeEventCarouselCard(event: event, imageStore: imageStore)
    }
}
