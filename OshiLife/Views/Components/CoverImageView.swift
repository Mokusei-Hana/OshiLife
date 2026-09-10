import SwiftUI

struct CoverImageView: View {
    let relativePath: String?
    let imageStore: ImageStore
    var height: CGFloat = 240
    var aspectRatio: CGFloat? = nil

    @State private var image: UIImage?

    var body: some View {
        Rectangle()
            .fill(EventPresentation.ink)
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
                    ZStack {
                        ForEach(0..<5) { index in
                            Circle()
                                .stroke(.white.opacity(0.08), lineWidth: 1)
                                .frame(width: CGFloat(100 + index * 70), height: CGFloat(100 + index * 70))
                        }
                        Image(systemName: "waveform")
                            .font(.system(size: 52, weight: .ultraLight))
                            .foregroundStyle(Color(red: 0.98, green: 0.58, blue: 0.40))
                    }
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
