import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:oshilife/data/db/live_store.dart';
import 'package:oshilife/features/import/import_editor_args.dart';
import 'package:oshilife/features/import/share_intent_service.dart';
import 'package:oshilife/import/models/pending_share_import.dart';
import 'package:oshilife/import/x_import_draft_builder.dart';
import 'package:oshilife/import/x_url_validator.dart';

/// The shared text contained no X post URL — rendered as the iOS
/// extension's `share.invalid_url` message.
class SharedTextHasNoPostUrl implements Exception {
  const SharedTextHasNoPostUrl();
}

/// Port of `PendingImportCoordinator` for the Android share model
/// (plan §7.2): `ACTION_SEND` lands in our own process, so the iOS
/// App-Group queue, staged files, and URL-scheme handoff collapse into a
/// direct flow — resolve the post URL, run the import behind a progress
/// screen, then open the import editor with the duplicate lookup done.
class ShareReceiveCoordinator extends ChangeNotifier {
  ShareReceiveCoordinator({
    required this._store,
    required this._draftBuilder,
    required this._router,
  });

  final LiveStore _store;

  // Lazy getters: the builder tracks the active language and the router
  // lives in its own provider — neither should recreate the coordinator.
  final XImportDraftBuilder Function() _draftBuilder;
  final GoRouter Function() _router;

  bool _isProcessing = false;
  Object? _shareError;

  /// True while a shared post is being imported (progress screen spinner).
  bool get isProcessing => _isProcessing;

  /// The failure that ended the last share flow, shown by the progress
  /// screen; reset when the next share arrives.
  Object? get shareError => _shareError;

  /// Manual flow (iOS `presentManual`): the manual import screen already
  /// built the draft — look up the duplicate and open the import editor.
  Future<void> presentManual(PendingShareImport draft) async {
    final duplicate = await _store.eventBySourceUrl(draft.sourceUrl.toString());
    _router().push(
      '/import/editor',
      extra: ImportEditorArgs(
        pending: draft,
        imageBytes: draft.imageBytes,
        duplicate: duplicate,
      ),
    );
  }

  /// Share-intent flow: the iOS `ShareViewController` pipeline running
  /// inside the app. Invalid text shows the error state on the progress
  /// screen; success swaps the progress screen for the import editor.
  Future<void> handleSharedPayload(SharedPayload payload) async {
    final router = _router();
    final postUrl = XUrlValidator.firstPostUrl(payload.text);
    if (postUrl == null) {
      _isProcessing = false;
      _shareError = const SharedTextHasNoPostUrl();
      notifyListeners();
      router.push('/import/receive');
      return;
    }

    _isProcessing = true;
    _shareError = null;
    notifyListeners();
    router.push('/import/receive');
    try {
      final draft = await _draftBuilder().makeDraft(postUrl);
      // A shared image beats downloaded media, like the iOS `stage(_:)`.
      final sharedImage = payload.imageBytes;
      final imageBytes = (sharedImage != null && sharedImage.isNotEmpty)
          ? sharedImage
          : draft.imageBytes;
      final duplicate = await _store.eventBySourceUrl(
        draft.sourceUrl.toString(),
      );
      _isProcessing = false;
      notifyListeners();
      router.pushReplacement(
        '/import/editor',
        extra: ImportEditorArgs(
          pending: draft,
          imageBytes: imageBytes,
          duplicate: duplicate,
        ),
      );
    } on Object catch (error) {
      _isProcessing = false;
      _shareError = error;
      notifyListeners();
    }
  }
}
