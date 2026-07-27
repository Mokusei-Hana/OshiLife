import 'package:flutter_test/flutter_test.dart';
import 'package:oshilife/core/utils/event_countdown_formatter.dart';

// Port of OshiLifeTests/EventCountdownFormatterTests.swift.
void main() {
  final now = DateTime.fromMillisecondsSinceEpoch(1800000000 * 1000);

  test('minutes only', () {
    expect(
      EventCountdownFormatter.shortText(
        until: now.add(const Duration(minutes: 45)),
        now: now,
      ),
      '45m',
    );
  });

  test('hours and minutes', () {
    expect(
      EventCountdownFormatter.shortText(
        until: now.add(const Duration(hours: 3, minutes: 12)),
        now: now,
      ),
      '3h 12m',
    );
  });

  test('days and hours', () {
    expect(
      EventCountdownFormatter.shortText(
        until: now.add(const Duration(days: 2, hours: 5, minutes: 59)),
        now: now,
      ),
      '2d 5h',
    );
  });

  test('past dates clamp to zero minutes', () {
    expect(
      EventCountdownFormatter.shortText(
        until: now.subtract(const Duration(hours: 1)),
        now: now,
      ),
      '0m',
    );
  });
}
