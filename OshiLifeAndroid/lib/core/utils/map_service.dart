/// Port of `OshiLife/Services/MapService.swift` for Android (plan §7.4):
/// name-first query, coordinates fallback. Apple Maps is replaced by a
/// generic `geo:` URI that opens the user's chosen maps app; the Google
/// Maps URL is identical to iOS. Callers launch the returned URIs with
/// url_launcher.
enum MapServiceErrorKind { emptyVenue, missingCoordinates }

class MapServiceException implements Exception {
  const MapServiceException(this.kind);

  final MapServiceErrorKind kind;

  /// iOS `errorDescription` localization keys.
  String get localizationKey => switch (kind) {
    MapServiceErrorKind.emptyVenue => 'error.map_empty',
    MapServiceErrorKind.missingCoordinates => 'error.map_coordinates',
  };
}

abstract final class MapService {
  static bool hasValidCoordinates(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  /// Same URL template as iOS `googleMapsURL(venue:)`.
  static Uri googleMapsUri({
    required String venue,
    double? latitude,
    double? longitude,
  }) {
    final query = _query(
      venue: venue,
      latitude: latitude,
      longitude: longitude,
    );
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });
  }

  /// Android-generic map intent: opens the system chooser of installed
  /// maps apps.
  static Uri geoUri({
    required String venue,
    double? latitude,
    double? longitude,
  }) {
    final query = _query(
      venue: venue,
      latitude: latitude,
      longitude: longitude,
    );
    return Uri.parse('geo:0,0?q=${Uri.encodeComponent(query)}');
  }

  /// Name-first, coordinates fallback — the iOS `open(provider:...)` rule.
  static String _query({
    required String venue,
    double? latitude,
    double? longitude,
  }) {
    final trimmed = venue.trim();
    if (trimmed.isNotEmpty) return trimmed;
    if (!hasValidCoordinates(latitude, longitude)) {
      throw const MapServiceException(MapServiceErrorKind.missingCoordinates);
    }
    return '$latitude,$longitude';
  }
}
