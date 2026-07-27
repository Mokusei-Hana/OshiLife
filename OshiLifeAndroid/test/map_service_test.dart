import 'package:flutter_test/flutter_test.dart';
import 'package:oshilife/core/utils/map_service.dart';

// Port of OshiLifeTests/MapServiceTests.swift semantics for the Android
// URL builders (Apple Maps is intentionally absent, plan §7.4).
void main() {
  test('name-first query builds the same Google Maps URL as iOS', () {
    final uri = MapService.googleMapsUri(venue: 'Zepp DiverCity');
    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/search/');
    expect(uri.queryParameters['api'], '1');
    expect(uri.queryParameters['query'], 'Zepp DiverCity');
  });

  test('falls back to coordinates when the venue is blank', () {
    final uri = MapService.googleMapsUri(
      venue: '  ',
      latitude: 35.0,
      longitude: 139.0,
    );
    expect(uri.queryParameters['query'], '35.0,139.0');

    final geo = MapService.geoUri(venue: '', latitude: 35.0, longitude: 139.0);
    expect(geo.scheme, 'geo');
    expect(geo.toString(), contains('35.0%2C139.0'));
  });

  test('rejects blank venue without coordinates', () {
    expect(
      () => MapService.googleMapsUri(venue: ' '),
      throwsA(isA<MapServiceException>()),
    );
  });

  test('validates coordinate ranges like iOS', () {
    expect(MapService.hasValidCoordinates(35.0, 139.0), isTrue);
    expect(MapService.hasValidCoordinates(91.0, 139.0), isFalse);
    expect(MapService.hasValidCoordinates(35.0, 181.0), isFalse);
    expect(MapService.hasValidCoordinates(null, 139.0), isFalse);
  });
}
