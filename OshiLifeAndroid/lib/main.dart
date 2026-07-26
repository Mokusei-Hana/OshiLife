import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oshilife/app/app.dart';
import 'package:oshilife/app/providers.dart';
import 'package:oshilife/features/import/share_intent_bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ShareIntentBootstrap(child: OshiLifeApp()),
    ),
  );
}
