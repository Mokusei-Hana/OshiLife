import Observation
import SwiftUI

enum AccentColorMode: String, CaseIterable, Identifiable {
    case oshiLifeDefault
    case artworkColor
    case custom

    var id: String { rawValue }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case japanese
    case simplifiedChinese

    var id: String { rawValue }
}

@Observable
final class AppSettings {
    private enum Key {
        static let accentColorMode = "settings.accentColorMode"
        static let appearance = "settings.appearance"
        static let language = "settings.language"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var accentColorMode: AccentColorMode {
        didSet { defaults.set(accentColorMode.rawValue, forKey: Key.accentColorMode) }
    }

    var appearance: AppAppearance {
        didSet { defaults.set(appearance.rawValue, forKey: Key.appearance) }
    }

    var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: Key.language) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        accentColorMode = AccentColorMode(
            rawValue: defaults.string(forKey: Key.accentColorMode) ?? ""
        ) ?? .oshiLifeDefault
        appearance = AppAppearance(
            rawValue: defaults.string(forKey: Key.appearance) ?? ""
        ) ?? .system
        language = AppLanguage(
            rawValue: defaults.string(forKey: Key.language) ?? ""
        ) ?? .system
    }
}
