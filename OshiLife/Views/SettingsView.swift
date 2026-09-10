import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings
    private let versionInfo: AppVersionInfo

    init(settings: AppSettings, versionInfo: AppVersionInfo = AppVersionInfo()) {
        self.settings = settings
        self.versionInfo = versionInfo
    }

    var body: some View {
        List {
            Section {
                NavigationLink {
                    about
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "music.note")
                            .font(.title)
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.accentColor, in: .rect(cornerRadius: 14))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(versionInfo.applicationName).font(.title2.bold())
                            Text("settings.about.section").font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 10)
                }
            }

            Section("settings.appearance.section") {
                NavigationLink {
                    appearance
                } label: {
                    settingsRow("settings.app_appearance", symbol: "circle.lefthalf.filled", value: settings.appearance.title)
                }
                NavigationLink {
                    accent
                } label: {
                    settingsRow("settings.accent_color_mode", symbol: "paintpalette", value: settings.accentColorMode.title)
                }
            }
            Section("settings.language.section") {
                NavigationLink {
                    language
                } label: {
                    settingsRow("settings.language", symbol: "globe", value: settings.language.title)
                }
            }
            Section {
                Link(destination: ProjectLinks.feedback) {
                    Label("settings.feedback", systemImage: "bubble.left.and.bubble.right")
                }
                Link(destination: ProjectLinks.github) {
                    Label("settings.github", systemImage: "chevron.left.forwardslash.chevron.right")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("settings.title")
    }

    private var appearance: some View {
        Form {
            Section {
                Picker("settings.app_appearance", selection: $settings.appearance) {
                    ForEach(AppAppearance.allCases) { value in
                        Text(value.title).tag(value)
                    }
                }
                .pickerStyle(.inline)
            }
        }
        .navigationTitle("settings.app_appearance")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var accent: some View {
        Form {
            Picker("settings.accent_color_mode", selection: $settings.accentColorMode) {
                ForEach(AccentColorMode.allCases) { value in
                    Text(value.title).tag(value)
                }
            }
            .pickerStyle(.inline)
        }
        .navigationTitle("settings.accent_color_mode")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var language: some View {
        Form {
            Picker("settings.language", selection: $settings.language) {
                ForEach(AppLanguage.allCases) { value in
                    Text(value.title).tag(value)
                }
            }
            .pickerStyle(.inline)
        }
        .navigationTitle("settings.language")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var about: some View {
        Form {
            Section {
                LabeledContent("settings.application_name", value: versionInfo.applicationName)
                LabeledContent("settings.version", value: versionInfo.version)
                LabeledContent("settings.build", value: versionInfo.build)
            }
            Section {
                Link(destination: ProjectLinks.github) {
                    Label("settings.github", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                Link(destination: ProjectLinks.feedback) {
                    Label("settings.feedback", systemImage: "bubble.left.and.bubble.right")
                }
            }
        }
        .navigationTitle("settings.about.section")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func settingsRow(_ title: LocalizedStringKey, symbol: String, value: LocalizedStringResource) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.body.weight(.medium))
                .foregroundStyle(.tint)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                Text(value).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 5)
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
