import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshilife/app/app.dart';
import 'package:oshilife/app/providers.dart';
import 'package:oshilife/data/db/database.dart';
import 'package:oshilife/data/db/live_store.dart';
import 'package:oshilife/data/images/image_store.dart';
import 'package:oshilife/data/models/live_event.dart';
import 'package:oshilife/features/home/home_providers.dart';
import 'package:oshilife/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fixed "now" used by all widget tests (2027-01-15T08:00Z).
final DateTime testNow = DateTime.fromMillisecondsSinceEpoch(1800000000 * 1000);

/// Pumps the full app (theme, l10n, router) against an in-memory database
/// and mocked preferences. The 60 s clock is overridden with a single
/// fixed value so tests are deterministic and free of pending timers.
Future<void> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  List<LiveEvent> seed = const [],
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sharedPrefs = await SharedPreferences.getInstance();
  final database = OshiLifeDatabase(NativeDatabase.memory());
  final store = LiveStore(database);
  for (final event in seed) {
    await store.insertEvent(event);
  }
  final imageRoot = Directory.systemTemp.createTempSync('oshilife-ui-test-');
  addTearDown(() async {
    if (imageRoot.existsSync()) {
      imageRoot.deleteSync(recursive: true);
    }
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        databaseProvider.overrideWith((ref) {
          ref.onDispose(database.close);
          return database;
        }),
        imageStoreProvider.overrideWith(
          (ref) async => ImageStore(root: imageRoot),
        ),
        clockProvider.overrideWith((ref) => Stream<DateTime>.value(testNow)),
      ],
      child: const OshiLifeApp(),
    ),
  );
  // Let the streams (events, clock, image store) deliver.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

/// Resolves the generated localizations from the running widget tree.
AppLocalizations l10nOf(WidgetTester tester) {
  return AppLocalizations.of(tester.element(find.byType(Scaffold).first));
}

/// Call at the end of every widget test that used [pumpApp]: unmounts the
/// tree and flushes the zero-duration cleanup Timer that drift schedules
/// (`StreamQueryStore.markAsClosed` → `Timer.run`) when its query streams
/// unsubscribe during disposal — otherwise the binding's pending-timer
/// invariant fails. The pump needs a non-null duration: only an elapsing
/// pump fires due timers under FakeAsync. (package:test tearDowns run
/// after that invariant, so this must happen inside the test body.)
Future<void> disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 20));
}

/// Scrolls the first (outermost) scrollable until [finder] is visible —
/// needed because lazily-built ListView children below the test viewport
/// don't exist until scrolled into view. Negative [delta] scrolls back up.
Future<void> scrollTo(
  WidgetTester tester,
  Finder finder, {
  double delta = 200,
}) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}
