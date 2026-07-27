// Rasterizes the legacy (API < 26) launcher icons from the same design as
// the adaptive icon (res/drawable/ic_launcher_foreground.xml + accent
// background): a white beamed-eighth-notes glyph on a #C84EF0 rounded
// rect. Placeholder until the shared brand asset exists.
//
// Run from the OshiLifeAndroid directory:
//   dart run tool/generate_launcher_icons.dart
//
// Overwrites android/app/src/main/res/mipmap-*/ic_launcher.png. Re-run
// only when the icon design changes; commit the PNGs.
import 'dart:io';

import 'package:image/image.dart' as img;

/// Density-bucket icon sizes in px.
const Map<String, int> densities = {
  'mdpi': 48,
  'hdpi': 72,
  'xhdpi': 96,
  'xxhdpi': 144,
  'xxxhdpi': 192,
};

/// Default accent — iOS `AppSettings.customAccentColor` default #C84EF0.
final img.Color background = img.ColorRgba8(0xC8, 0x4E, 0xF0, 0xFF);
final img.Color white = img.ColorRgba8(0xFF, 0xFF, 0xFF, 0xFF);

/// Glyph geometry in the adaptive icon's 108-unit space (must stay in
/// sync with ic_launcher_foreground.xml). Legacy icons render the full
/// canvas (no adaptive mask crop), so the glyph is scaled up around the
/// canvas center to keep a similar visual weight.
const double viewport = 108;
const double legacyScale = 1.35;

double _map(double coord, int size) =>
    ((coord - viewport / 2) * legacyScale + viewport / 2) * size / viewport;

void _rect(
  img.Image canvas,
  int size, {
  required double x1,
  required double y1,
  required double x2,
  required double y2,
}) {
  img.fillRect(
    canvas,
    x1: _map(x1, size).round(),
    y1: _map(y1, size).round(),
    x2: _map(x2, size).round(),
    y2: _map(y2, size).round(),
    color: white,
  );
}

void _circle(
  img.Image canvas,
  int size, {
  required double cx,
  required double cy,
  required double r,
}) {
  img.fillCircle(
    canvas,
    x: _map(cx, size).round(),
    y: _map(cy, size).round(),
    radius: (r * legacyScale * size / viewport).round(),
    color: white,
    antialias: true,
  );
}

void main() {
  const resDir = 'android/app/src/main/res';
  if (!Directory(resDir).existsSync()) {
    stderr.writeln('Run from the OshiLifeAndroid directory.');
    exit(1);
  }

  densities.forEach((density, size) {
    final canvas = img.Image(width: size, height: size, numChannels: 4);

    // Rounded-rect background, ~20% corner radius (classic legacy shape).
    img.fillRect(
      canvas,
      x1: 0,
      y1: 0,
      x2: size - 1,
      y2: size - 1,
      color: background,
      radius: size * 0.20,
    );

    // Beam, stems, note heads — same coordinates as the vector drawable.
    _rect(canvas, size, x1: 45.25, y1: 34, x2: 72.75, y2: 40);
    _rect(canvas, size, x1: 45.25, y1: 34, x2: 48.25, y2: 69);
    _rect(canvas, size, x1: 69.75, y1: 34, x2: 72.75, y2: 69);
    _circle(canvas, size, cx: 41.75, cy: 69, r: 6.5);
    _circle(canvas, size, cx: 66.25, cy: 69, r: 6.5);

    final path = '$resDir/mipmap-$density/ic_launcher.png';
    File(path).writeAsBytesSync(img.encodePng(canvas));
    stdout.writeln('Wrote $path (${size}x$size)');
  });
}
