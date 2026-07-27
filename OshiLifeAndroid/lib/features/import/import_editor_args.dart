import 'dart:typed_data';

import 'package:oshilife/data/models/live_event.dart';
import 'package:oshilife/import/models/pending_share_import.dart';

/// Everything the import editor route needs — the iOS `ImportEditorHost`
/// init parameters, carried through the router as one value.
class ImportEditorArgs {
  const ImportEditorArgs({
    required this.pending,
    this.imageBytes,
    this.duplicate,
  });

  final PendingShareImport pending;

  /// Cover candidate: the shared image when one was attached, otherwise
  /// the media the draft builder downloaded (iOS `currentImageData`).
  final Uint8List? imageBytes;

  /// An already-saved event with the same source URL, if any — drives the
  /// duplicate banner.
  final LiveEvent? duplicate;
}
