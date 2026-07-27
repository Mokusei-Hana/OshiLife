import 'dart:io';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
// ChangeNotifierProvider intentionally comes from the legacy surface:
// AppSettings is a faithful port of the mutable iOS `@Observable` object,
// and a ChangeNotifier keeps that shape 1:1 (plan §2.2).
import 'package:flutter_riverpod/legacy.dart';
import 'package:oshilife/data/db/database.dart';
import 'package:oshilife/data/db/live_store.dart';
import 'package:oshilife/data/images/image_store.dart';
import 'package:oshilife/data/settings/app_settings.dart';
import 'package:oshilife/l10n/app_localizations.dart';
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

/// Raw description of the failure that forced the in-memory fallback at
/// startup — the iOS `startupWarning`. Null while persistence is healthy;
/// `main()` overrides it after probing the store. The home screen renders
/// it through the localized `error.persistence_fallback`.
final startupPersistenceErrorProvider = Provider<String?>((ref) => null);

final liveStoreProvider = Provider<LiveStore>(
  (ref) => LiveStore(ref.watch(databaseProvider)),
);

/// Cover images live under the app's support directory, mirroring the iOS
/// `<container>/Images/` layout with relative paths in the database.
final imageStoreProvider = FutureProvider<ImageStore>((ref) async {
  final support = await getApplicationSupportDirectory();
  return ImageStore(root: Directory(support.path));
});

/// The active [AppLocalizations] resolved outside the widget tree, for
/// layers that have no `BuildContext` (the import warning formatter, the
/// share coordinator). Mirrors the app's `localeResolutionCallback`:
/// explicit language setting first, then the device locale by language
/// code, then Japanese.
final l10nProvider = Provider<AppLocalizations>((ref) {
  final settings = ref.watch(appSettingsProvider);
  final preferred =
      settings.language.locale ?? PlatformDispatcher.instance.locale;
  for (final supported in AppLocalizations.supportedLocales) {
    if (supported.languageCode == preferred.languageCode) {
      return lookupAppLocalizations(supported);
    }
  }
  return lookupAppLocalizations(const Locale('ja'));
});
