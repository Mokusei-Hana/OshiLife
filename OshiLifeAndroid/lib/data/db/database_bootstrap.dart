import 'package:drift/native.dart';
import 'package:oshilife/data/db/database.dart';

/// What the startup open produced: the database to run on, plus the error
/// that forced the in-memory fallback (null when persistence is healthy).
class DatabaseBootstrap {
  const DatabaseBootstrap({required this.database, this.persistenceError});

  final OshiLifeDatabase database;
  final String? persistenceError;
}

/// Port of the iOS `OshiLifeApp.init` bootstrap: try the persistent
/// store; if it cannot even answer a probe query, fall back to an
/// in-memory database and surface the raw error — the home screen wraps
/// it in the localized `error.persistence_fallback` banner.
Future<DatabaseBootstrap> openDatabaseWithFallback({
  OshiLifeDatabase Function() open = OshiLifeDatabase.open,
}) async {
  final database = open();
  try {
    // Drift opens lazily; force the open (and the schema migration) now so
    // a broken store is caught here instead of on the first screen.
    await database.customSelect('SELECT 1').get();
    return DatabaseBootstrap(database: database);
  } on Object catch (error) {
    try {
      await database.close();
    } on Object {
      // A broken executor may not close cleanly.
    }
    return DatabaseBootstrap(
      database: OshiLifeDatabase(NativeDatabase.memory()),
      persistenceError: error.toString(),
    );
  }
}
