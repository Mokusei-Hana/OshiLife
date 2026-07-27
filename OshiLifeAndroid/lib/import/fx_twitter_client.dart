import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:oshilife/import/capped_http.dart';
import 'package:oshilife/import/x_url_validator.dart';

/// Port of the FxTwitter DTOs (`Shared/Networking/FXTwitterClient.swift`).
/// Decoding is tolerant: `media`/`all` absent → empty, unparseable item
/// URLs → null.
class FXTwitterMediaItem {
  const FXTwitterMediaItem({this.type, this.url});

  factory FXTwitterMediaItem.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['url'];
    return FXTwitterMediaItem(
      type: json['type'] as String?,
      url: rawUrl is String ? Uri.tryParse(rawUrl) : null,
    );
  }

  final String? type;
  final Uri? url;
}

class FXTwitterTweet {
  const FXTwitterTweet({this.url, this.mediaAll = const []});

  factory FXTwitterTweet.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['url'];
    final media = json['media'];
    final all = media is Map<String, dynamic> ? media['all'] : null;
    return FXTwitterTweet(
      url: rawUrl is String ? Uri.tryParse(rawUrl) : null,
      mediaAll: all is List
          ? all
                .whereType<Map<String, dynamic>>()
                .map(FXTwitterMediaItem.fromJson)
                .toList()
          : const [],
    );
  }

  final Uri? url;

  /// `tweet.media.all`, flattened (`[]` when media is absent).
  final List<FXTwitterMediaItem> mediaAll;
}

class FXTwitterResponse {
  const FXTwitterResponse({this.code, required this.tweet});

  factory FXTwitterResponse.fromJson(Map<String, dynamic> json) {
    final tweet = json['tweet'];
    if (tweet is! Map<String, dynamic>) {
      throw const FormatException('FXTwitterResponse requires tweet');
    }
    return FXTwitterResponse(
      code: (json['code'] as num?)?.toInt(),
      tweet: FXTwitterTweet.fromJson(tweet),
    );
  }

  final int? code;
  final FXTwitterTweet tweet;
}

class FXTwitterMetadata {
  const FXTwitterMetadata({
    required this.canonicalUrl,
    required this.imageUrls,
  });

  final Uri canonicalUrl;
  final List<Uri> imageUrls;
}

enum FXTwitterErrorKind {
  invalidUrl,
  invalidResponse,
  responseTooLarge,
  httpStatus,
}

/// Port of `FXTwitterError`. The iOS descriptions are unlocalized English
/// literals — kept identical here.
class FXTwitterException implements Exception {
  const FXTwitterException.invalidUrl()
    : kind = FXTwitterErrorKind.invalidUrl,
      statusCode = null;

  const FXTwitterException.invalidResponse()
    : kind = FXTwitterErrorKind.invalidResponse,
      statusCode = null;

  const FXTwitterException.responseTooLarge()
    : kind = FXTwitterErrorKind.responseTooLarge,
      statusCode = null;

  const FXTwitterException.httpStatus(int this.statusCode)
    : kind = FXTwitterErrorKind.httpStatus;

  final FXTwitterErrorKind kind;
  final int? statusCode;

  String get message => switch (kind) {
    FXTwitterErrorKind.invalidUrl => 'Invalid X URL',
    FXTwitterErrorKind.invalidResponse => 'Invalid FxTwitter response',
    FXTwitterErrorKind.responseTooLarge => 'FxTwitter response is too large',
    FXTwitterErrorKind.httpStatus => 'FxTwitter returned HTTP $statusCode',
  };

  @override
  String toString() => message;
}

/// Port of the `FXTwitterFetching` protocol.
// ignore: one_member_abstracts
abstract interface class FXTwitterFetching {
  Future<FXTwitterMetadata> fetch(Uri postUrl);
}

/// Port of `FXTwitterClient` — media-only supplementary source.
class FXTwitterClient implements FXTwitterFetching {
  FXTwitterClient({http.Client? client}) : _client = client ?? http.Client();

  static const int maximumResponseBytes = 1 * 1024 * 1024;

  final http.Client _client;

  @override
  Future<FXTwitterMetadata> fetch(Uri postUrl) async {
    final normalized = XUrlValidator.normalizedPostUrl(postUrl);
    if (normalized == null) throw const FXTwitterException.invalidUrl();
    final statusId = normalized.pathSegments.last;
    final endpoint = Uri.parse('https://api.fxtwitter.com/status/$statusId');

    final CappedResponse response;
    try {
      response = await cappedGet(
        _client,
        endpoint,
        maxBytes: maximumResponseBytes,
      );
    } on http.ClientException {
      throw const FXTwitterException.invalidResponse();
    }
    if (!response.isSuccess) {
      throw FXTwitterException.httpStatus(response.statusCode);
    }
    if (response.exceededCap) {
      throw const FXTwitterException.responseTooLarge();
    }

    final FXTwitterResponse decoded;
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is! Map<String, dynamic>) {
        throw const FormatException('not an object');
      }
      decoded = FXTwitterResponse.fromJson(json);
    } on FormatException {
      throw const FXTwitterException.invalidResponse();
    }

    final canonicalUrl =
        XUrlValidator.normalizedPostUrl(decoded.tweet.url ?? normalized) ??
        normalized;
    return FXTwitterMetadata(
      canonicalUrl: canonicalUrl,
      imageUrls: imageUrls(decoded),
    );
  }

  /// Port of `imageURLs(in:)`: photos only, http(s) only, ordered dedup.
  static List<Uri> imageUrls(FXTwitterResponse response) {
    final seen = <String>{};
    final results = <Uri>[];
    for (final item in response.tweet.mediaAll) {
      if (item.type?.toLowerCase() != 'photo') continue;
      final url = item.url;
      if (url == null) continue;
      final scheme = url.scheme.toLowerCase();
      if (scheme != 'http' && scheme != 'https') continue;
      if (!seen.add(url.toString())) continue;
      results.add(url);
    }
    return results;
  }
}
