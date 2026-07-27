import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Result of a size-capped GET: the HTTP status, the body bytes (truncated
/// reads never happen — [exceededCap] is set instead and the transfer is
/// aborted), and whether the cap was exceeded.
class CappedResponse {
  const CappedResponse({
    required this.statusCode,
    required this.bodyBytes,
    required this.exceededCap,
    this.headers = const {},
  });

  final int statusCode;
  final Uint8List bodyBytes;
  final bool exceededCap;

  /// Response headers with lowercase names (package:http normalizes them).
  final Map<String, String> headers;

  /// iOS `(200..<300).contains(statusCode)`.
  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

/// Shared GET helper for the import clients, mirroring the iOS ephemeral
/// session configuration: 12 s request / 15 s resource timeouts, no
/// caching semantics (each call is a fresh request), and a hard response
/// size cap enforced while streaming.
Future<CappedResponse> cappedGet(
  http.Client client,
  Uri url, {
  required int maxBytes,
  Map<String, String>? headers,
  bool followRedirects = true,
  Duration timeout = const Duration(seconds: 15),
}) async {
  final request = http.Request('GET', url);
  if (headers != null) request.headers.addAll(headers);
  request.followRedirects = followRedirects;

  Future<CappedResponse> read() async {
    final response = await client.send(request);
    final builder = BytesBuilder(copy: false);
    var exceeded = false;
    await for (final chunk in response.stream) {
      builder.add(chunk);
      if (builder.length > maxBytes) {
        exceeded = true;
        break;
      }
    }
    return CappedResponse(
      statusCode: response.statusCode,
      bodyBytes: builder.takeBytes(),
      exceededCap: exceeded,
      headers: response.headers,
    );
  }

  return read().timeout(timeout);
}
