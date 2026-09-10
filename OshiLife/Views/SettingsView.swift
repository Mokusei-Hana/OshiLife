import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings
    private let versionInfo: AppVersionInfo

    init(settings: AppSettings, versionInfo: AppVersionInfo = AppVersionInfo()) {
        self.settings = settings
        self.versionInfo = versionInfo
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                NavigationLink { about } label: {
                    HStack(spacing: 18) {
                        Image(systemName: "waveform")
                            .font(.largeTitle.weight(.light))
                            .foregroundStyle(.white)
                            .frame(width: 72, height: 88)
                            .background(EventPresentation.ink, in: .rect(cornerRadius: 18))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(versionInfo.applicationName)
                                .font(.system(.title, design: .serif).weight(.bold))
                            Text("settings.about.section").font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up.right").foregroundStyle(EventPresentation.accent)
                    }
                    .journalSurface()
                }
                .buttonStyle(.plain)
                EventSection(title: "settings.appearance.section") {
                    NavigationLink { appearance } label: {
                        settingsRow("settings.app_appearance", symbol: "circle.lefthalf.filled", value: settings.appearance.title)
                    }
                    TicketRule()
                    NavigationLink { accent } label: {
                        settingsRow("settings.accent_color_mode", symbol: "paintpalette", value: settings.accentColorMode.title)
                    }
                }
                EventSection(title: "settings.language.section") {
                    NavigationLink { language } label: {
                        settingsRow("settings.language", symbol: "globe", value: settings.language.title)
                    }
                }
                VStack(spacing: 20) {
                    projectLink("settings.feedback", symbol: "bubble.left.and.bubble.right", url: ProjectLinks.feedback)
                    TicketRule()
                    projectLink("settings.github", symbol: "chevron.left.forwardslash.chevron.right", url: ProjectLinks.github)
                }
                .journalSurface()
            }
            .padding(EventPresentation.inset)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .background(EventPresentation.background)
        .navigationTitle("settings.title")
    }

    private var appearance: some View {
        preferencePage("settings.app_appearance") {
            ForEach(AppAppearance.allCases) { value in
                choice(value.title, selected: settings.appearance == value, symbol: appearanceSymbol(value)) {
                    settings.appearance = value
                }
            }
        }
    }

    private var accent: some View {
        preferencePage("settings.accent_color_mode") {
            ForEach(AccentColorMode.allCases) { value in
                choice(value.title, selected: settings.accentColorMode == value, symbol: "paintpalette") {
                    settings.accentColorMode = value
                }
            }
        }
    }

    private var language: some View {
        preferencePage("settings.language") {
            ForEach(AppLanguage.allCases) { value in
                choice(value.title, selected: settings.language == value, symbol: "globe") {
                    settings.language = value
                }
            }
        }
    }

    private var about: some View {
        preferencePage("settings.about.section") {
            Image(systemName: "waveform")
                .font(.system(size: 64, weight: .ultraLight))
                .foregroundStyle(EventPresentation.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .accessibilityHidden(true)
            VStack(spacing: 20) {
                LabeledContent("settings.application_name", value: versionInfo.applicationName)
                TicketRule()
                LabeledContent("settings.version", value: versionInfo.version)
                LabeledContent("settings.build", value: versionInfo.build)
            }
            .journalSurface()
            VStack(spacing: 24) {
                projectLink("settings.github", symbol: "chevron.left.forwardslash.chevron.right", url: ProjectLinks.github)
                projectLink("settings.feedback", symbol: "bubble.left.and.bubble.right", url: ProjectLinks.feedback)
            }
            .journalSurface()
        }
    }

    private func preferencePage<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16, content: content)
                .padding(EventPresentation.inset)
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
        }
        .background(EventPresentation.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func choice(_ title: LocalizedStringResource, selected: Bool, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: symbol)
                    .font(.title2)
                    .foregroundStyle(EventPresentation.accent)
                    .frame(width: 36)
                Text(title).font(.headline).foregroundStyle(.primary)
                Spacer(minLength: 0)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? EventPresentation.accent : Color.secondary)
            }
            .padding(.vertical, 10)
            .journalSurface()
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func settingsRow(_ title: LocalizedStringKey, symbol: String, value: LocalizedStringResource) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(EventPresentation.accent)
                .frame(width: 42, height: 48)
                .background(EventPresentation.background, in: .rect(cornerRadius: 12))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.headline).foregroundStyle(.primary)
                Text(value).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(.rect)
    }

    private func projectLink(_ title: LocalizedStringKey, symbol: String, url: URL) -> some View {
        Link(destination: url) {
            HStack {
                Label(title, systemImage: symbol)
                Spacer()
                Image(systemName: "arrow.up.right")
            }
            .padding(.vertical, 8)
        }
    }

    private func appearanceSymbol(_ value: AppAppearance) -> String {
        switch value {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon"
        }
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
