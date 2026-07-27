import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oshilife/import/fx_twitter_client.dart';
import 'package:oshilife/import/remote_image_data_client.dart';

// Direct coverage of Shared/Networking/RemoteImageDataClient.swift
// semantics (iOS covers these through the draft-builder tests).
void main() {
  final url = Uri.parse('https://pbs.twimg.com/media/cover.jpg');

  test('returns image bytes on success', () async {
    final client = RemoteImageDataClient(
      client: MockClient(
        (request) async =>
            http.Response.bytes(Uint8List.fromList([0xFF, 0xD8, 0xFF]), 200),
      ),
    );
    expect(await client.fetchImage(url), [0xFF, 0xD8, 0xFF]);
  });

  test('rejects empty and oversized payloads', () async {
    var body = Uint8List(0);
    final client = RemoteImageDataClient(
      client: MockClient((request) async => http.Response.bytes(body, 200)),
    );

    await expectLater(
      client.fetchImage(url),
      throwsA(
        isA<FXTwitterException>().having(
          (e) => e.kind,
          'kind',
          FXTwitterErrorKind.responseTooLarge,
        ),
      ),
    );

    body = Uint8List(RemoteImageDataClient.maximumImageBytes + 1);
    await expectLater(
      client.fetchImage(url),
      throwsA(
        isA<FXTwitterException>().having(
          (e) => e.kind,
          'kind',
          FXTwitterErrorKind.responseTooLarge,
        ),
      ),
    );
  });

  test('rejects HTTP errors', () async {
    final client = RemoteImageDataClient(
      client: MockClient((request) async => http.Response('', 404)),
    );
    await expectLater(
      client.fetchImage(url),
      throwsA(
        isA<FXTwitterException>()
            .having((e) => e.kind, 'kind', FXTwitterErrorKind.httpStatus)
            .having((e) => e.statusCode, 'statusCode', 404),
      ),
    );
  });
}
