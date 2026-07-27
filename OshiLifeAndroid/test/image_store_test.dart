import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:oshilife/data/images/image_store.dart';

// Port of OshiLifeTests/ImageStoreTests.swift, plus the ≤2400 px
// longest-edge rule from the shared image-pipeline contract (plan §6.1
// item 8).
void main() {
  late Directory root;
  late ImageStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('OshiLifeImageTests-');
    store = ImageStore(root: root);
  });

  tearDown(() async {
    if (root.existsSync()) {
      await root.delete(recursive: true);
    }
  });

  test('normalizes and deletes image', () async {
    final source = img.Image(width: 32, height: 16);
    img.fill(source, color: img.ColorRgb8(255, 105, 180));
    final pngBytes = img.encodePng(source);

    final path = await store.saveJpeg(pngBytes);
    expect(path, startsWith('Images/'));
    expect(path, endsWith('.jpg'));

    final saved = store.imageFile(path);
    expect(saved, isNotNull);
    final decoded = img.decodeJpg(await saved!.readAsBytes());
    expect(decoded, isNotNull);
    expect(decoded!.width, 32);
    expect(decoded.height, 16);

    await store.remove(path);
    expect(store.imageFile(path), isNull);
    // Removing again is a no-op, like the iOS guard.
    await store.remove(path);
  });

  test('downscales so the longest edge is at most 2400px', () async {
    final source = img.Image(width: 3000, height: 1500);
    img.fill(source, color: img.ColorRgb8(10, 20, 30));
    final pngBytes = img.encodePng(source);

    final path = await store.saveJpeg(pngBytes);
    final decoded = img.decodeJpg(await store.imageFile(path)!.readAsBytes());

    expect(decoded!.width, 2400);
    expect(decoded.height, 1200);
  });

  test('rejects invalid image data', () async {
    await expectLater(
      store.saveJpeg(const [0x00, 0x01]),
      throwsA(isA<ImageStoreException>()),
    );
  });

  test('file names are uppercase UUIDs', () async {
    final source = img.Image(width: 8, height: 8);
    final path = await store.saveJpeg(img.encodePng(source));
    final name = path.split('/').last.replaceAll('.jpg', '');
    expect(name, name.toUpperCase());
  });

  test('nil-tolerant reads and removes', () async {
    expect(store.imageFile(null), isNull);
    expect(store.imageFile('Images/missing.jpg'), isNull);
    await store.remove(null);
    await store.remove('Images/missing.jpg');
  });
}
