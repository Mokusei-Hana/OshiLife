import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oshilife/app/app.dart';
import 'package:oshilife/app/providers.dart';
import 'package:oshilife/data/db/database_bootstrap.dart';
import 'package:oshilife/features/import/share_intent_bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // iOS-parity bootstrap: a store that cannot open degrades to a warned
  // in-memory session instead of a crash loop.
  final bootstrap = await openDatabaseWithFallback();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWith((ref) {
          ref.onDispose(bootstrap.database.close);
          return bootstrap.database;
        }),
        startupPersistenceErrorProvider.overrideWithValue(
          bootstrap.persistenceError,
        ),
      ],
      child: const ShareIntentBootstrap(child: OshiLifeApp()),
    ),
  );
}
