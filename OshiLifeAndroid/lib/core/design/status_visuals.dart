import 'package:flutter/material.dart';
import 'package:oshilife/data/models/live_status.dart';
import 'package:oshilife/l10n/app_localizations.dart';

/// Port of the UI members of `LiveStatus` (`LiveStatus.swift`): icon and
/// tint per status, with Material Symbols standing in for SF Symbols
/// (sparkles → auto_awesome, checkmark.circle.fill → check_circle,
/// xmark.circle.fill → cancel).
extension LiveStatusVisuals on LiveStatus {
  IconData get icon => switch (this) {
    LiveStatus.planned => Icons.auto_awesome,
    LiveStatus.attended => Icons.check_circle,
    LiveStatus.cancelled => Icons.cancel,
  };

  Color tint(ColorScheme scheme) => switch (this) {
    LiveStatus.planned => const Color(0xFFF04D93),
    LiveStatus.attended => const Color(0xFF2E9E52),
    LiveStatus.cancelled => scheme.onSurfaceVariant,
  };

  String localizedName(AppLocalizations l10n) => switch (this) {
    LiveStatus.planned => l10n.statusPlanned,
    LiveStatus.attended => l10n.statusAttended,
    LiveStatus.cancelled => l10n.statusCancelled,
  };
}
