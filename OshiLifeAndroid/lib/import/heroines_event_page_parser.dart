import 'package:oshilife/data/models/ticket_option.dart';
import 'package:oshilife/import/event_page_parsing.dart';
import 'package:oshilife/import/models/event_import_details.dart';

/// Port of `Shared/Parsing/HeroinesEventPageParser.swift`.
///
/// Every regex is copied verbatim, with Swift's inline `(?i)`/`(?is)` flags
/// moved to Dart constructor flags (Dart `RegExp` does not support inline
/// flags). Dates and times are anchored to **Asia/Tokyo** (fixed +09:00, no
/// DST) exactly like iOS, and stored as UTC instants.
///
/// Returns null unless a date was found plus at least one of
/// title/venue/open/start — the parser never guesses.
class HeroinesEventPageParser implements EventPageParsing {
  const HeroinesEventPageParser();

  static const Duration _jstOffset = Duration(hours: 9);

  @override
  bool supports(Uri url) {
    final host = url.host.toLowerCase();
    return host == 'heroines.jp' || host == 'www.heroines.jp';
  }

  @override
  EventImportDetails? parse({required String html, required Uri sourceUrl}) {
    final text = _plainText(html);
    final eventText = _eventSection(text);
    final date = _eventDate(eventText);
    if (date == null) return null;

    final title = _eventTitle(eventText, html);
    final venue =
        _firstCapture(_venueAtLinePattern, eventText) ??
        _firstCapture(_venueAtPattern, eventText) ??
        _firstCapture(_venueLabelPattern, eventText);
    final times = _times(eventText, date);
    final performers = _performers(eventText);
    final ticketOptions = _ticketOptions(eventText);
    final ticketInformation = _ticketInformation(eventText, ticketOptions);

    if (title == null &&
        venue == null &&
        times.open == null &&
        times.start == null) {
      return null;
    }
    return EventImportDetails(
      title: title,
      date: date,
      venue: venue,
      openTime: times.open,
      startTime: times.start,
      performers: performers,
      ticketOptions: ticketOptions,
      ticketInformation: ticketInformation,
      linkedUrl: sourceUrl,
    );
  }

  // --- Regexes (Swift originals in comments) ---

  // (?is)<(script|style)\b[^>]*>.*?</\1>
  static final RegExp _scriptStylePattern = RegExp(
    r'<(script|style)\b[^>]*>.*?</\1>',
    caseSensitive: false,
    dotAll: true,
  );

  // (?i)<br\s*/?>
  static final RegExp _brPattern = RegExp(r'<br\s*/?>', caseSensitive: false);

  // (?i)</(?:p|div|h[1-6]|li|section|article)>
  static final RegExp _blockClosePattern = RegExp(
    r'</(?:p|div|h[1-6]|li|section|article)>',
    caseSensitive: false,
  );

  static final RegExp _tagPattern = RegExp(r'<[^>]+>');

  static final RegExp _newlinePattern = RegExp(
    '[\\n\\r\\u0085\\u2028\\u2029\\u000B\\u000C]',
  );

  static final List<RegExp> _eventSectionPatterns = [
    RegExp(r'(?:【|〖)\s*(?:公演概要|イベント概要)\s*(?:】|〗)'),
    RegExp(r'(?:^|\n)\s*(?:公演概要|イベント概要)\s*(?:\n|$)'),
  ];

  // (?<!\d)(20\d{2})[年./-]\s*(\d{1,2})[月./-]\s*(\d{1,2})日?
  // (?<!\d)(20\d{2})\s*年\s*(\d{1,2})\s*月\s*(\d{1,2})\s*日
  static final List<RegExp> _datePatterns = [
    RegExp(r'(?<!\d)(20\d{2})[年./-]\s*(\d{1,2})[月./-]\s*(\d{1,2})日?'),
    RegExp(r'(?<!\d)(20\d{2})\s*年\s*(\d{1,2})\s*月\s*(\d{1,2})\s*日'),
  ];

  static final RegExp _quotedTitlePattern = RegExp('(「[^」]+」)');

