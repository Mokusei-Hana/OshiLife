import 'package:oshilife/data/models/live_event.dart';
import 'package:oshilife/data/models/live_status.dart';

/// Port of the static query helpers on
/// `OshiLife/Features/Home/LiveListViewModel.swift`.
///
/// Note the deliberate iOS inconsistency that is preserved here: these use
/// `now` directly, while the list sort (`LiveStore.sortedForList`) pivots
/// on `startOfDay(now)`.
List<LiveEvent> upcomingEvents(
  List<LiveEvent> events, {
  required DateTime now,
}) {
  final upcoming = events
      .where(
        (event) =>
            event.status == LiveStatus.planned && event.eventDate.isAfter(now),
      )
      .toList();
  upcoming.sort((lhs, rhs) => lhs.eventDate.compareTo(rhs.eventDate));
  return upcoming;
}

List<LiveEvent> historicalEvents(List<LiveEvent> events) {
  final history = events
      .where((event) => event.status == LiveStatus.attended)
      .toList();
  history.sort((lhs, rhs) => rhs.eventDate.compareTo(lhs.eventDate));
  return history;
}
