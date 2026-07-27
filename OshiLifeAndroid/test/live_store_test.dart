import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshilife/data/db/database.dart';
import 'package:oshilife/data/db/live_store.dart';
import 'package:oshilife/data/models/live_event.dart';

// Port of OshiLifeTests/LiveStoreTests.swift (in-memory container →
// in-memory drift database).
void main() {
  late OshiLifeDatabase database;
  late LiveStore store;

  setUp(() {
    database = OshiLifeDatabase(NativeDatabase.memory());
    store = LiveStore(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('CRUD and upcoming-then-history ordering', () async {
    final now = DateTime.fromMillisecondsSinceEpoch(1800000000 * 1000);
    final past = LiveEvent(
      artistName: 'A',
      title: 'Past',
      eventDate: now.subtract(const Duration(days: 1)),
    );
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

    await store.insertEvent(past);
    await store.insertEvent(later);
    await store.insertEvent(sooner);

    final all = await store.fetchAll(now: now);
    expect(all.map((event) => event.title).toList(), [
      'Sooner',
      'Later',
      'Past',
    ]);
    expect((await store.eventById(later.id))?.title, 'Later');

    await store.deleteEvent(later);
    expect(await store.eventById(later.id), isNull);
  });

  test('persists venue coordinates', () async {
    final event = LiveEvent(
      artistName: 'A',
      title: 'Coordinate',
      eventDate: DateTime.now(),
      venue: 'Venue',
      address: 'Address',
      latitude: 35.0,
      longitude: 139.0,
    );

    await store.insertEvent(event);
    final fetched = await store.eventById(event.id);

    expect(fetched, isNotNull);
    expect(fetched!.latitude, 35.0);
    expect(fetched.longitude, 139.0);
  });

  test('round-trips JSON columns and status through the database', () async {
    final event = LiveEvent(
      artistName: '推し',
      title: 'ライブ',
      eventDate: DateTime.now(),
      performers: ['chuLa', 'TENRIN'],
    );

    await store.insertEvent(event);
    final fetched = (await store.eventById(event.id))!;
    expect(fetched.performers, ['chuLa', 'TENRIN']);
    expect(fetched.statusRawValue, 'planned');

    // Mutate-then-save, the iOS editing pattern.
    fetched.title = '更新';
    await store.saveEvent(fetched);
    expect((await store.eventById(event.id))!.title, '更新');
  });

  // Port of the LiveStore.event(sourceURLString:) dedup contract.
  test('source URL lookup ignores the empty string', () async {
    final withSource = LiveEvent(
      artistName: 'A',
      title: 'Imported',
      eventDate: DateTime.now(),
      sourceUrlString: 'https://x.com/oshi/status/42',
    );
    final withoutSource = LiveEvent(
      artistName: 'A',
      title: 'Manual',
      eventDate: DateTime.now(),
    );

    await store.insertEvent(withSource);
    await store.insertEvent(withoutSource);

    expect(
      (await store.eventBySourceUrl('https://x.com/oshi/status/42'))?.title,
      'Imported',
    );
    expect(await store.eventBySourceUrl(''), isNull);
  });
}
