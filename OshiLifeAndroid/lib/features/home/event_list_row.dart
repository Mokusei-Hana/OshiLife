import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oshilife/core/design/design_radius.dart';
import 'package:oshilife/core/design/widgets/cover_image.dart';
import 'package:oshilife/core/design/widgets/status_badge.dart';
import 'package:oshilife/core/design/widgets/venue_tag.dart';
import 'package:oshilife/core/utils/event_countdown_formatter.dart';
import 'package:oshilife/data/images/image_store.dart';
import 'package:oshilife/data/models/live_event.dart';
import 'package:oshilife/data/models/live_status.dart';
import 'package:oshilife/l10n/app_localizations.dart';

/// Port of `LiveListRowView.swift`: 82×88 cover, title + status badge,
/// date line, venue tag, and — only for future planned events — a tinted
/// countdown. (iOS uses the system relative-time text here; the Android
/// port reuses the shared compact countdown for consistency between the
/// two home modes — documented deviation.)
class EventListRow extends StatelessWidget {
  const EventListRow({
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
    final locale = Localizations.localeOf(context).toString();
    final showsCountdown =
        event.status == LiveStatus.planned && event.eventDate.isAfter(now);

    return Semantics(
      label: l10n.cardAccessibility(event.artistName, event.title),
      button: true,
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(DesignRadius.medium),
        child: InkWell(
          borderRadius: BorderRadius.circular(DesignRadius.medium),
          onTap: onOpen,
          onLongPress: onEdit == null
              ? null
              : () => _showContextMenu(context, l10n),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 82,
                  height: 88,
                  child: CoverImage(
                    file: imageStore?.imageFile(event.coverImagePath),
                    borderRadius: BorderRadius.circular(DesignRadius.small),
                    height: 88,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(status: event.status),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event.artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat.yMMMEd(locale).format(event.eventDate),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (event.venue.isNotEmpty)
                            Flexible(child: VenueTag(venue: event.venue)),
                          if (showsCountdown) ...[
                            const Spacer(),
                            Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              EventCountdownFormatter.shortText(
                                until: event.eventDate,
                                now: now,
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
