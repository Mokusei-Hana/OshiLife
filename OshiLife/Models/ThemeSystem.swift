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

    var isValid: Bool {
        [red, green, blue, alpha].allSatisfy { $0.isFinite && (0...1).contains($0) }
    }
}

enum OshiColor: String, CaseIterable, Codable, Identifiable {
    case white
    case blue
    case red
    case green
    case yellow
    case orange
    case pink
    case purple
    case aqua

    var id: String { rawValue }

    var displayName: LocalizedStringResource {
        switch self {
        case .white: "oshi_color.white"
        case .blue: "oshi_color.blue"
        case .red: "oshi_color.red"
        case .green: "oshi_color.green"
        case .yellow: "oshi_color.yellow"
        case .orange: "oshi_color.orange"
        case .pink: "oshi_color.pink"
        case .purple: "oshi_color.purple"
        case .aqua: "oshi_color.aqua"
        }
    }

    func primaryColor(for colorScheme: ColorScheme) -> Color {
        if self == .white {
            return colorScheme == .dark
                ? .white
                : Color(red: 0.48, green: 0.50, blue: 0.55)
        }
        return baseColor
    }

    func lightBackgroundColor(for colorScheme: ColorScheme) -> Color {
        if self == .white {
            return colorScheme == .dark
                ? .white.opacity(0.14)
                : Color(red: 0.96, green: 0.96, blue: 0.97)
        }
        return baseColor.opacity(colorScheme == .dark ? 0.18 : 0.12)
    }

    func borderColor(for colorScheme: ColorScheme) -> Color {
        if self == .white {
            return colorScheme == .dark
                ? .white.opacity(0.42)
                : Color(red: 0.78, green: 0.79, blue: 0.82)
        }
        return baseColor.opacity(colorScheme == .dark ? 0.60 : 0.42)
    }

    private var baseColor: Color {
        switch self {
        case .white: .white
        case .blue: Color(red: 0.10, green: 0.45, blue: 0.92)
        case .red: Color(red: 0.90, green: 0.16, blue: 0.20)
        case .green: Color(red: 0.15, green: 0.65, blue: 0.32)
        case .yellow: Color(red: 0.95, green: 0.70, blue: 0.05)
        case .orange: Color(red: 0.95, green: 0.42, blue: 0.08)
        case .pink: Color(red: 0.94, green: 0.30, blue: 0.58)
        case .purple: Color(red: 0.64, green: 0.28, blue: 0.88)
        case .aqua: Color(red: 0.00, green: 0.68, blue: 0.72)
        }
    }
}

struct ThemePalette {
    let primary: Color
    let background: Color
    let border: Color
}

enum ThemeSystem {
    static let locationColor = Color.green
    static let warningColor = Color.orange
    static let successColor = Color.green
    static let errorColor = Color.red

    static func palette(
        for settings: AppSettings,
        colorScheme: ColorScheme
    ) -> ThemePalette {
        switch settings.accentColorMode {
        case .oshiLifeDefault:
            return ThemePalette(
                primary: .accentColor,
                background: .accentColor.opacity(colorScheme == .dark ? 0.18 : 0.12),
                border: .accentColor.opacity(colorScheme == .dark ? 0.60 : 0.42)
            )
        case .oshiColor:
            return ThemePalette(
                primary: settings.oshiColor.primaryColor(for: colorScheme),
                background: settings.oshiColor.lightBackgroundColor(for: colorScheme),
                border: settings.oshiColor.borderColor(for: colorScheme)
            )
        case .custom:
            let color = settings.customAccentColor.color
            return ThemePalette(
                primary: color,
                background: color.opacity(colorScheme == .dark ? 0.18 : 0.12),
                border: color.opacity(colorScheme == .dark ? 0.60 : 0.42)
            )
        }
    }
}
