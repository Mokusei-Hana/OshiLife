import 'package:flutter_test/flutter_test.dart';
import 'package:oshilife/data/models/live_event.dart';
import 'package:oshilife/data/models/ticket_option.dart';
import 'package:oshilife/data/models/ticket_platform.dart';

// Port of OshiLifeTests/TicketPlatformTests.swift.
void main() {
  test('detects platforms from purchase URLs', () {
    final cases = <String, TicketPlatform>{
      'https://eplus.jp/sf/detail/123': TicketPlatform.ePlus,
      'https://t.pia.jp/pia/event/event.do?eventCd=123':
          TicketPlatform.ticketPia,
      'https://l-tike.com/order/?gLcode=123': TicketPlatform.lawsonTicket,
      'https://t.livepocket.jp/e/example': TicketPlatform.livePocket,
      'https://tiget.net/events/123': TicketPlatform.tiget,
      'https://zaiko.io/event/123': TicketPlatform.zaiko,
    };
    cases.forEach((rawUrl, expected) {
      expect(
        TicketPlatform.detect(Uri.parse(rawUrl)),
        expected,
        reason: rawUrl,
      );
    });
  });

  test('does not match lookalike or unsupported hosts', () {
    expect(
      TicketPlatform.detect(Uri.parse('https://eplus.jp.example.com/tickets')),
      isNull,
    );
    expect(
      TicketPlatform.detect(Uri.parse('https://example.com/tickets')),
      isNull,
    );
  });

  test('purchased ticket uses platform access page', () {
    final selectedTicket = TicketOption(name: 'Sチケット', price: 9000);
    final event = LiveEvent(
      artistName: '推し',
      title: 'ライブ',
      eventDate: DateTime.now(),
      ticketUrlString: 'https://eplus.jp/sf/detail/123',
      ticketOptions: [selectedTicket],
      selectedTicketId: selectedTicket.id,
    );

    expect(event.ticketActionUrl, TicketPlatform.ePlus.ticketAccessUrl);
  });

  test('unpurchased and unknown platform tickets use purchase URL', () {
    final ePlusPurchaseUrl = Uri.parse('https://eplus.jp/sf/detail/123');
    final unpurchasedEvent = LiveEvent(
      artistName: '推し',
      title: 'ライブ',
      eventDate: DateTime.now(),
      ticketUrlString: ePlusPurchaseUrl.toString(),
    );
    expect(unpurchasedEvent.ticketActionUrl, ePlusPurchaseUrl);

    final selectedTicket = TicketOption(name: '一般');
    final unknownPurchaseUrl = Uri.parse('https://example.com/tickets/123');
    final legacyEvent = LiveEvent(
      artistName: '推し',
      title: 'ライブ',
      eventDate: DateTime.now(),
      ticketUrlString: unknownPurchaseUrl.toString(),
      ticketOptions: [selectedTicket],
      selectedTicketId: selectedTicket.id,
    );
    expect(legacyEvent.ticketActionUrl, unknownPurchaseUrl);
  });
}
