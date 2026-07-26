import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oshilife/app/providers.dart';
import 'package:oshilife/core/design/widgets/empty_state.dart';
import 'package:oshilife/data/images/image_store.dart';
import 'package:oshilife/data/models/live_event.dart';
import 'package:oshilife/data/settings/app_settings.dart';
import 'package:oshilife/features/home/dashboard_view.dart';
import 'package:oshilife/features/home/event_list_row.dart';
import 'package:oshilife/features/home/home_providers.dart';
import 'package:oshilife/features/home/status_filter.dart';
import 'package:oshilife/features/import/import_providers.dart';
import 'package:oshilife/import/models/pending_share_import.dart';
import 'package:oshilife/l10n/app_localizations.dart';

/// Port of `LiveListView.swift`: the single root screen. Switches between
/// the card dashboard and the list per `AppSettings.homeDisplayStyle`,
/// with status filtering, the add menu, and the empty states.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(appSettingsProvider);
    final filter = ref.watch(statusFilterProvider);
    final eventsAsync = ref.watch(liveEventsProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final imageStore = ref.watch(imageStoreProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          PopupMenuButton<StatusFilter>(
            tooltip: l10n.filterTitle,
            icon: Icon(
              filter == StatusFilter.all ? Icons.filter_list : Icons.filter_alt,
              color: filter == StatusFilter.all
                  ? null
                  : Theme.of(context).colorScheme.primary,
            ),
            initialValue: filter,
            onSelected: (value) =>
                ref.read(statusFilterProvider.notifier).state = value,
            itemBuilder: (context) => [
              for (final value in StatusFilter.values)
                CheckedPopupMenuItem(
                  value: value,
                  checked: value == filter,
                  child: Text(value.localizedName(l10n)),
                ),
            ],
          ),
          PopupMenuButton<String>(
            tooltip: l10n.liveAdd,
            icon: const Icon(Icons.add),
            onSelected: (value) => switch (value) {
              'import' => _startManualImport(context, ref),
              _ => context.push('/editor'),
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'create',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.edit_calendar_outlined),
                  title: Text(l10n.liveCreateManually),
                ),
              ),
              PopupMenuItem(
                value: 'import',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.save_alt),
                  title: Text(l10n.manualImportTitle),
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
          ),
        ],
      ),
      body: eventsAsync.when(
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(l10n.commonLoading),
            ],
          ),
        ),
        error: (error, stackTrace) => EmptyState(
          icon: Icons.error_outline,
          title: l10n.commonError,
          message: '$error',
        ),
        data: (events) {
          final filtered = events.where(filter.matches).toList();
          if (filtered.isEmpty) {
            // Like the iOS empty state, both add-menu entries are offered.
            return EmptyState(
              icon: Icons.queue_music,
              title: l10n.listEmptyTitle,
              message: l10n.listEmptyMessage,
              action: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    onPressed: () => context.push('/editor'),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.liveCreateManually),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _startManualImport(context, ref),
                    icon: const Icon(Icons.save_alt, size: 18),
                    label: Text(l10n.manualImportTitle),
                  ),
                ],
              ),
            );
          }
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: settings.homeDisplayStyle == HomeDisplayStyle.card
                ? DashboardView(
                    key: const ValueKey(HomeDisplayStyle.card),
                    events: filtered,
                    now: now,
                    imageStore: imageStore,
                    onOpen: (event) => _openDetail(context, event),
                    onEdit: (event) => _openEditor(context, event),
                  )
                : _EventList(
                    key: const ValueKey(HomeDisplayStyle.list),
                    events: filtered,
                    now: now,
                    imageStore: imageStore,
                    onRefresh: () async => ref.invalidate(liveEventsProvider),
                  ),
          );
        },
      ),
    );
  }

  void _openDetail(BuildContext context, LiveEvent event) {
    context.push('/event/${event.id}');
  }

  void _openEditor(BuildContext context, LiveEvent event) {
    context.push('/editor', extra: event);
  }

  /// iOS presents the import editor when the manual sheet closes with a
  /// draft; here the manual screen pops with it and the coordinator takes
  /// over (duplicate lookup + route).
  Future<void> _startManualImport(BuildContext context, WidgetRef ref) async {
    final draft = await context.push<PendingShareImport>('/import/manual');
    if (draft == null) return;
    await ref.read(shareReceiveCoordinatorProvider).presentManual(draft);
  }
}

class _EventList extends StatelessWidget {
  const _EventList({
    super.key,
    required this.events,
    required this.now,
    required this.imageStore,
    required this.onRefresh,
  });

  final List<LiveEvent> events;
  final DateTime now;
  final ImageStore? imageStore;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final event = events[index];
          return EventListRow(
            event: event,
            now: now,
            imageStore: imageStore,
            onOpen: () => context.push('/event/${event.id}'),
            onEdit: () => context.push('/editor', extra: event),
          );
        },
      ),
    );
  }
}