  // (?is)<h1\b[^>]*>(.*?)</h1>
  static final RegExp _h1Pattern = RegExp(
    r'<h1\b[^>]*>(.*?)</h1>',
    caseSensitive: false,
    dotAll: true,
  );

  static final RegExp _unlikelyTitlePattern = RegExp(
    r'^(?:OPEN|START|開場|開演|出演|会場|チケット|前方|一般|注意|※|▼|【|〖)',
    caseSensitive: false,
  );

  static final RegExp _sectionLabelPattern = RegExp('公演概要|イベント概要');

  static final RegExp _venueAtLinePattern = RegExp(
    r'(?:^|\n)\s*[@＠]\s*([^\n]+)',
  );

  static final RegExp _venueAtPattern = RegExp(r'[@＠]\s*([^\n]+)');

  static final RegExp _venueLabelPattern = RegExp(
    r'(?:会場|VENUE)\s*[：:]\s*([^\n]+)',
    caseSensitive: false,
  );

  static final RegExp _combinedTimesPattern = RegExp(
    r'(?:OPEN|開場)\s*/\s*(?:START|開演)\s*[：:]?\s*(\d{1,2}:\d{2})\s*/\s*(\d{1,2}:\d{2})',
    caseSensitive: false,
  );

  static final RegExp _openTimePattern = RegExp(
    r'(?:OPEN|開場)\s*(?:/|・)?\s*[：:]?\s*(\d{1,2}:\d{2})',
    caseSensitive: false,
  );

  static final RegExp _startTimePattern = RegExp(
    r'(?:START|開演)\s*(?:/|・)?\s*[：:]?\s*(\d{1,2}:\d{2})',
    caseSensitive: false,
  );

  static final RegExp _performersPattern = RegExp(
    r'(?:出演|出演者|ACT)\s*[：:]\s*([^\n]+)',
    caseSensitive: false,
  );

  static final RegExp _performerSeparatorPattern = RegExp('[/／、,]');

  static final RegExp _ticketLinePattern = RegExp(
    'チケット|TICKET',
    caseSensitive: false,
  );

  static final RegExp _ticketHeaderPattern = RegExp(
    r'^(?:▼\s*)?(?:チケット情報|チケット販売|TICKET(?:\s+INFORMATION)?)',
    caseSensitive: false,
  );

  static final RegExp _ticketBreakPattern = RegExp(
    r'^(?:注意|備考|※|▼|【|出演|会場|OPEN|START)',
    caseSensitive: false,
  );

  // ^\s*(.+?)\s*(?:[¥￥]\s*)?([0-9][0-9,]*)\s*円?(?:\s+(.+))?\s*$
  static final RegExp _ticketOptionPattern = RegExp(
    r'^\s*(.+?)\s*(?:[¥￥]\s*)?([0-9][0-9,]*)\s*円?(?:\s+(.+))?\s*$',
  );

  static final RegExp _ticketNamePattern = RegExp(
    'チケット|券|TICKET',
    caseSensitive: false,
  );

  // --- Pipeline ---

  static String _plainText(String html) {
    return html
        .replaceAll(_scriptStylePattern, '')
        .replaceAll(_brPattern, '\n')
        .replaceAll(_blockClosePattern, '\n')
        .replaceAll(_tagPattern, '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .split(_newlinePattern)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n');
  }

