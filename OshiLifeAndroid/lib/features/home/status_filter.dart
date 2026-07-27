import 'package:oshilife/data/models/live_event.dart';
import 'package:oshilife/data/models/live_status.dart';
import 'package:oshilife/l10n/app_localizations.dart';

/// Port of `StatusFilter` from `LiveListViewModel.swift`.
enum StatusFilter {
  all,
  planned,
  attended,
  cancelled;

  bool matches(LiveEvent event) => switch (this) {
    all => true,
    planned => event.status == LiveStatus.planned,
    attended => event.status == LiveStatus.attended,
    cancelled => event.status == LiveStatus.cancelled,
  };

  String localizedName(AppLocalizations l10n) => switch (this) {
    all => l10n.filterAll,
    planned => l10n.statusPlanned,
    attended => l10n.statusAttended,
    cancelled => l10n.statusCancelled,
  };
}
