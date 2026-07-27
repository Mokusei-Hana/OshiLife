import 'package:oshilife/import/event_link_importer.dart';
import 'package:oshilife/import/fx_twitter_client.dart';
import 'package:oshilife/import/models/pending_share_import.dart';
import 'package:oshilife/import/remote_image_data_client.dart';
import 'package:oshilife/import/x_oembed_client.dart';
import 'package:oshilife/import/x_url_validator.dart';

/// Port of `Shared/Import/XImportDraftBuilder.swift`.
///
/// Ordering contract (pinned by the ported tests):
/// 1. Validate/normalize the URL — invalid throws before any network.
/// 2. oEmbed metadata + event-link details; ANY failure in this block puts
///    a warning on the draft and leaves it editable.
/// 3. FxTwitter media: first downloadable image wins; per-image failures
///    continue; whole-block failure is silent (no warning).
///
/// iOS composes the warning as the localized `share.metadata_warning %@`
/// string. The import layer stays Flutter-free, so the localized wrapping
/// is injected via [metadataWarningFormatter] by the UI layer; the default
/// carries the error description.
class XImportDraftBuilder {
  XImportDraftBuilder({
    XOEmbedFetching? client,
    EventLinkImporting? eventLinkImporter,
    FXTwitterFetching? fxTwitterClient,
    RemoteImageDataFetching? imageDownloader,
    String Function(Object error)? metadataWarningFormatter,
  }) : _client = client ?? XOEmbedClient(),
       _eventLinkImporter = eventLinkImporter ?? EventLinkImporter(),
       _fxTwitterClient = fxTwitterClient ?? FXTwitterClient(),
       _imageDownloader = imageDownloader ?? RemoteImageDataClient(),
       _metadataWarningFormatter = metadataWarningFormatter ?? _describeError;

  final XOEmbedFetching _client;
  final EventLinkImporting _eventLinkImporter;
  final FXTwitterFetching _fxTwitterClient;
  final RemoteImageDataFetching _imageDownloader;
  final String Function(Object error) _metadataWarningFormatter;

  Future<PendingShareImport> makeDraft(Uri candidate) async {
    final normalized = XUrlValidator.normalizedPostUrl(candidate);
    if (normalized == null) throw const XOEmbedException.invalidUrl();

    final draft = PendingShareImport(sourceUrl: normalized);
    try {
      final metadata = await _client.fetch(normalized);
      draft.sourceUrl = metadata.canonicalUrl;
      draft.authorName = metadata.authorName;
      draft.postText = metadata.postText;
      final contentUrls = [
        ...metadata.linkedUrls,
        ...EventLinkImporter.urls(metadata.postText ?? ''),
      ];
      final details = await _eventLinkImporter.importDetails(contentUrls);
      if (details != null) {
        draft.eventDetails = details;
      }
    } on Object catch (error) {
      draft.warning = _metadataWarningFormatter(error);
    }

    // FxTwitter is only an optional media source. Metadata or image
    // failures must leave the editable oEmbed draft usable.
    try {
      final media = await _fxTwitterClient.fetch(normalized);
      for (final imageUrl in media.imageUrls) {
        try {
          final data = await _imageDownloader.fetchImage(imageUrl);
          if (data.isNotEmpty) {
            draft.imageBytes = data;
            break;
          }
        } on Object {
          continue;
        }
      }
    } on Object {
      // The current import behavior does not depend on media availability.
    }
    return draft;
  }

  static String _describeError(Object error) {
    if (error is FXTwitterException) return error.message;
    return error.toString();
  }
}
