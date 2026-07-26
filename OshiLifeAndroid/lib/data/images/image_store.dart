import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

/// Port of `OshiLife/Services/ImageStore.swift`.
///
/// Pipeline parity: decode any supported format → apply EXIF orientation →
/// downscale so the longest edge is at most 2400 px → encode JPEG at
/// quality 0.85 → write to `<root>/Images/<uppercase-UUID>.jpg` and return
/// the relative path (`Images/<UUID>.jpg`), which is what gets persisted on
/// `LiveEvent.coverImagePath`.
///
/// Implementation note: uses the pure-Dart `image` package (the plan's
/// documented fallback) instead of a platform-channel plugin so the exact
/// pipeline is unit-testable on the Dart VM; the transcode runs in an
/// isolate to keep the UI thread free.
class ImageStore {
  ImageStore({required this.root});

  static const String imagesDirectory = 'Images';
  static const int maxPixelSize = 2400;
  static const int jpegQuality = 85;

  final Directory root;

  Future<String> saveJpeg(List<int> data) async {
    final encoded = await Isolate.run(() => _transcode(data));
    final directory = Directory('${root.path}/$imagesDirectory');
    await directory.create(recursive: true);
    final filename = '${const Uuid().v4().toUpperCase()}.jpg';
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(encoded, flush: true);
    return '$imagesDirectory/$filename';
  }

  /// Nil-tolerant read, mirroring `image(at:)`: null path or missing file
  /// returns null instead of throwing.
  File? imageFile(String? relativePath) {
    if (relativePath == null) return null;
    final file = File('${root.path}/$relativePath');
    return file.existsSync() ? file : null;
  }

  /// No-op when the path is null or the file is already gone.
  Future<void> remove(String? relativePath) async {
    if (relativePath == null) return;
    final file = File('${root.path}/$relativePath');
    if (!file.existsSync()) return;
    await file.delete();
  }

  static List<int> _transcode(List<int> data) {
    img.Image? decoded;
    try {
      decoded = img.decodeImage(
        data is Uint8List ? data : Uint8List.fromList(data),
      );
    } on Object {
      decoded = null;
    }
    if (decoded == null) {
      throw const ImageStoreException.invalidImage();
    }
    var normalized = img.bakeOrientation(decoded);
    final longestEdge = normalized.width > normalized.height
        ? normalized.width
        : normalized.height;
    if (longestEdge > maxPixelSize) {
      final scale = maxPixelSize / longestEdge;
      normalized = img.copyResize(
        normalized,
        width: (normalized.width * scale).round(),
        height: (normalized.height * scale).round(),
        interpolation: img.Interpolation.linear,
      );
    }
    try {
      return img.encodeJpg(normalized, quality: jpegQuality);
    } on Object {
      throw const ImageStoreException.encodingFailed();
    }
  }
}

/// Port of `ImageStoreError`.
class ImageStoreException implements Exception {
  const ImageStoreException.invalidImage() : reason = 'invalidImage';

  const ImageStoreException.encodingFailed() : reason = 'encodingFailed';

  final String reason;

  /// Localization key, matching the iOS `errorDescription` resources.
  String get localizationKey => switch (reason) {
    'invalidImage' => 'error.invalid_image',
    _ => 'error.image_encoding',
  };

  @override
  String toString() => 'ImageStoreException($reason)';
}
