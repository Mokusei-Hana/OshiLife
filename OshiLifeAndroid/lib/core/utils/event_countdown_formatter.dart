/// Port of `OshiLife/Core/Utilities/EventCountdownFormatter.swift`.
///
/// Compact countdown labels such as "2d 5h", "3h 12m", or "45m". The ASCII
/// suffixes are deliberately unlocalized — parity with iOS (see the plan's
/// open decision #4).
abstract final class EventCountdownFormatter {
  static String shortText({required DateTime until, required DateTime now}) {
    var seconds = until.difference(now).inSeconds;
    if (seconds < 0) seconds = 0;
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}
