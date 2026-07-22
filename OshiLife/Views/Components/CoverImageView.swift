import SwiftUI

struct CoverImageView: View {
    let relativePath: String?
    let imageStore: ImageStore
    var height: CGFloat = 240

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [.pink.opacity(0.65), .purple.opacity(0.55), .blue.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "music.note.list")
                        .font(.system(size: 42, weight: .light))
                        .foregroundStyle(.white.opacity(0.9))
                        .accessibilityHidden(true)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
        .task(id: relativePath) {
            image = imageStore.image(at: relativePath)
        }
        .accessibilityLabel(relativePath == nil ? Text("cover.placeholder") : Text("cover.image"))
    }
}
