import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:oshilife/app/providers.dart';
import 'package:oshilife/core/design/design_radius.dart';
import 'package:oshilife/core/design/theme_system.dart';
import 'package:oshilife/core/design/widgets/cover_image.dart';
import 'package:oshilife/core/design/widgets/empty_state.dart';
import 'package:oshilife/core/design/widgets/section_card.dart';
import 'package:oshilife/core/design/widgets/status_badge.dart';
import 'package:oshilife/core/utils/map_service.dart';
import 'package:oshilife/data/models/live_event.dart';
import 'package:oshilife/features/home/home_providers.dart';
import 'package:oshilife/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Port of `LiveDetailView.swift`: sectioned cards — hero header, event
/// information with the OPEN/START pair and the venue row, performers,
/// tickets with the platform-aware action link, notes, and links. The
/// venue row opens the Android maps sheet (Google Maps + system chooser,
/// plan §7.4).
class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final events = ref.watch(liveEventsProvider).value;
    final event = events?.where((event) => event.id == eventId).firstOrNull;

    if (event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.event_busy_outlined,
          title: l10n.errorMissingLive,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => context.push('/editor', extra: event),
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.commonEdit,
          ),
          IconButton(
            onPressed: () => _confirmDelete(context, ref, event),
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.commonDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _header(context, ref, event),
          const SizedBox(height: 16),
          _information(context, event, l10n),
          if (event.performers.isNotEmpty) ...[
            const SizedBox(height: 16),
            SectionCard(
              header: l10n.fieldPerformers,
              child: Text(
                event.performers.join(' / '),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
          if (event.ticketOptions.isNotEmpty || event.ticketUrl != null) ...[
            const SizedBox(height: 16),
            _tickets(context, event, l10n),
          ],
          if (event.notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            SectionCard(
              header: l10n.fieldNotes,
              child: SelectableText(
                event.notes,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
          if (event.ticketUrl != null || event.sourceUrl != null) ...[
            const SizedBox(height: 16),
            _links(context, event, l10n),
          ],
        ],
      ),
    );
  }

  Widget _header(BuildContext context, WidgetRef ref, LiveEvent event) {
    final theme = Theme.of(context);
    final imageStore = ref.watch(imageStoreProvider).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Stack(
            children: [
              CoverImage(
                file: imageStore?.imageFile(event.coverImagePath),
                aspectRatio: 4 / 5,
                borderRadius: BorderRadius.circular(DesignRadius.large),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: StatusBadge(status: event.status),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          event.artistName,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          event.title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _information(
    BuildContext context,
    LiveEvent event,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final timeFormat = DateFormat.Hm(locale);
    final openTime = event.openTime;
    final startTime = event.startTime;
    return SectionCard(
      header: l10n.detailInformation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat.yMMMEd(locale).format(event.eventDate),
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
          if (openTime != null || startTime != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (openTime != null)
                  Expanded(
                    child: _timeColumn(
                      context,
                      label: l10n.fieldOpenTime,
                      value: timeFormat.format(openTime),
                      prominent: false,
                    ),
                  ),
                if (startTime != null)
                  Expanded(
                    child: _timeColumn(
                      context,
                      label: l10n.fieldStartTime,
                      value: timeFormat.format(startTime),
                      prominent: true,
                    ),
                  ),
              ],
            ),
          ],
          if (event.venue.isNotEmpty || event.address.isNotEmpty) ...[
            const SizedBox(height: 12),
            _venueRow(context, event, l10n),
          ],
        ],
      ),
    );
  }

  Widget _timeColumn(
    BuildContext context, {
    required String label,
    required String value,
    required bool prominent,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style:
              (prominent
                      ? theme.textTheme.headlineSmall
                      : theme.textTheme.titleLarge)
                  ?.copyWith(
                    color: prominent
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: prominent ? FontWeight.w700 : FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
        ),
      ],
    );
  }

  Widget _venueRow(
    BuildContext context,
    LiveEvent event,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    return Material(
      color: ThemeSystem.locationColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(DesignRadius.medium),
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignRadius.medium),
        onTap: () => _showMapSheet(context, event, l10n),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(
                Icons.location_on,
                color: ThemeSystem.locationColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.venue.isNotEmpty ? event.venue : event.address,
                      style: theme.textTheme.titleSmall,
                    ),
                    if (event.venue.isNotEmpty && event.address.isNotEmpty)
                      Text(
                        event.address,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMapSheet(
    BuildContext context,
    LiveEvent event,
    AppLocalizations l10n,
  ) {
    final query = event.venue.isNotEmpty ? event.venue : event.address;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.detailOpenMaps,
                style: Theme.of(sheetContext).textTheme.titleSmall,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.map_outlined),
              title: Text(l10n.mapGoogle),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _openMap(
                  context,
                  MapService.googleMapsUri(
                    venue: query,
                    latitude: event.latitude,
                    longitude: event.longitude,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(l10n.detailOpenMaps),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _openMap(
                  context,
                  MapService.geoUri(
                    venue: query,
                    latitude: event.latitude,
                    longitude: event.longitude,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMap(BuildContext context, Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _tickets(
    BuildContext context,
    LiveEvent event,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final options = event.ticketOptions;
    final actionUrl = event.ticketActionUrl;
    return SectionCard(
      header: l10n.editorTickets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < options.length; index += 1) ...[
            if (index > 0) const Divider(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (options[index].id == event.selectedTicketId) ...[
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              options[index].name,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight:
                                    options[index].id == event.selectedTicketId
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (options[index].description != null)
                        Text(
                          options[index].description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (options[index].price != null)
                  Text(
                    '¥${NumberFormat.decimalPattern().format(options[index].price)}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
          ],
          if (actionUrl != null) ...[
            if (options.isNotEmpty) const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    launchUrl(actionUrl, mode: LaunchMode.externalApplication),
                icon: Icon(
                  event.selectedTicketId != null
                      ? Icons.confirmation_number
                      : Icons.shopping_cart_outlined,
                ),
                label: Text(
                  event.selectedTicketId != null
                      ? l10n.ticketOpenPurchased
                      : l10n.ticketPurchase,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _links(BuildContext context, LiveEvent event, AppLocalizations l10n) {
    final ticketUrl = event.ticketUrl;
    final sourceUrl = event.sourceUrl;
    return SectionCard(
      header: l10n.detailLinks,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          if (ticketUrl != null)
            ListTile(
              leading: const Icon(Icons.confirmation_number_outlined),
              title: Text(l10n.fieldTicketUrl),
              subtitle: Text(
                ticketUrl.toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () =>
                  launchUrl(ticketUrl, mode: LaunchMode.externalApplication),
            ),
          if (sourceUrl != null)
            ListTile(
              leading: const Icon(Icons.link),
              title: Text(l10n.detailSource),
              subtitle: Text(
                sourceUrl.toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () =>
                  launchUrl(sourceUrl, mode: LaunchMode.externalApplication),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    LiveEvent event,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteTitle),
        content: Text(l10n.deleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // iOS order: capture the cover path, delete the row, then the file.
    final coverPath = event.coverImagePath;
    await ref.read(liveStoreProvider).deleteEvent(event);
    final imageStore = await ref.read(imageStoreProvider.future);
    await imageStore.remove(coverPath);
    if (context.mounted) context.pop();
  }
}
