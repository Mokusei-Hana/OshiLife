import 'package:oshilife/import/models/event_import_details.dart';

/// Port of `Shared/Parsing/EventPageParsing.swift`.
///
/// Parses a fetched event page into structured import details. Add support
/// for a new event site by implementing this interface and registering the
/// parser in `EventLinkImporter`'s default parser list.
abstract interface class EventPageParsing {
  bool supports(Uri url);

  EventImportDetails? parse({required String html, required Uri sourceUrl});
}
