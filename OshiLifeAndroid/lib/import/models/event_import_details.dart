import 'package:oshilife/data/models/ticket_option.dart';

/// Port of `Shared/Models/EventImportDetails.swift`.
///
/// JSON keys match the Swift `CodingKeys` exactly (note `linkedURL` with
/// capital URL). `performers` and `ticketOptions` tolerate absent keys —
/// the backwards-compat contract pinned by the iOS
/// `testEventDetailsDecodesPayloadsCreatedBeforeTicketOptions` test.
/// `linkedURL` is the only hard requirement. Dates serialize as ISO-8601
/// UTC strings (the strategy iOS uses for staged payload JSON).
class EventImportDetails {
  EventImportDetails({
    this.title,
    this.date,
    this.venue,
    this.openTime,
    this.startTime,
    this.performers = const [],
    this.ticketOptions = const [],
    this.ticketInformation,
    required this.linkedUrl,
  });

  factory EventImportDetails.fromJson(Map<String, dynamic> json) {
    final rawLinkedUrl = json['linkedURL'];
    final linkedUrl = rawLinkedUrl is String
        ? Uri.tryParse(rawLinkedUrl)
        : null;
    if (linkedUrl == null) {
      throw const FormatException('EventImportDetails requires linkedURL');
    }
    return EventImportDetails(
      title: json['title'] as String?,
      date: _parseDate(json['date']),
      venue: json['venue'] as String?,
      openTime: _parseDate(json['openTime']),
      startTime: _parseDate(json['startTime']),
      performers: (json['performers'] as List?)?.cast<String>() ?? const [],
      ticketOptions:
          (json['ticketOptions'] as List?)
              ?.map(
                (item) => TicketOption.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      ticketInformation: json['ticketInformation'] as String?,
      linkedUrl: linkedUrl,
    );
  }

  String? title;
  DateTime? date;
  String? venue;
  DateTime? openTime;
  DateTime? startTime;
  List<String> performers;
  List<TicketOption> ticketOptions;
  String? ticketInformation;
  Uri linkedUrl;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (title != null) 'title': title,
      if (date != null) 'date': date!.toUtc().toIso8601String(),
      if (venue != null) 'venue': venue,
      if (openTime != null) 'openTime': openTime!.toUtc().toIso8601String(),
      if (startTime != null) 'startTime': startTime!.toUtc().toIso8601String(),
      'performers': performers,
      'ticketOptions': ticketOptions.map((option) => option.toJson()).toList(),
      if (ticketInformation != null) 'ticketInformation': ticketInformation,
      'linkedURL': linkedUrl.toString(),
    };
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }

  @override
  bool operator ==(Object other) {
    return other is EventImportDetails &&
        other.title == title &&
        other.date == date &&
        other.venue == venue &&
        other.openTime == openTime &&
        other.startTime == startTime &&
        _listsEqual(other.performers, performers) &&
        _listsEqual(other.ticketOptions, ticketOptions) &&
        other.ticketInformation == ticketInformation &&
        other.linkedUrl == linkedUrl;
  }

  @override
  int get hashCode => Object.hash(
    title,
    date,
    venue,
    openTime,
    startTime,
    Object.hashAll(performers),
    Object.hashAll(ticketOptions),
    ticketInformation,
    linkedUrl,
  );

  static bool _listsEqual<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
