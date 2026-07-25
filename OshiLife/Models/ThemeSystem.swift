import CoreImage
import SwiftUI
import UIKit

enum DesignRadius {
    static let large: CGFloat = 24
    static let medium: CGFloat = 18
    static let small: CGFloat = 12
}

struct AccentColorValue: Codable, Equatable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    static let oshiLifeDefault = AccentColorValue(
        red: 0.784,
        green: 0.306,
        blue: 0.941,
        alpha: 1
    )

    init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    init(color: Color) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            self = .oshiLifeDefault
            return
        }

        self.init(
            red: Double(red),
            green: Double(green),
            blue: Double(blue),
            alpha: Double(alpha)
        )
    }

    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

enum ThemeSystem {
    static func appAccentColor(for settings: AppSettings) -> Color {
        switch settings.accentColorMode {
        case .custom:
            settings.customAccentColor.color
        case .oshiLifeDefault, .artworkColor:
            .accentColor
        }
    }

    static func detailAccentColor(
        for settings: AppSettings,
        artworkColor: AccentColorValue?
    ) -> Color {
        switch settings.accentColorMode {
        case .artworkColor:
            (artworkColor ?? .oshiLifeDefault).color
        case .custom:
            settings.customAccentColor.color
        case .oshiLifeDefault:
            .accentColor
        }
    }
}

enum ArtworkAccentColorExtractor {
    static func extract(
        from image: UIImage?,
        fallback: AccentColorValue = .oshiLifeDefault
    ) -> AccentColorValue {
        guard
            let image,
            let inputImage = CIImage(image: image),
            !inputImage.extent.isEmpty,
            let filter = CIFilter(name: "CIAreaAverage")
        else {
            return fallback
        }

        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: inputImage.extent), forKey: kCIInputExtentKey)

        guard let outputImage = filter.outputImage else {
            return fallback
        }

        var pixel = [UInt8](repeating: 0, count: 4)
        CIContext(options: [.workingColorSpace: NSNull()])
            .render(
                outputImage,
                toBitmap: &pixel,
                rowBytes: 4,
                bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                format: .RGBA8,
                colorSpace: CGColorSpace(name: CGColorSpace.sRGB)
            )

        guard pixel[3] > 0 else {
            return fallback
        }

        return AccentColorValue(
            red: Double(pixel[0]) / 255,
            green: Double(pixel[1]) / 255,
            blue: Double(pixel[2]) / 255,
            alpha: 1
        )
    }
}
