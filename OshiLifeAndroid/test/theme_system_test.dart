import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:oshilife/core/design/accent_color_value.dart';
import 'package:oshilife/core/design/oshi_color.dart';
import 'package:oshilife/core/design/theme_system.dart';
import 'package:oshilife/data/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Port of OshiLifeTests/ThemeSystemTests.swift.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('custom color encoding round trip', () {
    const color = AccentColorValue(
      red: 0.12,
      green: 0.34,
      blue: 0.56,
      alpha: 0.78,
    );

    final json = jsonEncode(color.toJson());
    final decoded = AccentColorValue.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );

    expect(decoded, color);
  });

  test('oshi color raw value round trip', () {
    expect(OshiColor.fromRawValue(OshiColor.aqua.rawValue), OshiColor.aqua);
    expect(OshiColor.fromRawValue('unknown'), isNull);
  });

  test('white uses readable fallback in light mode', () {
    final primary = AccentColorValue.fromColor(
      OshiColor.white.primaryColor(Brightness.light),
    );

    expect(primary, isNot(const AccentColorValue(red: 1, green: 1, blue: 1)));
  });

  test('palette follows the accent mode', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings(await SharedPreferences.getInstance());

    final defaultPalette = ThemeSystem.palette(
      settings: settings,
      brightness: Brightness.light,
    );
    expect(defaultPalette.primary, AccentColorValue.oshiLifeDefault.color);

    settings.accentColorMode = AccentColorMode.oshiColor;
    settings.oshiColor = OshiColor.aqua;
    final oshiPalette = ThemeSystem.palette(
      settings: settings,
      brightness: Brightness.light,
    );
    expect(oshiPalette.primary, OshiColor.aqua.primaryColor(Brightness.light));

    settings.accentColorMode = AccentColorMode.custom;
    settings.customAccentColor = const AccentColorValue(
      red: 0.1,
      green: 0.2,
      blue: 0.3,
    );
    final customPalette = ThemeSystem.palette(
      settings: settings,
      brightness: Brightness.dark,
    );
    expect(
      customPalette.primary,
      const AccentColorValue(red: 0.1, green: 0.2, blue: 0.3).color,
    );
  });
}
