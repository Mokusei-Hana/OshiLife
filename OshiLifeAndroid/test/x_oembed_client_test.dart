import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oshilife/import/x_oembed_client.dart';

// Port of OshiLifeTests/XOEmbedClientTests.swift.
void main() {
  test('extracts post paragraph and decodes HTML', () {
    const html =
        '<blockquote><p lang="ja">推し &amp; ライブ<br>最高！ <a href="https://t.co/x">pic.twitter.com/x</a></p>&mdash; Author</blockquote>';
    expect(XOEmbedClient.postText(html), '推し & ライブ\n最高！ pic.twitter.com/x');
  });

  test('missing paragraph is recoverable', () {
    expect(
      XOEmbedClient.postText('<blockquote>No paragraph</blockquote>'),
      isNull,
    );
  });

  test('extracts and deduplicates link targets', () {
    const html = '''
<p>
  <a href="https://heroines.jp/news/event?a=1&amp;b=2">詳細</a>
  <a href="https://heroines.jp/news/event?a=1&amp;b=2">同じ詳細</a>
  <a href="mailto:info@example.com">メール</a>
</p>
''';
    expect(
      XOEmbedClient.linkedUrls(html).map((url) => url.toString()).toList(),
      ['https://heroines.jp/news/event?a=1&b=2'],
    );
  });

  test('fetch decodes metadata and hits the oEmbed endpoint', () async {
    late Uri requested;
    final client = XOEmbedClient(
      client: MockClient((request) async {
        requested = request.url;
        return http.Response.bytes(
          utf8.encode(
            '{"url":"https://x.com/oshi/status/42","author_name":"推し",'
            '"author_url":"https://x.com/oshi",'
            '"html":"<blockquote><p>ライブ情報</p></blockquote>"}',
          ),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final metadata = await client.fetch(
      Uri.parse('https://x.com/oshi/status/42'),
    );

    expect(requested.host, 'publish.x.com');
    expect(requested.path, '/oembed');
    expect(requested.queryParameters['url'], 'https://x.com/oshi/status/42');
    expect(metadata.authorName, '推し');
    expect(metadata.postText, 'ライブ情報');
    expect(metadata.canonicalUrl.toString(), 'https://x.com/oshi/status/42');
  });

  test('fetch rejects HTTP error and oversized response', () async {
    var status = 503;
    var body = Uint8List(0);
    final client = XOEmbedClient(
      client: MockClient((request) async => http.Response.bytes(body, status)),
    );
    final postUrl = Uri.parse('https://x.com/oshi/status/42');

    await expectLater(
      client.fetch(postUrl),
      throwsA(
        isA<XOEmbedException>()
            .having((e) => e.kind, 'kind', XOEmbedErrorKind.httpStatus)
            .having((e) => e.statusCode, 'statusCode', 503),
      ),
    );

    status = 200;
    body = Uint8List(XOEmbedClient.maximumResponseBytes + 1);
    body.fillRange(0, body.length, 0x20);
    await expectLater(
      client.fetch(postUrl),
      throwsA(
        isA<XOEmbedException>().having(
          (e) => e.kind,
          'kind',
          XOEmbedErrorKind.responseTooLarge,
        ),
      ),
    );
  });

  test('fetch rejects invalid post URLs before any network', () async {
    final client = XOEmbedClient(
      client: MockClient((request) async => fail('network must not be hit')),
    );
    await expectLater(
      client.fetch(Uri.parse('https://example.com/oshi/status/42')),
      throwsA(
        isA<XOEmbedException>().having(
          (e) => e.kind,
          'kind',
          XOEmbedErrorKind.invalidUrl,
        ),
      ),
    );
  });
}
