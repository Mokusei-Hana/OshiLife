import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshilife/core/design/widgets/empty_state.dart';
import 'package:oshilife/core/utils/event_countdown_formatter.dart';
import 'package:oshilife/data/models/live_event.dart';
import 'package:oshilife/data/models/live_status.dart';
import 'package:oshilife/features/home/dashboard_view.dart';
import 'package:oshilife/features/home/event_carousel_card.dart';
import 'package:oshilife/features/home/event_list_row.dart';

import 'helpers/test_harness.dart';

void main() {
  testWidgets('empty home shows the empty state with an add action', (
    tester,
  ) async {
    await pumpApp(tester);

    final l10n = l10nOf(tester);
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text(l10n.listEmptyTitle), findsOneWidget);
    expect(find.text(l10n.liveCreateManually), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('card mode shows the hero carousel with the countdown', (
    tester,
  ) async {
    final upcoming = LiveEvent(
      artistName: 'chuLa',
      title: 'HEROINES FES',
      eventDate: testNow.add(const Duration(days: 2, hours: 5)),
      venue: 'Zepp DiverCity',
    );
    final attended = LiveEvent(
      artistName: 'iLiFE!',
      title: '過去のライブ',
      eventDate: testNow.subtract(const Duration(days: 30)),
      status: LiveStatus.attended,
    );
    await pumpApp(tester, seed: [upcoming, attended]);

    final l10n = l10nOf(tester);
    expect(find.byType(DashboardView), findsOneWidget);
    expect(find.byType(EventCarouselCard), findsOneWidget);
    expect(find.text('HEROINES FES'), findsOneWidget);
    expect(find.text(l10n.homeUpcoming), findsOneWidget);
    expect(
      find.text(
        EventCountdownFormatter.shortText(
          until: upcoming.eventDate,
          now: testNow,
        ),
      ),
      findsOneWidget,
    );

    // The attended shelf sits below the fold of the test viewport.
    await scrollTo(tester, find.text(l10n.homeAttended));
    expect(find.text(l10n.homeAttended), findsOneWidget);
    expect(find.byType(HistoricalEventCard), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('list mode renders rows with venue and countdown', (
    tester,
  ) async {
    final upcoming = LiveEvent(
      artistName: 'chuLa',
      title: 'ワンマンライブ',
      eventDate: testNow.add(const Duration(days: 1)),
      venue: 'Kanadevia Hall',
    );
    await pumpApp(
      tester,
      prefs: {'settings.homeDisplayStyle': 'list'},
      seed: [upcoming],
    );

    expect(find.byType(EventListRow), findsOneWidget);
    expect(find.text('ワンマンライブ'), findsOneWidget);
    expect(find.text('Kanadevia Hall'), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('status filter narrows the visible events', (tester) async {
    final planned = LiveEvent(
      artistName: 'A',
      title: '予定ライブ',
      eventDate: testNow.add(const Duration(days: 1)),
    );
    final cancelled = LiveEvent(
      artistName: 'B',
      title: '中止ライブ',
      eventDate: testNow.add(const Duration(days: 2)),
      status: LiveStatus.cancelled,
    );
    await pumpApp(
      tester,
      prefs: {'settings.homeDisplayStyle': 'list'},
      seed: [planned, cancelled],
    );

    expect(find.byType(EventListRow), findsNWidgets(2));

    final l10n = l10nOf(tester);
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.statusCancelled).last);
    await tester.pumpAndSettle();

    expect(find.byType(EventListRow), findsOneWidget);
    expect(find.text('中止ライブ'), findsOneWidget);

    await disposeApp(tester);
  });
}
