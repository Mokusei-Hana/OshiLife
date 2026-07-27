import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oshilife/data/models/live_event.dart';
import 'package:oshilife/data/models/live_status.dart';
import 'package:oshilife/data/models/ticket_option.dart';

void main() {
  // Port of LiveStoreTests.testHTTPURLValidation.
  test('valid HTTP URL validation', () {
    expect(LiveEvent.validHttpUrl('https://example.com/ticket'), isNotNull);
    expect(LiveEvent.validHttpUrl(' http://example.com '), isNotNull);
    expect(LiveEvent.validHttpUrl('javascript:alert(1)'), isNull);
    expect(LiveEvent.validHttpUrl('not a url'), isNull);
    expect(LiveEvent.validHttpUrl(''), isNull);
  });

  test('unknown status raw value falls back to planned', () {
    final event = LiveEvent(
      artistName: 'A',
      title: 'T',
      eventDate: DateTime.now(),
    );
    event.statusRawValue = 'mystery';
    expect(event.status, LiveStatus.planned);
  });

  test('performers round-trip through JSON column', () {
    final event = LiveEvent(
      artistName: 'A',
      title: 'T',
      eventDate: DateTime.now(),
      performers: ['chuLa', 'TENRIN', 'iLiFE!'],
    );
    expect(event.performers, ['chuLa', 'TENRIN', 'iLiFE!']);
    expect(jsonDecode(event.performersJson), ['chuLa', 'TENRIN', 'iLiFE!']);

    event.performersJson = 'not json';
    expect(event.performers, isEmpty);
  });

  // The iOS `ticketOptions` setter is the app's only referential-integrity
  // rule: replacing the options clears a dangling selection.
  test('replacing ticket options clears dangling selection', () {
    final ticket = TicketOption(name: 'S', price: 9000);
    final event = LiveEvent(
      artistName: 'A',
      title: 'T',
      eventDate: DateTime.now(),
      ticketOptions: [ticket],
      selectedTicketId: ticket.id,
    );
    expect(event.selectedTicket, ticket);
    expect(event.selectedTicketName, 'S');

    event.ticketOptions = [TicketOption(name: 'A', price: 4000)];
    expect(event.selectedTicketId, isNull);
    expect(event.selectedTicket, isNull);
  });

  // Subtle Swift init ordering: `selectedTicketID` is assigned after the
  // setters ran, so an id that is not in `ticketOptions` survives
  // construction.
  test('constructor preserves selection not present in options', () {
    final event = LiveEvent(
      artistName: 'A',
      title: 'T',
      eventDate: DateTime.now(),
      ticketOptions: [TicketOption(name: 'A')],
      selectedTicketId: 'NOT-IN-OPTIONS',
    );
    expect(event.selectedTicketId, 'NOT-IN-OPTIONS');
    expect(event.selectedTicket, isNull);
  });

  test('selectedTicketName setter matches by name, first match wins', () {
    final first = TicketOption(name: '一般');
    final second = TicketOption(name: '一般');
    final event = LiveEvent(
      artistName: 'A',
      title: 'T',
      eventDate: DateTime.now(),
      ticketOptions: [first, second],
    );
    event.selectedTicketName = '一般';
    expect(event.selectedTicketId, first.id);

    event.selectedTicketName = 'unknown';
    expect(event.selectedTicketId, isNull);
  });

  // TicketOption JSON must round-trip iOS-written payloads: uppercase UUID
  // ids and omitted null fields.
  test('ticket option codec matches the iOS JSON shape', () {
    const iosJson =
        '[{"id":"3E82B1C4-6A1E-4B4E-9F1D-2A34567890AB","name":"Sチケット",'
        '"price":9000},{"id":"1B2C3D4E-0000-4000-8000-000000000000",'
        '"name":"当日券"}]';
    final event = LiveEvent(
      artistName: 'A',
      title: 'T',
      eventDate: DateTime.now(),
    );
    event.ticketOptionsJson = iosJson;

    final options = event.ticketOptions;
    expect(options, hasLength(2));
    expect(options[0].id, '3E82B1C4-6A1E-4B4E-9F1D-2A34567890AB');
    expect(options[0].price, 9000);
    expect(options[1].price, isNull);
    expect(options[1].description, isNull);

    final reEncoded = jsonDecode(
      jsonEncode(options.map((o) => o.toJson()).toList()),
    );
    expect(reEncoded, jsonDecode(iosJson));
  });

  test('generated ids are uppercase UUID strings', () {
    final event = LiveEvent(
      artistName: 'A',
      title: 'T',
      eventDate: DateTime.now(),
    );
    expect(event.id, event.id.toUpperCase());
    expect(
      RegExp(
        r'^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$',
      ).hasMatch(event.id),
      isTrue,
    );
  });
}