  static String _eventSection(String text) {
    for (final pattern in _eventSectionPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return text.substring(match.end);
      }
    }
    return text;
  }

  static DateTime? _eventDate(String text) {
    for (final pattern in _datePatterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;
      final year = int.tryParse(match.group(1)!);
      final month = int.tryParse(match.group(2)!);
      final day = int.tryParse(match.group(3)!);
      if (year == null || month == null || day == null) continue;
      // Midnight JST expressed as a UTC instant.
      return DateTime.utc(year, month, day).subtract(_jstOffset);
    }
    return null;
  }

  static String? _eventTitle(String text, String html) {
    final quoted = _firstCapture(_quotedTitlePattern, text);
    if (quoted != null) return quoted;

    final lines = text.split('\n');
    final dateIndex = lines.indexWhere((line) => _eventDate(line) != null);
    if (dateIndex >= 0) {
      // Up to two lines immediately before the date line, nearest first.
      String? preceding;
      for (
        var index = dateIndex - 1;
        index >= 0 && index >= dateIndex - 2;
        index -= 1
      ) {
        if (_isLikelyTitle(lines[index])) {
          preceding = lines[index];
          break;
        }
      }
      if (preceding != null && !_sectionLabelPattern.hasMatch(preceding)) {
        return preceding;
      }
      for (final line in lines.skip(dateIndex + 1).take(4)) {
        if (_isLikelyTitle(line)) return line;
      }
    }

    final heading = _firstCapture(_h1Pattern, html);
    if (heading != null) {
      final clean = _plainText(heading);
      final quotedHeading = _firstCapture(_quotedTitlePattern, clean);
      if (quotedHeading != null) return quotedHeading;
      if (clean.isNotEmpty && clean != 'NEWS') return clean;
    }
    return null;
  }

  static bool _isLikelyTitle(String line) {
    return !line.startsWith('@') &&
        !line.startsWith('＠') &&
        !_unlikelyTitlePattern.hasMatch(line);
  }

  static ({DateTime? open, DateTime? start}) _times(
    String text,
    DateTime eventDate,
  ) {
    final combined = _combinedTimesPattern.firstMatch(text);
    if (combined != null) {
      return (
        open: _time(combined.group(1), eventDate),
        start: _time(combined.group(2), eventDate),
      );
    }
    final open = _firstCapture(_openTimePattern, text);
    final start = _firstCapture(_startTimePattern, text);
    return (open: _time(open, eventDate), start: _time(start, eventDate));
  }

  /// iOS `calendar.date(bySettingHour:minute:second:of:)` with a JST
  /// calendar: same JST calendar day as [date], at the given wall time.
  static DateTime? _time(String? value, DateTime date) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    final jstDay = date.toUtc().add(_jstOffset);
    return DateTime.utc(
      jstDay.year,
      jstDay.month,
      jstDay.day,
      hour,
      minute,
    ).subtract(_jstOffset);
  }

  static List<String> _performers(String text) {
    final raw = _firstCapture(_performersPattern, text);
    if (raw == null) return const [];
    return raw
        .split(_performerSeparatorPattern)
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }

  static String? _ticketInformation(String text, List<TicketOption> options) {
    final lines = text.split('\n');
    final index = lines.indexWhere(_ticketLinePattern.hasMatch);
    if (index < 0) return null;
    final count = options.length + 1 > 8 ? options.length + 1 : 8;
    final result = lines.sublist(index).take(count).join('\n');
    return result.isEmpty ? null : result;
  }

  static List<TicketOption> _ticketOptions(String text) {
    final lines = text.split('\n');
    var startIndex = lines.indexWhere(
      (line) =>
          _ticketHeaderPattern.hasMatch(line) && _ticketOption(line) == null,
    );
    if (startIndex >= 0) {
      startIndex += 1;
    } else {
      startIndex = lines.indexWhere((line) => _ticketOption(line) != null);
      if (startIndex < 0) startIndex = lines.length;
    }

    final options = <TicketOption>[];
    for (final line in lines.skip(startIndex).take(20)) {
      if (_ticketBreakPattern.hasMatch(line)) {
        if (options.isNotEmpty) break;
        continue;
      }
      final option = _ticketOption(line);
      if (option == null) {
        if (options.isNotEmpty && line.isNotEmpty) break;
        continue;
      }
      options.add(option);
    }
    return options;
  }

  static TicketOption? _ticketOption(String line) {
    final match = _ticketOptionPattern.firstMatch(line);
    if (match == null) return null;
    final price = int.tryParse(match.group(2)!.replaceAll(',', ''));
    if (price == null) return null;
    final rawName = match.group(1)!.trim();
    if (!_ticketNamePattern.hasMatch(rawName)) return null;
    final description = match.group(3)?.trim() ?? '';
    return TicketOption(
      name: rawName,
      price: price,
      description: description.isEmpty ? null : description,
    );
  }

  static String? _firstCapture(RegExp pattern, String text) {
    final match = pattern.firstMatch(text);
    if (match == null) return null;
    final value = match.group(1)?.trim() ?? '';
    return value.isEmpty ? null : value;
  }
}
