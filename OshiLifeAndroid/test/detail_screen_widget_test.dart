import 'package:flutter_test/flutter_test.dart';
import 'package:oshilife/data/models/live_event.dart';
import 'package:oshilife/data/models/ticket_option.dart';
import 'package:oshilife/features/home/event_list_row.dart';

import 'helpers/test_harness.dart';

void main() {
  testWidgets('detail shows information, performers, tickets, and notes', (
    tester,
  ) async {
    final selected = TicketOption(name: 'Sチケット', price: 9000);
    final event = LiveEvent(
      artistName: 'chuLa',
      title: 'HEROINES FES',
      eventDate: testNow.add(const Duration(days: 3)),
      openTime: testNow.add(const Duration(days: 3, hours: 4)),
      startTime: testNow.add(const Duration(days: 3, hours: 5)),
      venue: 'Zepp DiverCity',
      address: '東京都江東区青海1-1-10',
      performers: ['chuLa', 'TENRIN'],
      ticketOptions: [
        selected,
        TicketOption(name: 'Aチケット', price: 4000),
      ],
      selectedTicketId: selected.id,
      ticketUrlString: 'https://eplus.jp/sf/detail/123',
      sourceUrlString: 'https://x.com/oshi/status/42',
      notes: '物販は開場前から。',
    );
    await pumpApp(
      tester,
      prefs: {'settings.homeDisplayStyle': 'list'},
      seed: [event],
    );

    await tester.tap(find.byType(EventListRow));
    await tester.pumpAndSettle();

    final l10n = l10nOf(tester);
    // Sections below the hero cover are lazily built — scroll to each.
    await scrollTo(tester, find.text('HEROINES FES'));
    expect(find.text('HEROINES FES'), findsOneWidget);
    await scrollTo(tester, find.text(l10n.detailInformation));
    await scrollTo(tester, find.text('Zepp DiverCity'));
    expect(find.text('Zepp DiverCity'), findsOneWidget);
    await scrollTo(tester, find.text('chuLa / TENRIN'));
    expect(find.text('chuLa / TENRIN'), findsOneWidget);
    await scrollTo(tester, find.text('Sチケット'));
    expect(find.text('¥9,000'), findsOneWidget);
    // A selected ticket routes the action to the platform "my tickets"
    // page label.
    await scrollTo(tester, find.text(l10n.ticketOpenPurchased));
    expect(find.text(l10n.ticketOpenPurchased), findsOneWidget);
    await scrollTo(tester, find.text('物販は開場前から。'));
    expect(find.text('物販は開場前から。'), findsOneWidget);
    await scrollTo(tester, find.text(l10n.detailLinks));
    expect(find.text(l10n.detailLinks), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('delete confirmation removes the event and pops home', (
    tester,
  ) async {
    final event = LiveEvent(
      artistName: 'chuLa',
      title: '削除するライブ',
      eventDate: testNow.add(const Duration(days: 1)),
    );
    await pumpApp(
      tester,
      prefs: {'settings.homeDisplayStyle': 'list'},
      seed: [event],
    );

    await tester.tap(find.byType(EventListRow));
    await tester.pumpAndSettle();

    final l10n = l10nOf(tester);
    await tester.tap(find.byTooltip(l10n.commonDelete));
    await tester.pumpAndSettle();
    expect(find.text(l10n.deleteTitle), findsOneWidget);

    await tester.tap(find.text(l10n.commonDelete).last);
    await tester.pumpAndSettle();

    // Back on home with the event gone.
    expect(find.text(l10n.listEmptyTitle), findsOneWidget);

    await disposeApp(tester);
  });
}
