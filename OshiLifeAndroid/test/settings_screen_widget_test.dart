import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_harness.dart';

void main() {
  testWidgets('display style change persists to preferences', (tester) async {
    await pumpApp(tester);
    final l10n = l10nOf(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text(l10n.settingsTitle), findsOneWidget);

    await tester.tap(find.text(l10n.displayModeList));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings.homeDisplayStyle'), 'list');

    await disposeApp(tester);
  });

  testWidgets('oshi color mode reveals the color chips and persists', (
    tester,
  ) async {
    await pumpApp(tester);
    final l10n = l10nOf(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.settingsAccentOshi));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text(l10n.oshiColorAqua));
    expect(find.text(l10n.oshiColorAqua), findsOneWidget);
    await tester.tap(find.text(l10n.oshiColorAqua));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings.accentColorMode'), 'oshiColor');
    expect(prefs.getString('settings.oshiColor'), 'aqua');

    await disposeApp(tester);
  });

  testWidgets('language selection persists and switches the locale', (
    tester,
  ) async {
    await pumpApp(tester);
    var l10n = l10nOf(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    // The language section is below the fold of the lazily built list.
    await scrollTo(tester, find.text(l10n.settingsLanguageSimplifiedChinese));
    await tester.tap(find.text(l10n.settingsLanguageSimplifiedChinese));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings.language'), 'simplifiedChinese');

    // The UI is now zh-Hans: the settings title reads 设置.
    l10n = l10nOf(tester);
    expect(l10n.localeName, 'zh');

    await disposeApp(tester);
  });
}
