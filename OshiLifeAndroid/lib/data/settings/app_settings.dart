import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:oshilife/core/design/accent_color_value.dart';
import 'package:oshilife/core/design/oshi_color.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Port of `AccentColorMode` (`OshiLife/Data/Models/AppSettings.swift`).
enum AccentColorMode {
  oshiLifeDefault,
  oshiColor,
  custom;

  static AccentColorMode? fromRawValue(String rawValue) {
    for (final mode in values) {
      if (mode.name == rawValue) return mode;
    }
    return null;
  }
}

/// Port of `AppAppearance`. `colorScheme` on iOS maps to [themeMode] here
/// (`system` → follow the platform).
enum AppAppearance {
  system,
  light,
  dark;

  static AppAppearance? fromRawValue(String rawValue) {
    for (final appearance in values) {
      if (appearance.name == rawValue) return appearance;
    }
    return null;
  }

  ThemeMode get themeMode => switch (this) {
    system => ThemeMode.system,
    light => ThemeMode.light,
    dark => ThemeMode.dark,
  };

  /// Equivalent of the iOS `colorScheme` optional: null means "follow the
  /// system".
  Brightness? get brightnessOverride => switch (this) {
    system => null,
    light => Brightness.light,
    dark => Brightness.dark,
  };
}

/// Port of `AppLanguage`. Unlike iOS (where the picker is persisted but
/// never applied), the Android app applies [locale] via `MaterialApp.locale`
/// — a documented, deliberate parity difference (plan §6.2).
enum AppLanguage {
  system,
  japanese,
  simplifiedChinese;

  static AppLanguage? fromRawValue(String rawValue) {
    for (final language in values) {
      if (language.name == rawValue) return language;
    }
    return null;
  }

  Locale? get locale => switch (this) {
    system => null,
    japanese => const Locale('ja'),
    simplifiedChinese => const Locale('zh'),
  };
}

/// Port of `HomeDisplayStyle`.
enum HomeDisplayStyle {
  card,
  list;

  static HomeDisplayStyle? fromRawValue(String rawValue) {
    for (final style in values) {
      if (style.name == rawValue) return style;
    }
    return null;
  }
}

/// Port of `AppSettings` (`OshiLife/Data/Models/AppSettings.swift`).
///
/// Preference keys and raw values are identical to iOS so that a future
/// settings export can round-trip. `customAccentColor` is stored as the
/// same JSON object iOS encodes (here as a JSON string).
///
/// The iOS legacy `eventDisplayMode` fallback and its first-launch
/// write-back are deliberately not ported: Android has no legacy installs
/// (plan §6.3).
class AppSettings extends ChangeNotifier {
  AppSettings(this._prefs)
    : _accentColorMode =
          AccentColorMode.fromRawValue(
            _prefs.getString(_Key.accentColorMode) ?? '',
          ) ??
          AccentColorMode.oshiLifeDefault,
      _appearance =
          AppAppearance.fromRawValue(_prefs.getString(_Key.appearance) ?? '') ??
          AppAppearance.system,
      _customAccentColor = _readCustomAccentColor(_prefs),
      _oshiColor =
          OshiColor.fromRawValue(_prefs.getString(_Key.oshiColor) ?? '') ??
          OshiColor.purple,
      _homeDisplayStyle =
          HomeDisplayStyle.fromRawValue(
            _prefs.getString(_Key.homeDisplayStyle) ?? '',
          ) ??
          HomeDisplayStyle.card,
      _language =
          AppLanguage.fromRawValue(_prefs.getString(_Key.language) ?? '') ??
          AppLanguage.system;

  final SharedPreferences _prefs;

  AccentColorMode _accentColorMode;
  AppAppearance _appearance;
  AccentColorValue _customAccentColor;
  OshiColor _oshiColor;
  HomeDisplayStyle _homeDisplayStyle;
  AppLanguage _language;

  AccentColorMode get accentColorMode => _accentColorMode;

  set accentColorMode(AccentColorMode newValue) {
    _accentColorMode = newValue;
    unawaited(_prefs.setString(_Key.accentColorMode, newValue.name));
    notifyListeners();
  }

  AppAppearance get appearance => _appearance;

  set appearance(AppAppearance newValue) {
    _appearance = newValue;
    unawaited(_prefs.setString(_Key.appearance, newValue.name));
    notifyListeners();
  }

  AccentColorValue get customAccentColor => _customAccentColor;

  set customAccentColor(AccentColorValue newValue) {
    _customAccentColor = newValue;
    unawaited(
      _prefs.setString(_Key.customAccentColor, jsonEncode(newValue.toJson())),
    );
    notifyListeners();
  }

  OshiColor get oshiColor => _oshiColor;

  set oshiColor(OshiColor newValue) {
    _oshiColor = newValue;
    unawaited(_prefs.setString(_Key.oshiColor, newValue.name));
    notifyListeners();
  }

  HomeDisplayStyle get homeDisplayStyle => _homeDisplayStyle;

  set homeDisplayStyle(HomeDisplayStyle newValue) {
    _homeDisplayStyle = newValue;
    unawaited(_prefs.setString(_Key.homeDisplayStyle, newValue.name));
    notifyListeners();
  }

  AppLanguage get language => _language;

  set language(AppLanguage newValue) {
    _language = newValue;
    unawaited(_prefs.setString(_Key.language, newValue.name));
    notifyListeners();
  }

  static AccentColorValue _readCustomAccentColor(SharedPreferences prefs) {
    final raw = prefs.getString(_Key.customAccentColor);
    if (raw == null) return AccentColorValue.oshiLifeDefault;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return AccentColorValue.oshiLifeDefault;
      }
      final value = AccentColorValue.fromJson(decoded);
      return value.isValid ? value : AccentColorValue.oshiLifeDefault;
    } on Object {
      return AccentColorValue.oshiLifeDefault;
    }
  }
}

abstract final class _Key {
  static const accentColorMode = 'settings.accentColorMode';
  static const appearance = 'settings.appearance';
  static const customAccentColor = 'settings.customAccentColor';
  static const homeDisplayStyle = 'settings.homeDisplayStyle';
  static const language = 'settings.language';
  static const oshiColor = 'settings.oshiColor';
}
