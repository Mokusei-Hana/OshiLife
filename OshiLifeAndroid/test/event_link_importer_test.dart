import 'dart:convert';

import 'package:charset/charset.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oshilife/import/event_link_importer.dart';
import 'package:oshilife/import/heroines_event_page_parser.dart';
import 'package:oshilife/import/models/event_import_details.dart';

/// Wall-clock instant in Asia/Tokyo (fixed +09:00) as a UTC DateTime —
/// mirrors the iOS tests' JST calendar-component assertions.
DateTime jst(int year, int month, int day, [int hour = 0, int minute = 0]) {
  return DateTime.utc(
    year,
    month,
    day,
    hour,
    minute,
  ).subtract(const Duration(hours: 9));
}

// Port of OshiLifeTests/EventLinkImporterTests.swift. Fixture HTML is
// verbatim from the Swift tests.
void main() {
  const parser = HeroinesEventPageParser();

  test('parses heroines event page', () {
    const html = '''
<html><body>
<h1>5月開催「HEROINES LEAGUEⅠ」公演概要とチケット販売に関するご案内</h1>
<time>2026.04.30</time>
<div>【公演概要】<br>
2026年5月20日(水)<br>
「HEROINES LEAGUEⅠ」<br>
@ Kanadevia Hall<br>
OPEN 13:30 / START 14:30<br>
出演：chuLa / TENRIN / iLiFE!<br>
▼チケット情報<br>
Sチケット ￥9,000<br>
Aチケット ￥4,000</div>
</body></html>
''';
    final sourceUrl = Uri.parse('https://heroines.jp/news/public/_/event.html');

    final details = parser.parse(html: html, sourceUrl: sourceUrl);

    expect(details, isNotNull);
    expect(details!.title, '「HEROINES LEAGUEⅠ」');
    expect(details.venue, 'Kanadevia Hall');
    expect(details.performers, ['chuLa', 'TENRIN', 'iLiFE!']);
    expect(details.ticketOptions.map((o) => o.name).toList(), [
      'Sチケット',
      'Aチケット',
    ]);
    expect(details.ticketOptions.map((o) => o.price).toList(), [9000, 4000]);
    expect(details.ticketInformation, contains('￥9,000'));
    expect(details.linkedUrl, sourceUrl);
    expect(details.date, jst(2026, 5, 20));
    expect(details.openTime, jst(2026, 5, 20, 13, 30));
    expect(details.startTime, jst(2026, 5, 20, 14, 30));
  });

  test('parses ticket descriptions and does not use publication date', () {
    final sourceUrl = Uri.parse('https://heroines.jp/news/event-with-tickets');
    const html = '''
<h1>掲載 2026.01.01 「春公演」</h1>
<div>【公演概要】<br>
2026年3月8日(日)<br>
「春公演」<br>
@ Zepp DiverCity<br>
OPEN 16:00 / START 17:00<br>
出演：A / B<br>
▼チケット情報<br>
Sチケット ¥9,000 前方エリア<br>
1Fチケット ¥4,000<br>
2Fチケット ¥3,500</div>
''';

    final details = parser.parse(html: html, sourceUrl: sourceUrl);

    expect(details, isNotNull);
    expect(details!.date, jst(2026, 3, 8));
    expect(details.ticketOptions[0].description, '前方エリア');
    expect(details.ticketOptions.map((o) => o.price).toList(), [
      9000,
      4000,
      3500,
    ]);
  });

  test('parses all ticket rows without ticket section header', () {
    final sourceUrl = Uri.parse(
      'https://heroines.jp/news/event-without-ticket-header',
    );
    const html = '''
<div>【公演概要】<br>
2026年5月20日(水)<br>
「HEROINES LEAGUEⅠ」<br>
@ Kanadevia Hall<br>
OPEN 13:30 / START 14:30<br>
出演：chuLa / TENRIN / iLiFE!<br>
Sチケット ￥9,000 (税込) ※スタンディング・前方エリア<br>
1Fチケット ¥4,000 (税込) ※スタンディング・後方エリア<br>
2Fチケット ￥3,500 (税込) ※2F・自由席</div>
''';

    final details = parser.parse(html: html, sourceUrl: sourceUrl);

    expect(details, isNotNull);
    expect(details!.ticketOptions.map((o) => o.name).toList(), [
      'Sチケット',
      '1Fチケット',
      '2Fチケット',
    ]);
    expect(details.ticketOptions.map((o) => o.price).toList(), [
      9000,
      4000,
      3500,
    ]);
    expect(details.ticketOptions.map((o) => o.description).toList(), [
      '(税込) ※スタンディング・前方エリア',
      '(税込) ※スタンディング・後方エリア',
      '(税込) ※2F・自由席',
    ]);
  });

  test('rejects non-event heroines page without guessing', () {
    final sourceUrl = Uri.parse('https://heroines.jp/faq');
    const html = '<html><body><h1>よくある質問</h1><p>会員登録について</p></body></html>';

    expect(parser.parse(html: html, sourceUrl: sourceUrl), isNull);
  });

  test('parses title placed before date', () {
    final sourceUrl = Uri.parse('https://heroines.jp/news/older-event');
    const html = '''
<h1>先行受付開始</h1>
<div>【公演概要】<br>
HEROINES FES 〜6周年記念LIVE〜<br>
2025年5月5日（月・祝）<br>
@ Spotify O-EAST<br>
open 11:30 / start 12:00<br>
前方チケット ¥10,000</div>
''';

    final details = parser.parse(html: html, sourceUrl: sourceUrl);

    expect(details, isNotNull);
    expect(details!.title, 'HEROINES FES 〜6周年記念LIVE〜');
    expect(details.venue, 'Spotify O-EAST');
  });

  test('extracts unique web links from tweet text', () {
    final urls = EventLinkImporter.urls(
      '詳細 https://heroines.jp/news/1 と https://example.com/tickets',
    );

    expect(urls.map((url) => url.toString()).toList(), [
      'https://heroines.jp/news/1',
      'https://example.com/tickets',
    ]);
  });

  test('unsupported website is kept as link without guessed fields', () async {
    final link = Uri.parse('https://example.com/tickets/42');
    final importer = EventLinkImporter(
      client: MockClient((request) async => fail('network must not be hit')),
    );

    final details = await importer.importDetails([link]);

    expect(details, isNotNull);
    expect(details!.linkedUrl, link);
    expect(details.title, isNull);
    expect(details.date, isNull);
    expect(details.venue, isNull);
    expect(details.startTime, isNull);
    expect(details.performers, isEmpty);
  });

  test('event details decodes payloads created before ticket options', () {
    final json =
        jsonDecode(
              '{"linkedURL":"https://heroines.jp/news/event",'
              '"performers":["A"],"title":"旧イベント"}',
            )
            as Map<String, dynamic>;

    final details = EventImportDetails.fromJson(json);

    expect(details.linkedUrl, Uri.parse('https://heroines.jp/news/event'));
    expect(details.title, '旧イベント');
    expect(details.performers, ['A']);
    expect(details.ticketOptions, isEmpty);
  });

  // Dart-specific coverage of behaviors iOS exercises implicitly.

  test('fetches and parses a supported link with the Accept header', () async {
    const html = '''
<div>【公演概要】<br>
2026年5月20日(水)<br>
「HEROINES LEAGUEⅠ」<br>
@ Kanadevia Hall</div>
''';
    late http.Request captured;
    final importer = EventLinkImporter(
      client: MockClient((request) async {
        captured = request;
        return http.Response.bytes(utf8.encode(html), 200);
      }),
    );

    final details = await importer.importDetails([
      Uri.parse('https://heroines.jp/news/event'),
    ]);

    expect(captured.headers['Accept'], 'text/html,application/xhtml+xml');
    expect(details!.title, '「HEROINES LEAGUEⅠ」');
    expect(details.venue, 'Kanadevia Hall');
  });

  test('decodes EUC-JP pages when UTF-8 fails', () async {
    // Fixture avoids characters outside the EUC-JP (JIS X 0208) repertoire
    // (e.g. the Roman numeral Ⅰ used in the UTF-8 fixtures) — a page that
    // is actually served as EUC-JP cannot contain them either.
    const html = '''
<div>【公演概要】<br>
2026年5月20日(水)<br>
「ヒロインズ 春の陣」<br>
@ Kanadevia Hall</div>
''';
    final importer = EventLinkImporter(
      client: MockClient(
        (request) async => http.Response.bytes(eucJp.encode(html), 200),
      ),
    );

    final details = await importer.importDetails([
      Uri.parse('https://heroines.jp/news/euc-event'),
    ]);

    expect(details!.title, '「ヒロインズ 春の陣」');
    expect(details.venue, 'Kanadevia Hall');
  });

  test('resolves t.co short links and parses the destination', () async {
    const html = '''
<div>【公演概要】<br>
2026年5月20日(水)<br>
「HEROINES LEAGUEⅠ」<br>
@ Kanadevia Hall</div>
''';
    final importer = EventLinkImporter(
      client: MockClient((request) async {
        if (request.url.host == 't.co') {
          return http.Response(
            '',
            301,
            headers: {'location': 'https://heroines.jp/news/event'},
          );
        }
        expect(request.url.toString(), 'https://heroines.jp/news/event');
        return http.Response.bytes(utf8.encode(html), 200);
      }),
    );

    final details = await importer.importDetails([
      Uri.parse('https://t.co/abc123'),
    ]);

    expect(details!.linkedUrl, Uri.parse('https://heroines.jp/news/event'));
    expect(details.title, '「HEROINES LEAGUEⅠ」');
  });

  test('network failure degrades to the bare link', () async {
    final importer = EventLinkImporter(
      client: MockClient(
        (request) async => throw http.ClientException('offline'),
      ),
    );

    final details = await importer.importDetails([
      Uri.parse('https://heroines.jp/news/event'),
    ]);

    expect(details!.linkedUrl, Uri.parse('https://heroines.jp/news/event'));
    expect(details.title, isNull);
    expect(details.date, isNull);
  });

  test('excludes X hosts and deduplicates before importing', () async {
    final importer = EventLinkImporter(
      client: MockClient((request) async => fail('network must not be hit')),
    );

    final details = await importer.importDetails([
      Uri.parse('https://x.com/oshi/status/42'),
      Uri.parse('https://www.twitter.com/oshi/status/42'),
      Uri.parse('mailto:info@example.com'),
      Uri.parse('https://example.com/tickets'),
      Uri.parse('https://example.com/tickets'),
    ]);

    expect(details!.linkedUrl, Uri.parse('https://example.com/tickets'));
  });
}
