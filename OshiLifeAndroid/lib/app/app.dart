import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oshilife/app/providers.dart';
import 'package:oshilife/app/router.dart';
import 'package:oshilife/core/design/theme_system.dart';
import 'package:oshilife/l10n/app_localizations.dart';

class OshiLifeApp extends ConsumerWidget {
  const OshiLifeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      theme: ThemeSystem.buildTheme(
        settings: settings,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeSystem.buildTheme(
        settings: settings,
        brightness: Brightness.dark,
      ),
      themeMode: settings.appearance.themeMode,
      locale: settings.language.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Unsupported device locales fall back to Japanese — the development
      // language on iOS — not English (plan §8).
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale != null) {
          for (final supported in supportedLocales) {
            if (supported.languageCode == locale.languageCode) {
              return supported;
            }
          }
        }
        return const Locale('ja');
      },
      routerConfig: ref.watch(routerProvider),
    );
  }
}
