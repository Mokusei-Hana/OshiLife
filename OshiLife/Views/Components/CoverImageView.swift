import SwiftUI

struct CoverImageView: View {
    let relativePath: String?
    let imageStore: ImageStore
    var height: CGFloat = 240
    var aspectRatio: CGFloat? = nil

    @State private var image: UIImage?

    var body: some View {
        Rectangle()
            .fill(Color(uiColor: .secondarySystemBackground))
            .modifier(CoverImageSize(height: height, aspectRatio: aspectRatio))
            .overlay {
                if let image {
                    GeometryReader { geometry in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                } else {
                    Image(systemName: "music.mic")
                        .font(.system(size: 36, weight: .ultraLight))
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
            }
            .clipped()
            .task(id: relativePath) {
                image = imageStore.image(at: relativePath)
            }
            .accessibilityLabel(relativePath == nil ? Text("cover.placeholder") : Text("cover.image"))
    }
}

private struct CoverImageSize: ViewModifier {
    let height: CGFloat
    let aspectRatio: CGFloat?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let aspectRatio {
            content.aspectRatio(aspectRatio, contentMode: .fit)
        } else {
            content.frame(height: height)
        }
    }
}
