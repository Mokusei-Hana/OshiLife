/// Port of `OshiLife/Data/Models/LiveStatus.swift`.
///
/// Raw values (`planned` / `attended` / `cancelled`) are persisted in the
/// database and must stay identical to the iOS spelling — including the
/// British double-L `cancelled`.
enum LiveStatus {
  planned,
  attended,
  cancelled;

  String get rawValue => name;

  /// Mirrors `LiveStatus(rawValue:)` — null for unknown values. Call sites
  /// that need the iOS `?? .planned` fallback use [LiveEvent.status].
  static LiveStatus? fromRawValue(String rawValue) {
    for (final status in values) {
      if (status.name == rawValue) return status;
    }
    return null;
  }

  /// Localization key, identical to the iOS `localizedName` resource key.
  String get localizationKey => switch (this) {
    planned => 'status.planned',
    attended => 'status.attended',
    cancelled => 'status.cancelled',
  };
}
