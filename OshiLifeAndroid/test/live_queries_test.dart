import 'package:flutter_test/flutter_test.dart';
import 'package:oshilife/data/db/live_queries.dart';
import 'package:oshilife/data/models/live_event.dart';
import 'package:oshilife/data/models/live_status.dart';

// Port of OshiLifeTests/LiveListViewModelTests.swift.
void main() {
  final now = DateTime.fromMillisecondsSinceEpoch(1800000000 * 1000);

  test('upcoming events keeps future planned sorted ascending', () {
    final later = LiveEvent(
      artistName: 'A',
      title: 'Later',
      eventDate: now.add(const Duration(days: 2)),
    );
    final sooner = LiveEvent(
      artistName: 'A',
      title: 'Sooner',
      eventDate: now.add(const Duration(days: 1)),
    );
    final past = LiveEvent(
      artistName: 'A',
      title: 'Past',
      eventDate: now.subtract(const Duration(days: 1)),
    );
    final attended = LiveEvent(
      artistName: 'A',
      title: 'Attended',
      eventDate: now.add(const Duration(days: 1)),
      status: LiveStatus.attended,
    );
    final cancelled = LiveEvent(
      artistName: 'A',
      title: 'Cancelled',
      eventDate: now.add(const Duration(days: 1)),
      status: LiveStatus.cancelled,
    );

    final upcoming = upcomingEvents([
      later,
      sooner,
      past,
      attended,
      cancelled,
    ], now: now);

    expect(upcoming.map((event) => event.title).toList(), ['Sooner', 'Later']);
  });

  test('historical events keeps attended sorted descending', () {
    final older = LiveEvent(
      artistName: 'A',
      title: 'Older',
      eventDate: now.subtract(const Duration(days: 2)),
      status: LiveStatus.attended,
    );
    final newer = LiveEvent(
      artistName: 'A',
      title: 'Newer',
      eventDate: now.subtract(const Duration(days: 1)),
      status: LiveStatus.attended,
    );
    final planned = LiveEvent(
      artistName: 'A',
      title: 'Planned',
      eventDate: now.add(const Duration(days: 1)),
    );

    final history = historicalEvents([older, planned, newer]);

    expect(history.map((event) => event.title).toList(), ['Newer', 'Older']);
  });
}
