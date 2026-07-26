import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
// ChangeNotifierProvider intentionally comes from the legacy surface:
// AppSettings is a faithful port of the mutable iOS `@Observable` object,
// and a ChangeNotifier keeps that shape 1:1 (plan §2.2).
import 'package:flutter_riverpod/legacy.dart';
import 'package:oshilife/data/db/database.dart';
import 'package:oshilife/data/db/live_store.dart';
import 'package:oshilife/data/images/image_store.dart';
import 'package:oshilife/data/settings/app_settings.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden with the real instance in `main()`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  ),
);

final appSettingsProvider = ChangeNotifierProvider<AppSettings>(
  (ref) => AppSettings(ref.watch(sharedPreferencesProvider)),
);

final databaseProvider = Provider<OshiLifeDatabase>((ref) {
  final database = OshiLifeDatabase.open();
  ref.onDispose(database.close);
  return database;
});

final liveStoreProvider = Provider<LiveStore>(
  (ref) => LiveStore(ref.watch(databaseProvider)),
);

/// Cover images live under the app's support directory, mirroring the iOS
/// `<container>/Images/` layout with relative paths in the database.
final imageStoreProvider = FutureProvider<ImageStore>((ref) async {
  final support = await getApplicationSupportDirectory();
  return ImageStore(root: Directory(support.path));
});
