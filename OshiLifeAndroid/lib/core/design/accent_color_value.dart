import 'dart:ui';

/// Port of `AccentColorValue` from
/// `OshiLife/Core/DesignSystem/ThemeSystem.swift`.
///
/// Persisted as JSON (`{"red":…,"green":…,"blue":…,"alpha":…}`) under the
/// `settings.customAccentColor` preference key, same shape as the iOS
/// `JSONEncoder` output.
class AccentColorValue {
  const AccentColorValue({
    required this.red,
    required this.green,
    required this.blue,
    this.alpha = 1,
  });

  factory AccentColorValue.fromJson(Map<String, dynamic> json) {
    return AccentColorValue(
      red: (json['red'] as num).toDouble(),
      green: (json['green'] as num).toDouble(),
      blue: (json['blue'] as num).toDouble(),
      alpha: (json['alpha'] as num).toDouble(),
    );
  }

  factory AccentColorValue.fromColor(Color color) {
    return AccentColorValue(
      red: color.r,
      green: color.g,
      blue: color.b,
      alpha: color.a,
    );
  }

  /// Matches the iOS default accent (`AccentColor` asset): ≈ #C84EF0.
  static const AccentColorValue oshiLifeDefault = AccentColorValue(
    red: 0.784,
    green: 0.306,
    blue: 0.941,
  );

  final double red;
  final double green;
  final double blue;
  final double alpha;

  Color get color =>
      Color.from(alpha: alpha, red: red, green: green, blue: blue);

  bool get isValid {
    return [red, green, blue, alpha].every(
      (component) => component.isFinite && component >= 0 && component <= 1,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'red': red,
      'green': green,
      'blue': blue,
      'alpha': alpha,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is AccentColorValue &&
        other.red == red &&
        other.green == green &&
        other.blue == blue &&
        other.alpha == alpha;
  }

  @override
  int get hashCode => Object.hash(red, green, blue, alpha);
}
