import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oshilife/app/providers.dart';
import 'package:oshilife/core/design/accent_color_value.dart';
import 'package:oshilife/core/design/oshi_color.dart';
import 'package:oshilife/core/design/widgets/section_card.dart';
import 'package:oshilife/data/settings/app_settings.dart';
import 'package:oshilife/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Port of `AppVersionInfo.swift` — name/version/build with an em-dash
/// fallback.
class AppVersionInfo {
  const AppVersionInfo({
    this.applicationName = '—',
    this.version = '—',
    this.build = '—',
  });

  final String applicationName;
  final String version;
  final String build;
}

final appVersionProvider = FutureProvider<AppVersionInfo>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return AppVersionInfo(
      applicationName: info.appName.isEmpty ? '—' : info.appName,
      version: info.version.isEmpty ? '—' : info.version,
      build: info.buildNumber.isEmpty ? '—' : info.buildNumber,
    );
  } on Object {
    return const AppVersionInfo();
  }
});

abstract final class _ProjectLinks {
  static final Uri github = Uri.parse(
    'https://github.com/Mokusei-Hana/OshiLife',
  );
  static final Uri feedback = Uri.parse(
    'https://github.com/Mokusei-Hana/OshiLife/issues',
  );
}

/// Port of `SettingsView.swift`: home display style, accent mode with
/// 推し色 / custom color, appearance, language (actually applied here —
/// documented parity difference), and the about section.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(appSettingsProvider);
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final versionInfo =
        ref.watch(appVersionProvider).value ?? const AppVersionInfo();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            header: l10n.settingsHomeSection,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.settingsHomeDisplayStyle,
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                SegmentedButton<HomeDisplayStyle>(
                  segments: [
                    ButtonSegment(
                      value: HomeDisplayStyle.card,
                      icon: const Icon(Icons.view_carousel_outlined, size: 16),
                      label: Text(l10n.displayModeCard),
                    ),
                    ButtonSegment(
                      value: HomeDisplayStyle.list,
                      icon: const Icon(Icons.view_list_outlined, size: 16),
                      label: Text(l10n.displayModeList),
                    ),
                  ],
                  selected: {settings.homeDisplayStyle},
                  onSelectionChanged: (selection) =>
                      settings.homeDisplayStyle = selection.first,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            header: l10n.settingsAppearanceSection,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.settingsAccentColorMode,
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                SegmentedButton<AccentColorMode>(
                  segments: [
                    ButtonSegment(
                      value: AccentColorMode.oshiLifeDefault,
                      label: Text(l10n.settingsAccentDefault),
                    ),
                    ButtonSegment(
                      value: AccentColorMode.oshiColor,
                      label: Text(l10n.settingsAccentOshi),
                    ),
                    ButtonSegment(
                      value: AccentColorMode.custom,
                      label: Text(l10n.settingsAccentCustom),
                    ),
                  ],
                  selected: {settings.accentColorMode},
                  onSelectionChanged: (selection) =>
                      settings.accentColorMode = selection.first,
                ),
                if (settings.accentColorMode == AccentColorMode.oshiColor) ...[
                  const SizedBox(height: 14),
                  Text(
                    l10n.settingsAccentOshiColor,
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final color in OshiColor.values)
                        ChoiceChip(
                          avatar: CircleAvatar(
                            radius: 7,
                            backgroundColor: color.primaryColor(brightness),
                          ),
                          label: Text(_oshiColorName(l10n, color)),
                          selected: settings.oshiColor == color,
                          onSelected: (_) => settings.oshiColor = color,
                        ),
                    ],
                  ),
                ],
                if (settings.accentColorMode == AccentColorMode.custom) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.settingsAccentCustomColor),
                    trailing: CircleAvatar(
                      radius: 12,
                      backgroundColor: settings.customAccentColor.color,
                    ),
                    onTap: () => _pickCustomColor(context, settings, l10n),
                  ),
                ],
                const Divider(height: 24),
                Text(
                  l10n.settingsAppAppearance,
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                SegmentedButton<AppAppearance>(
                  segments: [
                    ButtonSegment(
                      value: AppAppearance.system,
                      label: Text(l10n.settingsAppearanceSystem),
                    ),
                    ButtonSegment(
                      value: AppAppearance.light,
                      label: Text(l10n.settingsAppearanceLight),
                    ),
                    ButtonSegment(
                      value: AppAppearance.dark,
                      label: Text(l10n.settingsAppearanceDark),
                    ),
                  ],
                  selected: {settings.appearance},
                  onSelectionChanged: (selection) =>
                      settings.appearance = selection.first,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            header: l10n.settingsLanguageSection,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: RadioGroup<AppLanguage>(
              groupValue: settings.language,
              onChanged: (value) {
                if (value != null) settings.language = value;
              },
              child: Column(
                children: [
                  for (final language in AppLanguage.values)
                    RadioListTile<AppLanguage>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_languageName(l10n, language)),
                      value: language,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            header: l10n.settingsAboutSection,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _aboutRow(
                  context,
                  l10n.settingsApplicationName,
                  versionInfo.applicationName,
                ),
                _aboutRow(context, l10n.settingsVersion, versionInfo.version),
                _aboutRow(context, l10n.settingsBuild, versionInfo.build),
                const Divider(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.code),
                  title: Text(l10n.settingsGithub),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => launchUrl(
                    _ProjectLinks.github,
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.forum_outlined),
                  title: Text(l10n.settingsFeedback),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => launchUrl(
                    _ProjectLinks.feedback,
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomColor(
    BuildContext context,
    AppSettings settings,
    AppLocalizations l10n,
  ) async {
    var selected = settings.customAccentColor.color;
    final confirmed = await ColorPicker(
      color: selected,
      enableOpacity: false,
      heading: Text(l10n.settingsAccentCustomColor),
      pickersEnabled: const {
        ColorPickerType.wheel: true,
        ColorPickerType.primary: true,
        ColorPickerType.accent: false,
      },
      onColorChanged: (color) => selected = color,
    ).showPickerDialog(context);
    if (confirmed) {
      settings.customAccentColor = AccentColorValue.fromColor(selected);
    }
  }

  String _oshiColorName(AppLocalizations l10n, OshiColor color) {
    return switch (color) {
      OshiColor.white => l10n.oshiColorWhite,
      OshiColor.blue => l10n.oshiColorBlue,
      OshiColor.red => l10n.oshiColorRed,
      OshiColor.green => l10n.oshiColorGreen,
      OshiColor.yellow => l10n.oshiColorYellow,
      OshiColor.orange => l10n.oshiColorOrange,
      OshiColor.pink => l10n.oshiColorPink,
      OshiColor.purple => l10n.oshiColorPurple,
      OshiColor.aqua => l10n.oshiColorAqua,
    };
  }

  String _languageName(AppLocalizations l10n, AppLanguage language) {
    return switch (language) {
      AppLanguage.system => l10n.settingsLanguageSystem,
      AppLanguage.japanese => l10n.settingsLanguageJapanese,
      AppLanguage.simplifiedChinese => l10n.settingsLanguageSimplifiedChinese,
    };
  }
}
