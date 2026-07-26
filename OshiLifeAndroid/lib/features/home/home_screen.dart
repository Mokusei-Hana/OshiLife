import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oshilife/core/design/design_radius.dart';
import 'package:oshilife/core/design/theme_system.dart';
import 'package:oshilife/l10n/app_localizations.dart';

/// M0/M1 placeholder for `LiveListView` — proves l10n and 推し色 theming.
/// The real card/list home ships in M3.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final oshiTheme = OshiTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
          ),
        ],
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: oshiTheme.background,
            borderRadius: BorderRadius.circular(DesignRadius.large),
            border: Border.all(color: oshiTheme.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.queue_music, size: 48, color: oshiTheme.primary),
              const SizedBox(height: 12),
              Text(
                l10n.listEmptyTitle,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.listEmptyMessage,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
