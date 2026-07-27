import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oshilife/core/design/design_radius.dart';
import 'package:oshilife/core/design/theme_system.dart';
import 'package:oshilife/core/design/widgets/cover_image.dart';
import 'package:oshilife/core/design/widgets/status_badge.dart';
import 'package:oshilife/core/design/widgets/venue_tag.dart';
import 'package:oshilife/core/utils/event_countdown_formatter.dart';
import 'package:oshilife/data/images/image_store.dart';
import 'package:oshilife/data/models/live_event.dart';
import 'package:oshilife/l10n/app_localizations.dart';

/// Port of `HomeEventCarouselCard.swift` fused with the dashboard's
/// countdown card: hero cover with status badge, artist/title, date,
/// venue tag, and the big tabular countdown on the accent wash.
class EventCarouselCard extends StatelessWidget {
  const EventCarouselCard({
    super.key,
    required this.event,
    required this.now,
    this.imageStore,
    this.onOpen,
    this.onEdit,
  });

  final LiveEvent event;
  final DateTime now;
  final ImageStore? imageStore;
  final VoidCallback? onOpen;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final oshiTheme = OshiTheme.of(context);
    final locale = Localizations.localeOf(context).toString();

    return Semantics(
      label: l10n.cardAccessibility(event.artistName, event.title),
      button: true,
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(DesignRadius.large),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          onLongPress: onEdit == null
              ? null
              : () => _showContextMenu(context, l10n),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  CoverImage(
                    file: imageStore?.imageFile(event.coverImagePath),
                    height: 260,
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: StatusBadge(status: event.status),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.artistName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 15,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            DateFormat.yMMMEd(locale).format(event.eventDate),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    if (event.venue.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      VenueTag(venue: event.venue),
                    ],
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(DesignRadius.medium),
                  border: Border.all(
                    color: oshiTheme.border.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homeSelectedLiveCountdown,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      EventCountdownFormatter.shortText(
                        until: event.eventDate,
                        now: now,
                      ),
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: Text(l10n.commonEdit),
          onTap: () {
            Navigator.of(sheetContext).pop();
            onEdit?.call();
          },
        ),
      ),
    );
  }
}

/// Port of `HistoricalEventCard` — the attended-history shelf tile.
class HistoricalEventCard extends StatelessWidget {
  const HistoricalEventCard({
    super.key,
    required this.event,
    this.imageStore,
    this.onOpen,
  });

  final LiveEvent event;
  final ImageStore? imageStore;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    return SizedBox(
      width: 208,
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(DesignRadius.medium),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CoverImage(
                file: imageStore?.imageFile(event.coverImagePath),
                height: 122,
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.yMMMd(locale).format(event.eventDate),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
