import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:oshilife/import/capped_http.dart';
import 'package:oshilife/import/fx_twitter_client.dart';

/// Port of the `RemoteImageDataFetching` protocol.
// ignore: one_member_abstracts
abstract interface class RemoteImageDataFetching {
  Future<Uint8List> fetchImage(Uri url);
}

/// Port of `Shared/Networking/RemoteImageDataClient.swift`. Reuses the
/// FxTwitter error kinds exactly like iOS does.
class RemoteImageDataClient implements RemoteImageDataFetching {
  RemoteImageDataClient({http.Client? client})
    : _client = client ?? http.Client();

  static const int maximumImageBytes = 25 * 1024 * 1024;

  final http.Client _client;

  @override
  Future<Uint8List> fetchImage(Uri url) async {
    final CappedResponse response;
    try {
      response = await cappedGet(_client, url, maxBytes: maximumImageBytes);
    } on http.ClientException {
      throw const FXTwitterException.invalidResponse();
    }
    if (!response.isSuccess) {
      throw FXTwitterException.httpStatus(response.statusCode);
    }
    if (response.exceededCap || response.bodyBytes.isEmpty) {
      throw const FXTwitterException.responseTooLarge();
    }
    return response.bodyBytes;
  }
}
