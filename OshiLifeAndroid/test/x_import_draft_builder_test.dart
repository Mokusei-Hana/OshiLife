import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:oshilife/import/event_link_importer.dart';
import 'package:oshilife/import/fx_twitter_client.dart';
import 'package:oshilife/import/models/event_import_details.dart';
import 'package:oshilife/import/remote_image_data_client.dart';
import 'package:oshilife/import/x_import_draft_builder.dart';
import 'package:oshilife/import/x_oembed_client.dart';

// Port of OshiLifeTests/XImportDraftBuilderTests.swift.

class _StubOEmbedClient implements XOEmbedFetching {
  _StubOEmbedClient(this.metadata);

  final XOEmbedMetadata? metadata;

  @override
  Future<XOEmbedMetadata> fetch(Uri postUrl) async {
    final value = metadata;
    if (value == null) throw Exception('not connected to internet');
    return value;
  }
}

class _StubEventLinkImporter implements EventLinkImporting {
  _StubEventLinkImporter(this.details);

  final EventImportDetails? details;

  @override
  Future<EventImportDetails?> importDetails(List<Uri> urls) async => details;
}

class _StubFXTwitterClient implements FXTwitterFetching {
  _StubFXTwitterClient(this.imageUrls);

  final List<Uri> imageUrls;

  @override
  Future<FXTwitterMetadata> fetch(Uri postUrl) async {
    return FXTwitterMetadata(canonicalUrl: postUrl, imageUrls: imageUrls);
  }
}

class _StubImageDownloader implements RemoteImageDataFetching {
  _StubImageDownloader({
    this.dataByUrl = const {},
    this.failingUrls = const {},
  });

  final Map<Uri, Uint8List> dataByUrl;
  final Set<Uri> failingUrls;

  @override
  Future<Uint8List> fetchImage(Uri url) async {
    if (failingUrls.contains(url)) throw Exception('cannot load from network');
    final data = dataByUrl[url];
    if (data == null) throw Exception('file does not exist');
    return data;
  }
}

XImportDraftBuilder builder({
  required XOEmbedFetching client,
  EventLinkImporting? eventLinkImporter,
  List<Uri> imageUrls = const [],
  Map<Uri, Uint8List> imageData = const {},
  Set<Uri> failingImageUrls = const {},
}) {
  return XImportDraftBuilder(
    client: client,
    eventLinkImporter: eventLinkImporter ?? _StubEventLinkImporter(null),
    fxTwitterClient: _StubFXTwitterClient(imageUrls),
    imageDownloader: _StubImageDownloader(
      dataByUrl: imageData,
      failingUrls: failingImageUrls,
    ),
  );
}

void main() {
  test('builds draft from oEmbed metadata', () async {
    final canonicalUrl = Uri.parse('https://x.com/oshi/status/42');
    final metadata = XOEmbedMetadata(
      canonicalUrl: canonicalUrl,
      authorName: '推し',
      postText: 'ライブ情報',
    );

    final draft = await builder(
      client: _StubOEmbedClient(metadata),
    ).makeDraft(Uri.parse('https://twitter.com/oshi/status/42?s=20'));

    expect(draft.sourceUrl, canonicalUrl);
    expect(draft.authorName, '推し');
    expect(draft.postText, 'ライブ情報');
    expect(draft.warning, isNull);
  });

  test('adds parsed event details to editable draft', () async {
    final canonicalUrl = Uri.parse('https://x.com/oshi/status/42');
    final eventUrl = Uri.parse('https://heroines.jp/news/event');
    final date = DateTime.fromMillisecondsSinceEpoch(1800000000 * 1000);
    final metadata = XOEmbedMetadata(
      canonicalUrl: canonicalUrl,
      authorName: '推し',
      postText: 'ライブ情報',
      linkedUrls: [eventUrl],
    );
    final details = EventImportDetails(
      title: 'HEROINES FES',
      date: date,
      venue: 'Spotify O-EAST',
      performers: ['iLiFE!', 'のんふぃく！'],
      linkedUrl: eventUrl,
    );

    final draft = await builder(
      client: _StubOEmbedClient(metadata),
      eventLinkImporter: _StubEventLinkImporter(details),
    ).makeDraft(canonicalUrl);

    expect(draft.eventDetails, details);
    expect(draft.postText, 'ライブ情報');
  });

  test('builds editable draft when metadata fetch fails', () async {
    final draft = await builder(
      client: _StubOEmbedClient(null),
    ).makeDraft(Uri.parse('https://x.com/oshi/status/42'));

    expect(draft.sourceUrl.toString(), 'https://x.com/oshi/status/42');
    expect(draft.warning, isNotNull);
  });

  test('rejects invalid URL before fetching', () async {
    await expectLater(
      builder(
        client: _StubOEmbedClient(null),
      ).makeDraft(Uri.parse('https://example.com/oshi/status/42')),
      throwsA(
        isA<XOEmbedException>().having(
          (e) => e.kind,
          'kind',
          XOEmbedErrorKind.invalidUrl,
        ),
      ),
    );
  });

  test('downloads first available tweet image', () async {
    final first = Uri.parse('https://pbs.twimg.com/media/first.jpg');
    final second = Uri.parse('https://pbs.twimg.com/media/second.jpg');
    final metadata = XOEmbedMetadata(
      canonicalUrl: Uri.parse('https://x.com/oshi/status/42'),
      authorName: '推し',
      postText: 'ライブ情報',
    );

    final draft = await builder(
      client: _StubOEmbedClient(metadata),
      imageUrls: [first, second],
      imageData: {
        second: Uint8List.fromList([0xFF, 0xD8, 0xFF]),
      },
      failingImageUrls: {first},
    ).makeDraft(metadata.canonicalUrl);

    expect(draft.imageBytes, [0xFF, 0xD8, 0xFF]);
  });

  test('import without tweet images keeps current behavior', () async {
    final metadata = XOEmbedMetadata(
      canonicalUrl: Uri.parse('https://x.com/oshi/status/42'),
      authorName: '推し',
      postText: 'ライブ情報',
    );

    final draft = await builder(
      client: _StubOEmbedClient(metadata),
    ).makeDraft(metadata.canonicalUrl);

    expect(draft.imageBytes, isNull);
    expect(draft.warning, isNull);
  });

  test('warning formatter receives the metadata error', () async {
    final draft = await XImportDraftBuilder(
      client: _StubOEmbedClient(null),
      eventLinkImporter: _StubEventLinkImporter(null),
      fxTwitterClient: _StubFXTwitterClient(const []),
      imageDownloader: _StubImageDownloader(),
      metadataWarningFormatter: (error) => 'wrapped: $error',
    ).makeDraft(Uri.parse('https://x.com/oshi/status/42'));

    expect(draft.warning, startsWith('wrapped: '));
  });
}
