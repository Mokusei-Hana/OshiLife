import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:oshilife/features/import/manual_import_view_model.dart';
import 'package:oshilife/import/event_link_importer.dart';
import 'package:oshilife/import/fx_twitter_client.dart';
import 'package:oshilife/import/models/event_import_details.dart';
import 'package:oshilife/import/remote_image_data_client.dart';
import 'package:oshilife/import/x_import_draft_builder.dart';
import 'package:oshilife/import/x_oembed_client.dart';

// Port of OshiLifeTests/ManualXImportViewModelTests.swift. The builder's
// side clients are stubbed offline so no test touches the network.

class _StubOEmbedClient implements XOEmbedFetching {
  @override
  Future<XOEmbedMetadata> fetch(Uri postUrl) async {
    return XOEmbedMetadata(
      canonicalUrl: postUrl,
      authorName: '推し',
      postText: 'ライブ情報',
    );
  }
}

class _NullEventLinkImporter implements EventLinkImporting {
  @override
  Future<EventImportDetails?> importDetails(List<Uri> urls) async => null;
}

class _OfflineFXTwitterClient implements FXTwitterFetching {
  @override
  Future<FXTwitterMetadata> fetch(Uri postUrl) async {
    throw Exception('offline');
  }
}

class _OfflineImageDownloader implements RemoteImageDataFetching {
  @override
  Future<Uint8List> fetchImage(Uri url) async => throw Exception('offline');
}

XImportDraftBuilder _stubBuilder() {
  return XImportDraftBuilder(
    client: _StubOEmbedClient(),
    eventLinkImporter: _NullEventLinkImporter(),
    fxTwitterClient: _OfflineFXTwitterClient(),
    imageDownloader: _OfflineImageDownloader(),
  );
}

void main() {
  test('clipboard is checked only once and the suggestion can be used', () {
    final viewModel = ManualImportViewModel(draftBuilder: _stubBuilder());
    viewModel.checkClipboard('https://twitter.com/first/status/1?s=20');
    viewModel.checkClipboard('https://x.com/second/status/2');

    expect(
      viewModel.clipboardSuggestion.toString(),
      'https://x.com/first/status/1',
    );

    viewModel.useClipboardSuggestion();
    expect(viewModel.urlText.text, 'https://x.com/first/status/1');
    expect(viewModel.clipboardSuggestion, isNull);
    viewModel.dispose();
  });

  test('imports the normalized URL into a draft', () async {
    final viewModel = ManualImportViewModel(draftBuilder: _stubBuilder());
    viewModel.urlText.text = ' https://mobile.twitter.com/oshi/status/42?s=20 ';

    final draft = await viewModel.importDraft();

    expect(draft, isNotNull);
    expect(draft!.sourceUrl.toString(), 'https://x.com/oshi/status/42');
    expect(draft.authorName, '推し');
    expect(viewModel.errorMessage, isNull);
    viewModel.dispose();
  });

  test('an invalid URL shows an error and does not import', () async {
    final viewModel = ManualImportViewModel(draftBuilder: _stubBuilder());
    viewModel.urlText.text = 'https://example.com/not-x';

    final draft = await viewModel.importDraft();

    expect(draft, isNull);
    expect(viewModel.errorMessage, isNotNull);
    viewModel.dispose();
  });

  test('editing the URL clears the error (iOS onChange rule)', () async {
    final viewModel = ManualImportViewModel(draftBuilder: _stubBuilder());
    viewModel.urlText.text = 'https://example.com/not-x';
    await viewModel.importDraft();
    expect(viewModel.errorMessage, isNotNull);

    viewModel.urlText.text = 'https://x.com/oshi/status/42';

    expect(viewModel.errorMessage, isNull);
    viewModel.dispose();
  });
}
