/// Port of `OshiLife/Data/Models/VenueSelection.swift`.
class VenueSelection {
  const VenueSelection({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String address;
  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) {
    return other is VenueSelection &&
        other.name == name &&
        other.address == address &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(name, address, latitude, longitude);
}
