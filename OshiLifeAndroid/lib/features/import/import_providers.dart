import 'package:flutter_riverpod/flutter_riverpod.dart';
// ChangeNotifierProvider from the legacy surface, matching the app-wide
// pattern for ported iOS `@Observable` objects (see app/providers.dart).
import 'package:flutter_riverpod/legacy.dart';
import 'package:oshilife/app/providers.dart';
import 'package:oshilife/app/router.dart';
import 'package:oshilife/features/import/import_error_messages.dart';
import 'package:oshilife/features/import/share_receive_coordinator.dart';
import 'package:oshilife/import/x_import_draft_builder.dart';

/// The app-wide draft builder, with metadata failures wrapped in the
/// localized `share.metadata_warning` string exactly like the iOS builder.
/// Tests override this with stubbed network clients.
final importDraftBuilderProvider = Provider<XImportDraftBuilder>((ref) {
  final l10n = ref.watch(l10nProvider);
  return XImportDraftBuilder(
    metadataWarningFormatter: (error) =>
        l10n.shareMetadataWarning(describeImportError(l10n, error)),
  );
});

final shareReceiveCoordinatorProvider =
    ChangeNotifierProvider<ShareReceiveCoordinator>((ref) {
      return ShareReceiveCoordinator(
        store: ref.watch(liveStoreProvider),
        draftBuilder: () => ref.read(importDraftBuilderProvider),
        router: () => ref.read(routerProvider),
      );
    });
