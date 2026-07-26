import 'package:flutter/material.dart';
import 'package:oshilife/core/design/status_visuals.dart';
import 'package:oshilife/data/models/live_status.dart';
import 'package:oshilife/l10n/app_localizations.dart';

/// Port of `StatusBadge.swift`: a capsule chip with the status icon and
/// localized name on a status-tinted translucent fill (the iOS glass
/// capsule maps to a tonal capsule, plan §5.1).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final LiveStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tint = status.tint(Theme.of(context).colorScheme);
    return Semantics(
      label: status.localizedName(l10n),
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: 13, color: tint),
            const SizedBox(width: 4),
            Text(
              status.localizedName(l10n),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: tint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
