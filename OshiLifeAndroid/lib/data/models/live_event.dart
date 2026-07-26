import 'dart:convert';

import 'package:oshilife/data/models/live_status.dart';
import 'package:oshilife/data/models/ticket_option.dart';
import 'package:oshilife/data/models/ticket_platform.dart';
import 'package:uuid/uuid.dart';

/// Port of `OshiLife/Data/Models/LiveEvent.swift` (schema V3).
///
/// Mutable, mirroring the SwiftData `@Model` class. `performers` and
/// `ticketOptions` are denormalized JSON strings exactly like iOS, and all
/// UUIDs are stored as uppercase strings (Swift `UUID.uuidString`).
class LiveEvent {
  LiveEvent({
    String? id,
    required this.artistName,
    required this.title,
    required this.eventDate,
    this.openTime,
    this.startTime,
    this.venue = '',
    this.address = '',
    this.latitude,
    this.longitude,
    this.coverImagePath,
    this.ticketUrlString = '',
    this.sourceUrlString = '',
    List<String> performers = const [],
    List<TicketOption> ticketOptions = const [],
    // Initializes the field directly (not via the `ticketOptions` setter's
    // clearing rule), so a selected id that is not in `ticketOptions`
    // survives construction — matching the Swift init, where
    // `selectedTicketID` is assigned after the setters ran.
    this.selectedTicketId,
    this.notes = '',
    LiveStatus status = LiveStatus.planned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4().toUpperCase(),
       statusRawValue = status.rawValue,
       performersJson = _encode(performers),
       ticketOptionsJson = _encode(
         ticketOptions.map((option) => option.toJson()).toList(),
       ),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Rehydrates an event from persisted columns without re-encoding JSON.
  LiveEvent.persisted({
    required this.id,
    required this.artistName,
    required this.title,
    required this.eventDate,
    required this.openTime,
    required this.startTime,
    required this.venue,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.coverImagePath,
    required this.ticketUrlString,
    required this.sourceUrlString,
    required this.performersJson,
    required this.ticketOptionsJson,
    required this.selectedTicketId,
    required this.notes,
    required this.statusRawValue,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  String artistName;
  String title;
  DateTime eventDate;
  DateTime? openTime;
  DateTime? startTime;
  String venue;
  String address;
  double? latitude;
  double? longitude;
  String? coverImagePath;
  String ticketUrlString;
  String sourceUrlString;
  String performersJson;
  String ticketOptionsJson;
  String? selectedTicketId;
  String notes;
  String statusRawValue;
  DateTime createdAt;
  DateTime updatedAt;

  LiveStatus get status =>
      LiveStatus.fromRawValue(statusRawValue) ?? LiveStatus.planned;

  set status(LiveStatus newValue) => statusRawValue = newValue.rawValue;

  List<String> get performers {
    final decoded = _decodeList(performersJson);
    if (decoded == null) return const [];
    try {
      return List<String>.from(decoded);
    } on TypeError {
      return const [];
    }
  }

  set performers(List<String> newValue) {
    performersJson = _encode(newValue);
  }

  List<TicketOption> get ticketOptions {
    final decoded = _decodeList(ticketOptionsJson);
    if (decoded == null) return const [];
    try {
      return decoded
          .map((item) => TicketOption.fromJson(item as Map<String, dynamic>))
          .toList();
    } on Object {
      return const [];
    }
  }

  set ticketOptions(List<TicketOption> newValue) {
    ticketOptionsJson = _encode(
      newValue.map((option) => option.toJson()).toList(),
    );
    final selected = selectedTicketId;
    if (selected != null && !newValue.any((option) => option.id == selected)) {
      selectedTicketId = null;
    }
  }

  TicketOption? get selectedTicket {
    final selected = selectedTicketId;
    if (selected == null) return null;
    for (final option in ticketOptions) {
      if (option.id == selected) return option;
    }
    return null;
  }

  String? get selectedTicketName => selectedTicket?.name;

  set selectedTicketName(String? newValue) {
    String? matchedId;
    for (final option in ticketOptions) {
      if (option.name == newValue) {
        matchedId = option.id;
        break;
      }
    }
    selectedTicketId = matchedId;
  }

  Uri? get ticketUrl => validHttpUrl(ticketUrlString);

  Uri? get sourceUrl => validHttpUrl(sourceUrlString);

  Uri? get ticketActionUrl {
    final purchase = ticketUrl;
    if (purchase == null) return null;
    if (selectedTicketId == null) return purchase;
    return TicketPlatform.detect(purchase)?.ticketAccessUrl ?? purchase;
  }

  /// Port of `LiveEvent.validHTTPURL`: trims whitespace/newlines, requires a
  /// parseable URL with an http(s) scheme and a non-empty host. The empty
  /// string is a valid stored value meaning "absent" (and returns null here).
  static Uri? validHttpUrl(String rawValue) {
    final trimmed = rawValue.trim();
    final url = Uri.tryParse(trimmed);
    if (url == null) return null;
    final scheme = url.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;
    if (url.host.isEmpty) return null;
    return url;
  }

  static String _encode(Object value) {
    try {
      return jsonEncode(value);
    } on Object {
      return '[]';
    }
  }

  static List<dynamic>? _decodeList(String json) {
    try {
      final decoded = jsonDecode(json);
      return decoded is List ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}
