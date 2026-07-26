import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oshilife/import/fx_twitter_client.dart';

// Port of OshiLifeTests/FXTwitterClientTests.swift.
void main() {
  test('extracts only unique photo media in order', () {
    final first = Uri.parse('https://pbs.twimg.com/media/first.jpg');
    final second = Uri.parse('https://pbs.twimg.com/media/second.jpg');
    final response = FXTwitterResponse(
      code: 200,
      tweet: FXTwitterTweet(
        url: Uri.parse('https://x.com/oshi/status/42'),
        mediaAll: [
          FXTwitterMediaItem(type: 'photo', url: first),
          FXTwitterMediaItem(type: 'video', url: second),
          FXTwitterMediaItem(type: 'photo', url: first),
          FXTwitterMediaItem(type: 'photo', url: second),
        ],
      ),
    );

    expect(FXTwitterClient.imageUrls(response), [first, second]);
  });

  test('missing media produces no image URLs', () {
    const response = FXTwitterResponse(code: 200, tweet: FXTwitterTweet());

    expect(FXTwitterClient.imageUrls(response), isEmpty);
  });

  test('fetch hits the status endpoint and tolerates missing media', () async {
    late Uri requested;
    final client = FXTwitterClient(
      client: MockClient((request) async {
        requested = request.url;
        return http.Response.bytes(
          utf8.encode(
            '{"code":200,"tweet":{"url":"https://x.com/oshi/status/42"}}',
          ),
          200,
        );
      }),
    );

    final metadata = await client.fetch(
      Uri.parse('https://twitter.com/oshi/status/42?s=20'),
    );

    expect(requested.toString(), 'https://api.fxtwitter.com/status/42');
    expect(metadata.canonicalUrl.toString(), 'https://x.com/oshi/status/42');
    expect(metadata.imageUrls, isEmpty);
  });
}
