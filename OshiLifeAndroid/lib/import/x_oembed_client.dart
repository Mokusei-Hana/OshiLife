import 'dart:convert';

import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'package:oshilife/import/capped_http.dart';
import 'package:oshilife/import/x_url_validator.dart';

/// Port of `XOEmbedMetadata` (`Shared/Networking/XOEmbedClient.swift`).
class XOEmbedMetadata {
  const XOEmbedMetadata({
    required this.canonicalUrl,
    required this.authorName,
    this.postText,
    this.linkedUrls = const [],
  });

  final Uri canonicalUrl;
  final String authorName;
  final String? postText;
  final List<Uri> linkedUrls;
}

enum XOEmbedErrorKind {
  invalidUrl,
  invalidResponse,
  responseTooLarge,
  httpStatus,
}

/// Port of `XOEmbedError`. Carries the iOS localization key so the UI
/// layer can render the same localized message.
class XOEmbedException implements Exception {
  const XOEmbedException.invalidUrl()
    : kind = XOEmbedErrorKind.invalidUrl,
      statusCode = null;

  const XOEmbedException.invalidResponse()
    : kind = XOEmbedErrorKind.invalidResponse,
      statusCode = null;

  const XOEmbedException.responseTooLarge()
    : kind = XOEmbedErrorKind.responseTooLarge,
      statusCode = null;

  const XOEmbedException.httpStatus(int this.statusCode)
    : kind = XOEmbedErrorKind.httpStatus;

  final XOEmbedErrorKind kind;
  final int? statusCode;

  /// iOS `errorDescription` localization keys.
  String get localizationKey => switch (kind) {
    XOEmbedErrorKind.invalidUrl => 'error.invalid_x_url',
    XOEmbedErrorKind.invalidResponse => 'error.oembed_response',
    XOEmbedErrorKind.responseTooLarge => 'error.oembed_too_large',
    XOEmbedErrorKind.httpStatus => 'error.oembed_http',
  };

  @override
  String toString() => switch (kind) {
    XOEmbedErrorKind.httpStatus => 'XOEmbedException.httpStatus($statusCode)',
    _ => 'XOEmbedException.${kind.name}',
  };
}

/// Port of the `XOEmbedFetching` protocol (stub seam for the draft builder).
// ignore: one_member_abstracts
abstract interface class XOEmbedFetching {
  Future<XOEmbedMetadata> fetch(Uri postUrl);
}

/// Port of `XOEmbedClient` — the primary metadata source, using X's
/// official oEmbed endpoint (no API auth, no scraping).
class XOEmbedClient implements XOEmbedFetching {
  XOEmbedClient({http.Client? client}) : _client = client ?? http.Client();

  static const int maximumResponseBytes = 512 * 1024;

  final http.Client _client;

  static final RegExp _paragraphPattern = RegExp(
    r'<p(?:\s[^>]*)?>(.*?)</p>',
    caseSensitive: false,
    dotAll: true,
  );

  static final RegExp _anchorHrefPattern = RegExp(
    '''<a\\b[^>]*\\bhref\\s*=\\s*["']([^"']+)["']''',
    caseSensitive: false,
  );

  static final RegExp _brPattern = RegExp(r'<br\s*/?>', caseSensitive: false);

  static final RegExp _tagPattern = RegExp(r'<[^>]+>');

  @override
  Future<XOEmbedMetadata> fetch(Uri postUrl) async {
    final normalized = XUrlValidator.normalizedPostUrl(postUrl);
    if (normalized == null) throw const XOEmbedException.invalidUrl();

    final endpoint = Uri.https('publish.x.com', '/oembed', {
      'url': normalized.toString(),
    });

    final CappedResponse response;
    try {
      response = await cappedGet(
        _client,
        endpoint,
        maxBytes: maximumResponseBytes,
      );
    } on XOEmbedException {
      rethrow;
    } on http.ClientException {
      throw const XOEmbedException.invalidResponse();
    }
    if (!response.isSuccess) {
      throw XOEmbedException.httpStatus(response.statusCode);
    }
    if (response.exceededCap) {
      throw const XOEmbedException.responseTooLarge();
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const XOEmbedException.invalidResponse();
    }
    if (decoded is! Map<String, dynamic>) {
      throw const XOEmbedException.invalidResponse();
    }
    final rawUrl = decoded['url'];
    final authorName = decoded['author_name'];
    final html = decoded['html'];
    if (rawUrl is! String || authorName is! String || html is! String) {
      throw const XOEmbedException.invalidResponse();
    }
    final decodedUrl = Uri.tryParse(rawUrl);
    if (decodedUrl == null) throw const XOEmbedException.invalidResponse();

    return XOEmbedMetadata(
      canonicalUrl: XUrlValidator.normalizedPostUrl(decodedUrl) ?? normalized,
      authorName: authorName,
      postText: postText(html),
      linkedUrls: linkedUrls(html),
    );
  }

  /// Port of `linkedURLs(from:)`: anchor hrefs with `&amp;` decoded,
  /// http(s) only, ordered dedup.
  static List<Uri> linkedUrls(String html) {
    final seen = <String>{};
    final results = <Uri>[];
    for (final match in _anchorHrefPattern.allMatches(html)) {
      final value = match.group(1)!.replaceAll('&amp;', '&');
      final url = Uri.tryParse(value);
      if (url == null) continue;
      final scheme = url.scheme.toLowerCase();
      if (scheme != 'http' && scheme != 'https') continue;
      if (!seen.add(url.toString())) continue;
      results.add(url);
    }
    return results;
  }

  /// Port of `postText(from:)`: isolates the first `<p>` paragraph and
  /// converts it to plain text — `<br>` becomes a newline, tags are
  /// stripped, and HTML entities are decoded (the iOS build does this via
  /// `NSAttributedString` HTML rendering; `html_unescape` reproduces the
  /// entity coverage).
  static String? postText(String html) {
    final match = _paragraphPattern.firstMatch(html);
    if (match == null) return null;
    final fragment = match.group(1)!;
    final text = HtmlUnescape()
        .convert(
          fragment.replaceAll(_brPattern, '\n').replaceAll(_tagPattern, ''),
        )
        .trim();
    return text.isEmpty ? null : text;
  }
}
