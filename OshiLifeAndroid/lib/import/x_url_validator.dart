/// Port of `Shared/Parsing/XURLValidator.swift`.
///
/// Accepts https-only status URLs on the allowed X/Twitter hosts and
/// normalizes them to `https://x.com/{user}/status/{id}` — user info,
/// port, query, fragment, and trailing path segments are stripped, and the
/// status id must be ASCII digits (full-width digits are rejected).
abstract final class XUrlValidator {
  static const List<String> _allowedHosts = [
    'x.com',
    'www.x.com',
    'twitter.com',
    'www.twitter.com',
    'mobile.twitter.com',
  ];

  static final RegExp _urlPattern = RegExp(
    r'''https://[^\s<>"']+''',
    caseSensitive: false,
  );

  static final RegExp _asciiDigits = RegExp(r'^[0-9]+$');

  /// Characters trimmed from the end of URL candidates found in free text.
  static const String _trailingPunctuation = ',.!?;:、。)]}';

  static Uri? normalizedPostUrl(Uri candidate) {
    if (candidate.scheme.toLowerCase() != 'https') return null;
    final host = candidate.host.toLowerCase();
    if (!_allowedHosts.contains(host)) return null;

    final segments = candidate.path
        .split('/')
        .where((part) => part.isNotEmpty)
        .toList();
    if (segments.length < 3) return null;
    if (segments[1].toLowerCase() != 'status') return null;
    if (segments[0].isEmpty) return null;
    if (!_asciiDigits.hasMatch(segments[2])) return null;

    return Uri(
      scheme: 'https',
      host: 'x.com',
      path: '/${segments[0]}/status/${segments[2]}',
    );
  }

  static Uri? normalizedPostUrlFromText(String text) {
    final value = text.trim();
    if (value.isEmpty) return null;
    final candidate = Uri.tryParse(value);
    if (candidate == null) return null;
    return normalizedPostUrl(candidate);
  }

  static Uri? firstPostUrl(String text) {
    for (final match in _urlPattern.allMatches(text)) {
      var rawValue = match.group(0)!;
      while (rawValue.isNotEmpty &&
          _trailingPunctuation.contains(rawValue[rawValue.length - 1])) {
        rawValue = rawValue.substring(0, rawValue.length - 1);
      }
      final candidate = Uri.tryParse(rawValue);
      if (candidate == null) continue;
      final normalized = normalizedPostUrl(candidate);
      if (normalized != null) return normalized;
    }
    return null;
  }
}
