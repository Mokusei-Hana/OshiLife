import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Drift mapping of the SwiftData V3 `LiveEvent` schema
/// (`OshiLife/Data/Models/LiveEvent.swift`).
///
/// Conventions shared with iOS (do not break — they keep a future
/// export/import round-trippable):
/// - `id` / `selectedTicketId` are uppercase UUID strings.
/// - Dates are ISO-8601 UTC text (`store_date_time_values_as_text` in
///   build.yaml).
/// - `performersJson` / `ticketOptionsJson` are denormalized JSON arrays
///   with `'[]'` defaults, exactly like the Swift property defaults that
///   made the V2→V3 lightweight migration legal.
@DataClassName('LiveEventRow')
class LiveEvents extends Table {
  TextColumn get id => text()();
  TextColumn get artistName => text()();
  TextColumn get title => text()();
  DateTimeColumn get eventDate => dateTime()();
  DateTimeColumn get openTime => dateTime().nullable()();
  DateTimeColumn get startTime => dateTime().nullable()();
  TextColumn get venue => text().withDefault(const Constant(''))();
  TextColumn get address => text().withDefault(const Constant(''))();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get coverImagePath => text().nullable()();
  TextColumn get ticketUrlString => text().withDefault(const Constant(''))();
  TextColumn get sourceUrlString => text().withDefault(const Constant(''))();
  TextColumn get performersJson => text().withDefault(const Constant('[]'))();
  TextColumn get ticketOptionsJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get selectedTicketId => text().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get statusRawValue => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Drift schema version 1 corresponds to the iOS logical schema V3.
/// Future iOS schema versions must land here as drift migrations in the
/// same parity PR.
@DriftDatabase(tables: [LiveEvents])
class OshiLifeDatabase extends _$OshiLifeDatabase {
  OshiLifeDatabase(super.executor);

  /// Production database. The name matches the iOS store name
  /// (`SharedConstants.databaseName`).
  OshiLifeDatabase.open() : super(driftDatabase(name: 'OshiLife'));

  @override
  int get schemaVersion => 1;
}
