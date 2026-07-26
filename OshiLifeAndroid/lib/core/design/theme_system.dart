import 'package:flutter/material.dart';
import 'package:oshilife/core/design/accent_color_value.dart';
import 'package:oshilife/data/settings/app_settings.dart';

/// Port of `ThemePalette` + `ThemeSystem` from
/// `OshiLife/Core/DesignSystem/ThemeSystem.swift`.
class ThemePalette {
  const ThemePalette({
    required this.primary,
    required this.background,
    required this.border,
  });

  final Color primary;
  final Color background;
  final Color border;
}

abstract final class ThemeSystem {
  /// Semantic colors. Only `locationColor` is consumed on iOS today; the
  /// others are carried for parity with the Swift declarations.
  static const Color locationColor = Colors.green;
  static const Color warningColor = Colors.orange;
  static const Color successColor = Colors.green;
  static const Color errorColor = Colors.red;

  static ThemePalette palette({
    required AppSettings settings,
    required Brightness brightness,
  }) {
    final dark = brightness == Brightness.dark;
    switch (settings.accentColorMode) {
      case AccentColorMode.oshiLifeDefault:
        final accent = AccentColorValue.oshiLifeDefault.color;
        return ThemePalette(
          primary: accent,
          background: accent.withValues(alpha: dark ? 0.18 : 0.12),
          border: accent.withValues(alpha: dark ? 0.60 : 0.42),
        );
      case AccentColorMode.oshiColor:
        return ThemePalette(
          primary: settings.oshiColor.primaryColor(brightness),
          background: settings.oshiColor.lightBackgroundColor(brightness),
          border: settings.oshiColor.borderColor(brightness),
        );
      case AccentColorMode.custom:
        final color = settings.customAccentColor.color;
        return ThemePalette(
          primary: color,
          background: color.withValues(alpha: dark ? 0.18 : 0.12),
          border: color.withValues(alpha: dark ? 0.60 : 0.42),
        );
    }
  }

  /// Builds the Material theme for one brightness. The seed drives the
  /// tonal scheme, but `primary` is pinned to the exact 推し色 so the accent
  /// never tone-shifts (plan §5.2).
  static ThemeData buildTheme({
    required AppSettings settings,
    required Brightness brightness,
  }) {
    final palette = ThemeSystem.palette(
      settings: settings,
      brightness: brightness,
    );
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: brightness,
    ).copyWith(primary: palette.primary);
    return ThemeData(
      colorScheme: scheme,
      brightness: brightness,
      extensions: [
        OshiTheme(
          primary: palette.primary,
          background: palette.background,
          border: palette.border,
          locationColor: locationColor,
        ),
      ],
    );
  }
}

/// Theme extension carrying the OshiLife palette to widgets.
class OshiTheme extends ThemeExtension<OshiTheme> {
  const OshiTheme({
    required this.primary,
    required this.background,
    required this.border,
    required this.locationColor,
  });

  final Color primary;
  final Color background;
  final Color border;
  final Color locationColor;

  static OshiTheme of(BuildContext context) =>
      Theme.of(context).extension<OshiTheme>()!;

  @override
  OshiTheme copyWith({
    Color? primary,
    Color? background,
    Color? border,
    Color? locationColor,
  }) {
    return OshiTheme(
      primary: primary ?? this.primary,
      background: background ?? this.background,
      border: border ?? this.border,
      locationColor: locationColor ?? this.locationColor,
    );
  }

  @override
  OshiTheme lerp(ThemeExtension<OshiTheme>? other, double t) {
    if (other is! OshiTheme) return this;
    return OshiTheme(
      primary: Color.lerp(primary, other.primary, t)!,
      background: Color.lerp(background, other.background, t)!,
      border: Color.lerp(border, other.border, t)!,
      locationColor: Color.lerp(locationColor, other.locationColor, t)!,
    );
  }
}
