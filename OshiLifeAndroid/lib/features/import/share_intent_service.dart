import 'package:flutter/services.dart';

/// What another app shared into OshiLife: the raw `EXTRA_TEXT` and the
/// optional `EXTRA_STREAM` image bytes (already read and capped by the
/// Kotlin shim).
class SharedPayload {
  const SharedPayload({required this.text, this.imageBytes});

  final String text;
  final Uint8List? imageBytes;
}

/// Dart side of the `oshilife/share` MethodChannel (plan §7.2).
///
/// The Kotlin shim buffers a cold-start share until the Dart side asks for
/// it with [consumeInitialShare] — the Android replacement for the iOS
/// App-Group queue — and pushes warm-start shares as `onShareReceived`
/// events delivered to the [listen] callback.
class ShareIntentService {
  ShareIntentService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('oshilife/share');

  final MethodChannel _channel;

  void listen(void Function(SharedPayload payload) onShare) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onShareReceived') {
        final payload = decodePayload(call.arguments);
        if (payload != null) onShare(payload);
      }
      return null;
    });
  }

  Future<SharedPayload?> consumeInitialShare() async {
    try {
      final raw = await _channel.invokeMethod<dynamic>('consumeInitialShare');
      return decodePayload(raw);
    } on MissingPluginException {
      // No host shim on this platform (tests, desktop runs).
      return null;
    }
  }

  static SharedPayload? decodePayload(Object? raw) {
    if (raw is! Map) return null;
    final text = raw['text'];
    final image = raw['image'];
    final textValue = text is String ? text : '';
    final imageBytes = image is Uint8List && image.isNotEmpty ? image : null;
    if (textValue.isEmpty && imageBytes == null) return null;
    return SharedPayload(text: textValue, imageBytes: imageBytes);
  }
}
