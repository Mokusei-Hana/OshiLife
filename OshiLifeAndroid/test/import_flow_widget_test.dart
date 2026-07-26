import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshilife/data/models/live_event.dart';
import 'package:oshilife/import/models/pending_share_import.dart';
import 'package:oshilife/import/x_import_draft_builder.dart';
import 'package:oshilife/import/x_oembed_client.dart';
import 'package:oshilife/import/x_url_validator.dart';
import 'package:oshilife/l10n/app_localizations.dart';

import 'helpers/test_harness.dart';

/// Offline draft builder: resolves instantly with a fixed author/post and,
/// optionally, a warning on the first call only (so retry can clear it).
class _StubDraftBuilder extends XImportDraftBuilder {
  _StubDraftBuilder({this.warnOnFirstCall = false});

  final bool warnOnFirstCall;
  int calls = 0;

  @override
  Future<PendingShareImport> makeDraft(Uri candidate) async {
    calls += 1;
    final normalized = XUrlValidator.normalizedPostUrl(candidate);
    if (normalized == null) throw const XOEmbedException.invalidUrl();
    return PendingShareImport(
      sourceUrl: normalized,
      authorName: '推し',
      postText: 'ライブ情報',
      warning: warnOnFirstCall && calls == 1 ? 'メタデータを取得できませんでした' : null,
    );
  }
}

/// Drives home → add menu → manual import → prefilled import editor.
Future<void> _openImportEditorManually(
  WidgetTester tester,
  AppLocalizations l10n,
) async {
  await tester.tap(
    find.descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.add)),
  );
  await tester.pumpAndSettle();
  // `.last`: the empty-state button carries the same label as the menu item.
  await tester.tap(find.text(l10n.manualImportTitle).last);
  await tester.pumpAndSettle();

  await tester.enterText(
    find.byKey(const Key('manualImportUrlField')),
    'https://x.com/oshi/status/42',
  );
  await tester.pump();
  await tester.tap(find.byKey(const Key('manualXImportButton')));
  await tester.pumpAndSettle();
}

void main() {
  const shareChannel = MethodChannel('oshilife/share');

  testWidgets('manual import opens a prefilled editor and confirms discard', (
    tester,
  ) async {
    await pumpApp(tester, draftBuilder: _StubDraftBuilder());
    final l10n = l10nOf(tester);

    await _openImportEditorManually(tester, l10n);

    expect(find.text(l10n.editorNewTitle), findsOneWidget);
    final artistField = tester.widget<TextField>(
      find.byKey(const Key('editorArtistField')),
    );
    expect(artistField.controller!.text, '推し');

    // System back is intercepted by the PopScope, like the iOS
    // non-dismissible sheet, and asks before discarding.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(l10n.importDiscardTitle), findsOneWidget);
    await tester.tap(find.text(l10n.commonContinueEditing));
    await tester.pumpAndSettle();
    expect(find.text(l10n.editorNewTitle), findsOneWidget);

    // The close button goes through the same confirmation; discarding
    // returns home.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.importDiscardAction));
    await tester.pumpAndSettle();
    expect(find.text(l10n.listEmptyTitle), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('import editor surfaces the saved duplicate and can open it', (
    tester,
  ) async {
    final saved = LiveEvent(
      artistName: 'chuLa',
      title: 'HEROINES FES',
      eventDate: testNow.add(const Duration(days: 3)),
      sourceUrlString: 'https://x.com/oshi/status/42',
    );
    await pumpApp(
      tester,
      prefs: {'settings.homeDisplayStyle': 'list'},
      seed: [saved],
      draftBuilder: _StubDraftBuilder(),
    );
    final l10n = l10nOf(tester);

    await _openImportEditorManually(tester, l10n);

    expect(find.text(l10n.importDuplicateTitle), findsOneWidget);
    expect(find.textContaining('HEROINES FES'), findsOneWidget);

    // Opening the duplicate swaps the import editor for the detail screen.
    await tester.tap(find.text(l10n.importDuplicateOpen));
    await tester.pumpAndSettle();
    expect(find.text(l10n.editorNewTitle), findsNothing);
    expect(find.byTooltip(l10n.commonDelete), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('import warning banner retries and clears', (tester) async {
    final builder = _StubDraftBuilder(warnOnFirstCall: true);
    await pumpApp(tester, draftBuilder: builder);
    final l10n = l10nOf(tester);

    await _openImportEditorManually(tester, l10n);

    expect(find.text('メタデータを取得できませんでした'), findsOneWidget);
    await tester.tap(find.text(l10n.importRetry));
    await tester.pumpAndSettle();

    expect(builder.calls, 2);
    expect(find.text('メタデータを取得できませんでした'), findsNothing);
    expect(find.text(l10n.importRetry), findsNothing);

    await disposeApp(tester);
  });

  testWidgets('a cold-start share intent lands in the import editor', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      shareChannel,
      (call) async => call.method == 'consumeInitialShare'
          ? {'text': 'チケット情報 https://x.com/oshi/status/42 です', 'image': null}
          : null,
    );

    await pumpApp(
      tester,
      draftBuilder: _StubDraftBuilder(),
      withShareBootstrap: true,
    );
    await tester.pumpAndSettle();
    final l10n = l10nOf(tester);

    expect(find.text(l10n.shareProcessing), findsNothing);
    expect(find.text(l10n.editorNewTitle), findsOneWidget);
    final artistField = tester.widget<TextField>(
      find.byKey(const Key('editorArtistField')),
    );
    expect(artistField.controller!.text, '推し');

    await disposeApp(tester);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      shareChannel,
      null,
    );
  });

  testWidgets('shared text without an X URL shows the invalid-share screen', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      shareChannel,
      (call) async => call.method == 'consumeInitialShare'
          ? {'text': '今日のライブ最高でした', 'image': null}
          : null,
    );

    await pumpApp(tester, withShareBootstrap: true);
    await tester.pumpAndSettle();
    final l10n = l10nOf(tester);

    expect(find.text(l10n.shareTitle), findsOneWidget);
    expect(find.text(l10n.shareInvalidUrl), findsOneWidget);

    await tester.tap(find.text(l10n.commonClose));
    await tester.pumpAndSettle();
    expect(find.text(l10n.listEmptyTitle), findsOneWidget);

    await disposeApp(tester);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      shareChannel,
      null,
    );
  });
}
