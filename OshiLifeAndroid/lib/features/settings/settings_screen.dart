import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oshilife/app/providers.dart';
import 'package:oshilife/core/design/oshi_color.dart';
import 'package:oshilife/data/settings/app_settings.dart';
import 'package:oshilife/l10n/app_localizations.dart';

/// M0/M1 minimal settings — appearance, accent mode, and 推し色 selection,
/// enough to prove reactive theming and persistence. The full `SettingsView`
/// port (custom color picker, language, about) ships in M3.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(appSettingsProvider);
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.settingsAppearanceSection,
            style: Theme.of(context).textTheme.titleSmall,
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
          const SizedBox(height: 24),
          Text(
            l10n.settingsAccentColorMode,
            style: Theme.of(context).textTheme.titleSmall,
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
            const SizedBox(height: 16),
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
        ],
      ),
    );
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
}
