import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings
    private let versionInfo: AppVersionInfo

    init(settings: AppSettings, versionInfo: AppVersionInfo = AppVersionInfo()) {
        self.settings = settings
        self.versionInfo = versionInfo
    }

    var body: some View {
        Form {
            Section("settings.appearance.section") {
                Picker("settings.accent_color_mode", selection: $settings.accentColorMode) {
                    ForEach(AccentColorMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }

                Picker("settings.app_appearance", selection: $settings.appearance) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Text(appearance.title).tag(appearance)
                    }
                }
            }

            Section("settings.language.section") {
                Picker("settings.language", selection: $settings.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.title).tag(language)
                    }
                }
            }

            Section("settings.about.section") {
                LabeledContent("settings.application_name", value: versionInfo.applicationName)
                LabeledContent("settings.version", value: versionInfo.version)
                LabeledContent("settings.build", value: versionInfo.build)

                Link(destination: ProjectLinks.github) {
                    Label("settings.github", systemImage: "chevron.left.forwardslash.chevron.right")
                }

                Link(destination: ProjectLinks.feedback) {
                    Label("settings.feedback", systemImage: "bubble.left.and.bubble.right")
                }
            }
        }
        .navigationTitle("settings.title")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private enum ProjectLinks {
    static let github = URL(string: "https://github.com/Mokusei-Hana/OshiLife")!
    static let feedback = URL(string: "https://github.com/Mokusei-Hana/OshiLife/issues")!
}

private extension AccentColorMode {
    var title: LocalizedStringResource {
        switch self {
        case .oshiLifeDefault: "settings.accent.default"
        case .artworkColor: "settings.accent.artwork"
        case .custom: "settings.accent.custom"
        }
    }
}

private extension AppAppearance {
    var title: LocalizedStringResource {
        switch self {
        case .system: "settings.appearance.system"
        case .light: "settings.appearance.light"
        case .dark: "settings.appearance.dark"
        }
    }
}

private extension AppLanguage {
    var title: LocalizedStringResource {
        switch self {
        case .system: "settings.language.system"
        case .japanese: "settings.language.japanese"
        case .simplifiedChinese: "settings.language.simplified_chinese"
        }
    }
}
