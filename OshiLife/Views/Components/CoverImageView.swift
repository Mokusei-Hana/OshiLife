import SwiftUI

struct CoverImageView: View {
    let relativePath: String?
    let imageStore: ImageStore
    var height: CGFloat = 240
    var aspectRatio: CGFloat? = nil

    @State private var image: UIImage?

    var body: some View {
        coverContent
            .frame(maxWidth: .infinity)
            .modifier(CoverImageSize(height: height, aspectRatio: aspectRatio))
            .clipped()
            .task(id: relativePath) {
                image = imageStore.image(at: relativePath)
            }
            .accessibilityLabel(relativePath == nil ? Text("cover.placeholder") : Text("cover.image"))
    }

    private var coverContent: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color(uiColor: .tertiarySystemGroupedBackground)
                    Image(systemName: "music.note.list")
                        .font(.system(size: 42, weight: .light))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            }
        }
    }
}

private struct CoverImageSize: ViewModifier {
    let height: CGFloat
    let aspectRatio: CGFloat?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let aspectRatio {
            content.aspectRatio(aspectRatio, contentMode: .fill)
        } else {
            content.frame(height: height)
        }
    }
}
