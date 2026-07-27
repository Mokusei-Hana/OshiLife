import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshilife/core/design/accent_color_value.dart';
import 'package:oshilife/core/design/oshi_color.dart';
import 'package:oshilife/data/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Port of OshiLifeTests/AppSettingsTests.swift.
//
// The iOS legacy `eventDisplayMode` migration test is intentionally not
// ported: Android has no legacy installs (plan §6.3).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> freshPrefs([
    Map<String, Object> values = const {},
  ]) {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  test('defaults', () async {
    final settings = AppSettings(await freshPrefs());

    expect(settings.accentColorMode, AccentColorMode.oshiLifeDefault);
    expect(settings.appearance, AppAppearance.system);
    expect(settings.customAccentColor, AccentColorValue.oshiLifeDefault);
    expect(settings.oshiColor, OshiColor.purple);
    expect(settings.homeDisplayStyle, HomeDisplayStyle.card);
    expect(settings.language, AppLanguage.system);
  });

  test('persists selections', () async {
    final prefs = await freshPrefs();
    final settings = AppSettings(prefs);
    settings.accentColorMode = AccentColorMode.oshiColor;
    settings.appearance = AppAppearance.dark;
    settings.customAccentColor = const AccentColorValue(
      red: 0.1,
      green: 0.2,
      blue: 0.3,
    );
    settings.oshiColor = OshiColor.blue;
    settings.homeDisplayStyle = HomeDisplayStyle.list;
    settings.language = AppLanguage.simplifiedChinese;

    final reloaded = AppSettings(prefs);

    expect(reloaded.accentColorMode, AccentColorMode.oshiColor);
    expect(reloaded.appearance, AppAppearance.dark);
    expect(
      reloaded.customAccentColor,
      const AccentColorValue(red: 0.1, green: 0.2, blue: 0.3),
    );
    expect(reloaded.oshiColor, OshiColor.blue);
    expect(reloaded.homeDisplayStyle, HomeDisplayStyle.list);
    expect(reloaded.language, AppLanguage.simplifiedChinese);
  });

  test('unknown raw values fall back to defaults', () async {
    final settings = AppSettings(
      await freshPrefs({
        'settings.accentColorMode': 'unknown',
        'settings.appearance': 'unknown',
        'settings.homeDisplayStyle': 'unknown',
        'settings.language': 'unknown',
        'settings.oshiColor': 'unknown',
      }),
    );

    expect(settings.accentColorMode, AccentColorMode.oshiLifeDefault);
    expect(settings.appearance, AppAppearance.system);
    expect(settings.homeDisplayStyle, HomeDisplayStyle.card);
    expect(settings.language, AppLanguage.system);
    expect(settings.oshiColor, OshiColor.purple);
  });

  test('invalid custom color falls back to default', () async {
    final settings = AppSettings(
      await freshPrefs({'settings.customAccentColor': 'invalid'}),
    );
    expect(settings.customAccentColor, AccentColorValue.oshiLifeDefault);
  });

  test('out-of-range custom color falls back to default', () async {
    final settings = AppSettings(
      await freshPrefs({
        'settings.customAccentColor':
            '{"red":2.0,"green":0.2,"blue":0.3,"alpha":1.0}',
      }),
    );
    expect(settings.customAccentColor, AccentColorValue.oshiLifeDefault);
  });

  // Port of testAppearanceColorSchemeMapping (ColorScheme? → ThemeMode /
  // Brightness?).
  test('appearance theme mode mapping', () {
    expect(AppAppearance.system.themeMode, ThemeMode.system);
    expect(AppAppearance.light.themeMode, ThemeMode.light);
    expect(AppAppearance.dark.themeMode, ThemeMode.dark);
    expect(AppAppearance.system.brightnessOverride, isNull);
    expect(AppAppearance.light.brightnessOverride, Brightness.light);
    expect(AppAppearance.dark.brightnessOverride, Brightness.dark);
  });
}
