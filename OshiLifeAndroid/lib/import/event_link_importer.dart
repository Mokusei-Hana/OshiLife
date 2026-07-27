import 'dart:convert';

import 'package:charset/charset.dart';
import 'package:http/http.dart' as http;
import 'package:oshilife/import/capped_http.dart';
import 'package:oshilife/import/event_page_parsing.dart';
import 'package:oshilife/import/heroines_event_page_parser.dart';
import 'package:oshilife/import/models/event_import_details.dart';

/// Port of the `EventLinkImporting` protocol (stub seam for the builder).
// ignore: one_member_abstracts
abstract interface class EventLinkImporting {
  Future<EventImportDetails?> importDetails(List<Uri> urls);
}

/// Port of `Shared/Import/EventLinkImporter.swift`.
///
/// Decision tree (identical to iOS): no usable links → null; the first
/// link a registered parser supports → fetch and parse it; else a first
/// link on `t.co` → resolve the redirect and parse if supported; else the
/// bare link with no guessed fields. All network/parse failures degrade to
/// the bare-link details, never an error.
class EventLinkImporter implements EventLinkImporting {
  EventLinkImporter({
    http.Client? client,
    this.parsers = const [HeroinesEventPageParser()],
  }) : _client = client ?? http.Client();

  static const int maximumResponseBytes = 2 * 1024 * 1024;

  static const int _maximumRedirects = 5;

  final http.Client _client;
  final List<EventPageParsing> parsers;

  /// Approximation of iOS `NSDataDetector(.link)` over tweet text: RFC 3986
  /// URL characters after an explicit scheme, with trailing punctuation
  /// trimmed. Scheme-less detections (bare domains) are not reproduced —
  /// tweet links are always fully-qualified. Pinned by the ported tests.
  static final RegExp _urlPattern = RegExp(
    r'https?://[A-Za-z0-9\-._~:/?#\[\]@!$&()*+,;=%]+',
    caseSensitive: false,
  );

  static const String _trailingPunctuation = ',.!?;:、。)]}';

  static const List<String> _excludedHosts = [
    // mobile.twitter.com is deliberately NOT excluded — iOS quirk preserved.
    'x.com',
    'www.x.com',
    'twitter.com',
    'www.twitter.com',
  ];

  static List<Uri> urls(String text) {
    final results = <Uri>[];
    for (final match in _urlPattern.allMatches(text)) {
      var rawValue = match.group(0)!;
      while (rawValue.isNotEmpty &&
          _trailingPunctuation.contains(rawValue[rawValue.length - 1])) {
        rawValue = rawValue.substring(0, rawValue.length - 1);
      }
      final url = Uri.tryParse(rawValue);
      if (url != null) results.add(url);
    }
    return results;
  }

  @override
  Future<EventImportDetails?> importDetails(List<Uri> urls) async {
    final links = _uniqueWebUrls(urls);
    if (links.isEmpty) return null;
    final first = links.first;

    Uri? supported;
    for (final link in links) {
      if (parsers.any((parser) => parser.supports(link))) {
        supported = link;
        break;
      }
    }
    if (supported != null) {
      final parser = parsers.firstWhere(
        (parser) => parser.supports(supported!),
      );
      return _fetchAndParse(supported, parser);
    }

    if (first.host.toLowerCase() == 't.co') {
      return _resolveShortLink(first);
    }
    return EventImportDetails(linkedUrl: first);
  }

  Future<EventImportDetails> _fetchAndParse(
    Uri supported,
    EventPageParsing parser,
  ) async {
    try {
      final response = await cappedGet(
        _client,
        supported,
        maxBytes: maximumResponseBytes,
        headers: const {'Accept': 'text/html,application/xhtml+xml'},
      );
      if (!response.isSuccess || response.exceededCap) {
        return EventImportDetails(linkedUrl: supported);
      }
      final html = _decodeHtml(response.bodyBytes);
      if (html == null) {
        return EventImportDetails(linkedUrl: supported);
      }
      return parser.parse(html: html, sourceUrl: supported) ??
          EventImportDetails(linkedUrl: supported);
    } on Object {
      return EventImportDetails(linkedUrl: supported);
    }
  }

  /// iOS lets URLSession follow the redirect and uses `response.url`;
  /// package:http does not expose the final URL, so redirects are followed
  /// manually here — same observable behavior.
  Future<EventImportDetails> _resolveShortLink(Uri shortUrl) async {
    try {
      var current = shortUrl;
      CappedResponse response = await cappedGet(
        _client,
        current,
        maxBytes: maximumResponseBytes,
        followRedirects: false,
      );
      var redirects = 0;
      while (response.statusCode >= 300 &&
          response.statusCode < 400 &&
          redirects < _maximumRedirects) {
        final location = response.headers['location'];
        if (location == null) break;
        current = current.resolve(location);
        redirects += 1;
        response = await cappedGet(
          _client,
          current,
          maxBytes: maximumResponseBytes,
          followRedirects: false,
        );
      }

      final resolvedUrl = current;
      if (response.exceededCap) {
        return EventImportDetails(linkedUrl: resolvedUrl);
      }
      EventPageParsing? parser;
      for (final candidate in parsers) {
        if (candidate.supports(resolvedUrl)) {
          parser = candidate;
          break;
        }
      }
      if (parser == null) {
        return EventImportDetails(linkedUrl: resolvedUrl);
      }
      final html = _decodeHtml(response.bodyBytes);
      if (html == null) {
        return EventImportDetails(linkedUrl: resolvedUrl);
      }
      return parser.parse(html: html, sourceUrl: resolvedUrl) ??
          EventImportDetails(linkedUrl: resolvedUrl);
    } on Object {
      return EventImportDetails(linkedUrl: shortUrl);
    }
  }

  /// UTF-8 first, then EUC-JP — the only non-UTF-8 fallback, matching iOS
  /// (`String(data:encoding:.japaneseEUC)`; Shift_JIS is deliberately not
  /// handled). Both are strict: undecodable bytes → null.
  static String? _decodeHtml(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      try {
        return eucJp.decode(bytes);
      } on Object {
        return null;
      }
    }
  }

  static List<Uri> _uniqueWebUrls(List<Uri> urls) {
    final seen = <String>{};
    final results = <Uri>[];
    for (final url in urls) {
      final scheme = url.scheme.toLowerCase();
      if (scheme != 'http' && scheme != 'https') continue;
      if (_excludedHosts.contains(url.host.toLowerCase())) continue;
      if (!seen.add(url.toString())) continue;
      results.add(url);
    }
    return results;
  }
}
