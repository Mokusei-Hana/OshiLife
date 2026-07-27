import 'dart:ui';

/// Port of `OshiColor` from `OshiLife/Core/DesignSystem/ThemeSystem.swift`.
///
/// A theme is one seed color plus three opacity ramps; only the `white`
/// case branches on brightness. All sRGB triples are copied verbatim.
enum OshiColor {
  white,
  blue,
  red,
  green,
  yellow,
  orange,
  pink,
  purple,
  aqua;

  String get rawValue => name;

  static OshiColor? fromRawValue(String rawValue) {
    for (final color in values) {
      if (color.name == rawValue) return color;
    }
    return null;
  }

  /// Localization key, identical to the iOS `displayName` resource key.
  String get localizationKey => 'oshi_color.$name';

  Color primaryColor(Brightness brightness) {
    if (this == white) {
      return brightness == Brightness.dark
          ? const Color.from(alpha: 1, red: 1, green: 1, blue: 1)
          : const Color.from(alpha: 1, red: 0.48, green: 0.50, blue: 0.55);
    }
    return _baseColor;
  }

  Color lightBackgroundColor(Brightness brightness) {
    if (this == white) {
      return brightness == Brightness.dark
          ? const Color.from(alpha: 0.14, red: 1, green: 1, blue: 1)
          : const Color.from(alpha: 1, red: 0.96, green: 0.96, blue: 0.97);
    }
    return _baseColor.withValues(
      alpha: brightness == Brightness.dark ? 0.18 : 0.12,
    );
  }

  Color borderColor(Brightness brightness) {
    if (this == white) {
      return brightness == Brightness.dark
          ? const Color.from(alpha: 0.42, red: 1, green: 1, blue: 1)
          : const Color.from(alpha: 1, red: 0.78, green: 0.79, blue: 0.82);
    }
    return _baseColor.withValues(
      alpha: brightness == Brightness.dark ? 0.60 : 0.42,
    );
  }

  Color get _baseColor => switch (this) {
    white => const Color.from(alpha: 1, red: 1, green: 1, blue: 1),
    blue => const Color.from(alpha: 1, red: 0.10, green: 0.45, blue: 0.92),
    red => const Color.from(alpha: 1, red: 0.90, green: 0.16, blue: 0.20),
    green => const Color.from(alpha: 1, red: 0.15, green: 0.65, blue: 0.32),
    yellow => const Color.from(alpha: 1, red: 0.95, green: 0.70, blue: 0.05),
    orange => const Color.from(alpha: 1, red: 0.95, green: 0.42, blue: 0.08),
    pink => const Color.from(alpha: 1, red: 0.94, green: 0.30, blue: 0.58),
    purple => const Color.from(alpha: 1, red: 0.64, green: 0.28, blue: 0.88),
    aqua => const Color.from(alpha: 1, red: 0.00, green: 0.68, blue: 0.72),
  };
}
