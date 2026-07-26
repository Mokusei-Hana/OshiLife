import 'package:drift/drift.dart';
import 'package:oshilife/data/db/database.dart';
import 'package:oshilife/data/models/live_event.dart';

/// Port of `OshiLife/Data/Persistence/LiveStore.swift` on top of Drift.
///
/// The iOS store fetches everything and sorts in memory; the sort pivot is
/// the *start of today* in the device calendar, which is not expressible as
/// a static SQL ORDER BY — so the same in-memory sort is kept here.
class LiveStore {
  LiveStore(this._db);

  final OshiLifeDatabase _db;

  /// Two-block ordering: upcoming (`eventDate >= startOfDay(now)`) first in
  /// ascending order, then past events in descending order.
  Future<List<LiveEvent>> fetchAll({DateTime? now}) async {
    final rows = await _db.select(_db.liveEvents).get();
    final events = rows.map(_toDomain).toList();
    return sortedForList(events, now: now ?? DateTime.now());
  }

  /// Reactive variant (deliberate platform difference, plan §6.2): the UI
  /// watches this stream instead of re-loading on lifecycle events.
  Stream<List<LiveEvent>> watchAll({DateTime Function()? clock}) {
    return _db.select(_db.liveEvents).watch().map((rows) {
      final events = rows.map(_toDomain).toList();
      return sortedForList(events, now: (clock ?? DateTime.now)());
    });
  }

  Future<LiveEvent?> eventById(String id) async {
    final query = _db.select(_db.liveEvents)
      ..where((table) => table.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  /// Duplicate lookup for imports: exact string match, and the empty string
  /// (meaning "no source URL") never matches anything. Saving duplicates is
  /// allowed (the banner is advisory), so this takes `.first` like iOS
  /// rather than asserting uniqueness.
  Future<LiveEvent?> eventBySourceUrl(String sourceUrlString) async {
    if (sourceUrlString.isEmpty) return null;
    final query = _db.select(_db.liveEvents)
      ..where((table) => table.sourceUrlString.equals(sourceUrlString))
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<void> insertEvent(LiveEvent event) async {
    await _db.into(_db.liveEvents).insert(_toCompanion(event));
  }

  /// Persists in-place mutations of a fetched event (the iOS pattern is
  /// "mutate the managed object, then save()").
  Future<void> saveEvent(LiveEvent event) async {
    await _db.update(_db.liveEvents).replace(_toCompanion(event));
  }

  Future<void> deleteEvent(LiveEvent event) async {
    final query = _db.delete(_db.liveEvents)
      ..where((table) => table.id.equals(event.id));
    await query.go();
  }

  /// Port of the `LiveStore.fetchAll` comparator.
  static List<LiveEvent> sortedForList(
    List<LiveEvent> events, {
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final sorted = List<LiveEvent>.of(events);
    sorted.sort((lhs, rhs) {
      final lhsUpcoming = !lhs.eventDate.isBefore(today);
      final rhsUpcoming = !rhs.eventDate.isBefore(today);
      if (lhsUpcoming != rhsUpcoming) return lhsUpcoming ? -1 : 1;
      if (lhsUpcoming) return lhs.eventDate.compareTo(rhs.eventDate);
      return rhs.eventDate.compareTo(lhs.eventDate);
    });
    return sorted;
  }

  static LiveEvent _toDomain(LiveEventRow row) {
    return LiveEvent.persisted(
      id: row.id,
      artistName: row.artistName,
      title: row.title,
      eventDate: row.eventDate.toLocal(),
      openTime: row.openTime?.toLocal(),
      startTime: row.startTime?.toLocal(),
      venue: row.venue,
      address: row.address,
      latitude: row.latitude,
      longitude: row.longitude,
      coverImagePath: row.coverImagePath,
      ticketUrlString: row.ticketUrlString,
      sourceUrlString: row.sourceUrlString,
      performersJson: row.performersJson,
      ticketOptionsJson: row.ticketOptionsJson,
      selectedTicketId: row.selectedTicketId,
      notes: row.notes,
      statusRawValue: row.statusRawValue,
      createdAt: row.createdAt.toLocal(),
      updatedAt: row.updatedAt.toLocal(),
    );
  }

  static LiveEventsCompanion _toCompanion(LiveEvent event) {
    return LiveEventsCompanion(
      id: Value(event.id),
      artistName: Value(event.artistName),
      title: Value(event.title),
      eventDate: Value(event.eventDate.toUtc()),
      openTime: Value(event.openTime?.toUtc()),
      startTime: Value(event.startTime?.toUtc()),
      venue: Value(event.venue),
      address: Value(event.address),
      latitude: Value(event.latitude),
      longitude: Value(event.longitude),
      coverImagePath: Value(event.coverImagePath),
      ticketUrlString: Value(event.ticketUrlString),
      sourceUrlString: Value(event.sourceUrlString),
      performersJson: Value(event.performersJson),
      ticketOptionsJson: Value(event.ticketOptionsJson),
      selectedTicketId: Value(event.selectedTicketId),
      notes: Value(event.notes),
      statusRawValue: Value(event.statusRawValue),
      createdAt: Value(event.createdAt.toUtc()),
      updatedAt: Value(event.updatedAt.toUtc()),
    );
  }
}
