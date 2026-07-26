import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshilife/features/import/share_intent_service.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('oshilife/share');

  group('decodePayload', () {
    test('keeps text and image bytes', () {
      final payload = ShareIntentService.decodePayload({
        'text': 'https://x.com/oshi/status/42',
        'image': Uint8List.fromList([1, 2, 3]),
      });
      expect(payload!.text, 'https://x.com/oshi/status/42');
      expect(payload.imageBytes, [1, 2, 3]);
    });

    test('treats a missing or empty image as absent', () {
      final payload = ShareIntentService.decodePayload({
        'text': 'こんにちは',
        'image': Uint8List(0),
      });
      expect(payload!.text, 'こんにちは');
      expect(payload.imageBytes, isNull);
    });

    test('rejects payloads with nothing to import', () {
      expect(ShareIntentService.decodePayload({'text': ''}), isNull);
      expect(ShareIntentService.decodePayload('not a map'), isNull);
      expect(ShareIntentService.decodePayload(null), isNull);
    });
  });

  group('consumeInitialShare', () {
    tearDown(() {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    });

    test('decodes the buffered share from the host', () async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        expect(call.method, 'consumeInitialShare');
        return {'text': 'https://x.com/oshi/status/42', 'image': null};
      });

      final service = ShareIntentService();
      final payload = await service.consumeInitialShare();
      expect(payload!.text, 'https://x.com/oshi/status/42');
      expect(payload.imageBytes, isNull);
    });

    test('returns null when the host buffered nothing', () async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async => null,
      );

      final service = ShareIntentService();
      expect(await service.consumeInitialShare(), isNull);
    });

    test('swallows the missing host shim (tests, desktop)', () async {
      final service = ShareIntentService();
      expect(await service.consumeInitialShare(), isNull);
    });
  });

  test('listen delivers onShareReceived events', () async {
    final service = ShareIntentService();
    final received = <SharedPayload>[];
    service.listen(received.add);

    const codec = StandardMethodCodec();
    ServicesBinding.instance.channelBuffers.push(
      'oshilife/share',
      codec.encodeMethodCall(
        const MethodCall('onShareReceived', {'text': 'ライブ告知', 'image': null}),
      ),
      (ByteData? reply) {},
    );
    // Let the async channel dispatch complete.
    await Future<void>.delayed(Duration.zero);

    expect(received, hasLength(1));
    expect(received.single.text, 'ライブ告知');
  });
}
